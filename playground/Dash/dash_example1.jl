using Dash  
using DashBootstrapComponents
using PlotlyJS, JSON3, Printf, Statistics

# include helper functions
include("utils.jl")  # tomographic dataset

# Load data
DataTomo, DataTopo = load_dataset();

data_fields =  keys(DataTomo.fields)

# set the initial cross-section
start_val = (5.0,46.0)
end_val = (12.0,44.0) 
cross = get_cross_section(DataTomo, start_val, end_val)

# Create a global variable with the data structure
global AppData
AppData = (DataTomo=DataTomo, DataTopo=DataTopo, cross=cross, move_cross=false, CrossSections=[]);        # this will later hold the cross-section and plot data


colornames = ["red",    "green",    "blue",    "black", "white"]
colorvalues= ["#F80038", "#00FF00", "#0000FF", "#000000","#FFFFFF"]

"""
Creates a topo plot & line that shows the cross-section
"""
#function plot_topo(DataTopo,start_val=nothing, end_val=nothing)
function plot_topo(AppData)    
    xdata =  AppData.DataTopo.lon.val[:,1]
    ydata =  AppData.DataTopo.lat.val[1,:]
    zdata =  AppData.DataTopo.depth.val[:,:,1]'
    cross =  AppData.cross
    start_val = cross.start_lonlat
    end_val   = cross.end_lonlat
    colorscale = "Viridis";
    reversescale = false;

    shapes = [ (   type = "line",   x0=start_val[1], x1=end_val[1], 
                                    y0=start_val[2], y1=end_val[2],
                                    editable = true,
                                    line  = (color="#000000", width=4),
                                    label = (text="",))] 
    for cr in AppData.CrossSections
        shape = (   type = "line",    x0=cr.start_lonlat[1], x1=cr.end_lonlat[1], 
                                      y0=cr.start_lonlat[2], y1=cr.end_lonlat[2],
                                      editable = false,
                                      line  = (color="#0000FF", width=1),
                                      label=(text="$(cr.Number)",))
        push!(shapes, shape)
    end

    pl = (
        id = "fig_topo",
        data = [heatmap(x = xdata, 
                        y = ydata, 
                        z = collect(eachcol(zdata)),
                        colorscale = colorscale,reversescale=reversescale,
                        zmin = -4, 
                        zmax = 4,
                        colorbar=attr(thickness=5)
                        )
                ],
        colorbar=Dict("orientation"=>"v", "len"=>0.5, "thickness"=>10,"title"=>"elevat"),
        layout = (  title = "topography [km]",
                    yaxis=attr(
                        title="Latitude",
                        tickfont_size= 14,
                        tickfont_color="rgb(100, 100, 100)"
                    ),
                    xaxis=attr(
                        title="Longitude",
                        tickfont_size= 14,
                        tickfont_color="rgb(10, 10, 10)"
                    ),

                    # once we save additional cross-sections, add them here
                    shapes = shapes,

                    ),
        config = (edits    = (shapePosition =  true,)),                              
    )

    return pl
end


"""
Creates topo plot & line that shows the cross-section
"""
function plot_cross(Cross::Profile; zmax=nothing, zmin=nothing, shapes=[])
    colorscale = "Rgb";
    reversescale = true;
    println("updating cross section")
    data = Cross.data';
    if isnothing(zmax)
        zmin, zmax = extrema(data)
    end
    shapes = Cross.Polygons

    shapes_data = [];
    if !isempty(shapes)
        # a shape was added to the plot; add it again
        for shape in shapes
            
            if shape.type=="line"
                line = shape.data_curve
                val  = (type = "line",   x0=line[1], x1=line[3], y0=line[2], y1=line[4], editable = true,
                            label = (text=shape.label_text,),
                            line  = (color=shape.line_color, width=shape.line_width))
                    
            elseif shape.type=="path"
                val =  (type = "path", path=shape.data_curve, editable = true,
                            label = (text=shape.label_text,),
                            line  = (color=shape.line_color, width=shape.line_width))
                                
            end
            push!(shapes_data, val)
        end
    end

    pl = (  id = "fig_cross",
            data = [heatmap(x = Cross.x_cart, 
                            y = Cross.z_cart, 
                            z = collect(eachcol(data)),
                            colorscale   = colorscale,
                            reversescale = reversescale,
                            colorbar=attr(thickness=5),
                            zmin=zmin, zmax=zmax
                            )
                    ],                            
            colorbar=Dict("orientation"=>"v", "len"=>0.5, "thickness"=>10,"title"=>"elevat"),
            layout = (  title = "Cross-section",
                        xaxis=attr(
                            title="Length along cross-section [km]",
                            tickfont_size= 14,
                            tickfont_color="rgb(100, 100, 100)"
                        ),
                        yaxis=attr(
                            title="Depth [km]",
                            tickfont_size= 14,
                            tickfont_color="rgb(10, 10, 10)"
                        ),
                        shapes = shapes_data,
                        ),
            config = (edits    = (shapePosition =  true,)),  
        )
    return pl
end


function plot_cross(cross::Nothing) 
    println("default cross section")
    cross = get_cross_section(DataTomo, (10.0,41.0), (10.0,49.0))
    pl = plot_cross(cross)
    return pl
end
plot_cross() = plot_cross(nothing)  


# This creates the topography (mapview) plot (lower left)
function create_topo_plot(AppData)
   
    dcc_graph(
        id = "mapview",
        figure    = plot_topo(AppData),
        animate   = true,
        clickData = true,
        config = PlotConfig(displayModeBar=false, scrollZoom = false)
    )

end

# This creates the cross-section plot
function cross_section_plot()
    dcc_graph(
        id = "cross_section",
        figure = plot_cross(), 
        animate = false,
        responsive=false,
        config = PlotConfig(displayModeBar=true, modeBarButtonsToAdd=["drawline","drawopenpath","eraseshape"],displaylogo=false))
        
end




# sets some defaults for webpage
#app = dash(external_stylesheets = ["/assets/app.css"])  
app = dash(external_stylesheets = [dbc_themes.BOOTSTRAP])

app.title = "GMG Data picker"


options_fields = [(label = String(f), value="$f" ) for f in data_fields]

# Create the main layout
app.layout = dbc_container(className = "mxy-auto") do

    
    html_h1("GMG Data Picker v0.1", style = Dict("margin-top" => 50, "textAlign" => "center")),

    html_div([
        dbc_col([
            # plot with cross-section
            dbc_row([dbc_col([cross_section_plot()], width=10),
                     dbc_col([
                                dbc_row([dbc_button("Curve Interpretation",id="button-curve-interpretation"),
                                         dbc_collapse(
                                             dbc_card(dbc_cardbody([
                                                dbc_row([
                                                    dbc_row(dbc_label("Options"),justify="center"),
                                                   # dbc_checkbox(label="lock curve", id="lock-curve"),

                                                     dbc_row([dbc_col(dbc_label("Name:"),align="center", width=5),
                                                             dbc_col(dbc_input(placeholder="Name of curve",id="shape-name"), width=6)]),

                                                    dbc_row([dbc_col(dbc_label("Linewidth:"),align="center", width=5),
                                                             dbc_col(dbc_input(placeholder="Linewidth",id="shape-linewidth", value="1", type="number"))
                                                            ]),

                                                    dbc_row([dbc_col(dbc_label("Colors:"),align="center", width=5),
                                                            dbc_col(dcc_dropdown(options=colornames,id="shape-color", value="black", clearable=false))
                                                           ]),

                                                    dbc_button("Update props of last curve",id="button-update-curve"),
                                                    dbc_button("Add all curves to profile",id="button-add-curve"),
                                                    dbc_button("Clear all curves",id="button-clear-curve"),
                                                    
                                                ])
                                                ])),
                                             id="collapse",
                                             is_open=false,
                                         ),
                                         dbc_button("Plot cross-section",id="button-plot-cross_section")
                                ])

                        
                            ], align="center"),
                    ], justify="center"),

            # info below plot
            dbc_row([
                    dbc_col([dcc_input(id="start_val", name="start_val", type="text", value="start: 5,46",style = Dict(:width => "100%"), debounce=true)]),
                    dbc_col([dcc_dropdown(
                                    id="dropdown_field",
                                    options = options_fields,
                                    value = "dVp_paf21",
                                    clearable=false, placeholder="Select Dataset",
                                ),
                                ]),
                    dbc_col([ dcc_rangeslider(
                                    id = "colorbar-slider",
                                    min = -5.,
                                    max = 5.,
                                    #step = .1,
                                    value=[-3, 3],
                                    allowCross=false,
                                    tooltip="always_visible"
                                    #marks = Dict([i => ("$i") for i in [-10, -5, 0, 5, 10]])
                                ),    
                                ]),
                    dbc_col([dcc_input(id="end_val", name="end_val", type="text", value="end: 10,45",style = Dict(:width => "100%"),placeholder="min")])
                    ]),
            ], width=12),

            # lower row | topography plot & buttons
            dbc_row([
                # plot topography
                dbc_col([create_topo_plot(AppData)]),
                
                # various menus @ lower right
                dbc_col([
                    dbc_row(dbc_label("Profile options"),justify="center"),
                    dbc_row(dbc_label("# of profiles: 0"),id="num_profiles"),
                    dbc_row([dbc_button("Add profile", id="button-add-profile")]),
                    dbc_row([dcc_dropdown(options="none", id="dropdown-profiles", placeholder="Select profile")]),
                    
                    #dbc_row([html_div("various options")], justify="center"),
                    #dbc_row([dbc_placeholder(xs=6, button=true)], align="center",justify="end"),
                   
                    #dbc_card(dbc_cardbody(["This is some text within a card body",
                    #         html_button(id="button-select", name="select", n_clicks=0, contentEditable=true),
                    #         dbc_placeholder(xs=6),
                    #]))
                    
                ], align="center", width=5)
                #dbc_col([
                #    dbc_row([html_button(id="button-select", name="select", n_clicks=0, contentEditable=true)])
                #])

            ])
           
        ]),


        #html_div(className = "row") do
        #    create_topo_plot(DataTopo, start_val, end_val),
        #    lowerright_menu()
        #end,
    
        html_pre(id="relayout-data")

end

# this is the callback that is invoked if the line on the topography map is changed
callback!(app,  Output("start_val", "value"),
                Output("end_val", "value"),
                Output("colorbar-slider", "value"),
                Input("mapview", "relayoutData"),
                Input("dropdown_field","value"),
                Input("mapview", "clickData"),
                Input("colorbar-slider", "value")
                ) do value, selected_field, clickData, colorbar_value
    global AppData
  
    # if we move the line value on the cross-section it will update this here:
    if AppData.move_cross==false
        start_val, end_val = get_startend_cross_section(value)
    else
        start_val = AppData.cross.start_lonlat
        end_val   = AppData.cross.end_lonlat
    end
    if isnothing(start_val)
        start_val = AppData.cross.start_lonlat
    end
    if isnothing(end_val)
        end_val = AppData.cross.end_lonlat
    end
    
    shapes = AppData.cross.Polygons
    cross = get_cross_section(AppData.DataTomo, start_val, end_val, Symbol(selected_field))
    cross.Polygons = shapes

    # update cross-section in AppData
    AppData = (AppData..., cross=cross,move_cross=false);

    # Update textbox values
    retStart = "start: $(@sprintf("%.2f", start_val[1])),$(@sprintf("%.2f", start_val[2]))"
    retEnd   = "end: $(@sprintf("%.2f", end_val[1])),$(@sprintf("%.2f", end_val[2]))"

    return retStart, retEnd, colorbar_value
end

# Updates the topo plot if we change the numerical start/end values
callback!(app,  Output("mapview", "figure"),
                Output("dropdown_field", "value"),
                Input("start_val", "n_submit"),
                Input("end_val", "n_submit"),
                State("start_val", "value"),
                State("end_val", "value")) do n_start, n_end, start_value, end_value

    global AppData
    if isnothing(n_start); n_start=0 end
    if isnothing(n_end); n_end=0 end
   
    if n_start>0 || n_end>0

            # extract numerical values of start & end
            start_val, end_val = extract_start_end_values(start_value, end_value)

            # compute new cross-section
            selected_field = AppData.cross.selected_field;
            shapes = AppData.cross.Polygons
            cross = get_cross_section(AppData.DataTomo, start_val, end_val, selected_field)

            cross.Polygons = shapes;

            # perhaps empty shapes, as this is a new cross-section?

            # update cross-section in AppData
            AppData = (AppData..., cross=cross, move_cross=true);
            
            # update topo plot
            fig_topo = plot_topo(AppData)

    else
        fig_topo = plot_topo(AppData)
        selected_field = AppData.cross.selected_field;

    end
    return fig_topo, String(selected_field)
    
end



# Updates the cross-section if we change the field or color axes
callback!(app,  Output("button-plot-cross_section","n_clicks"), 
                Input("dropdown_field","value"),
                Input("colorbar-slider", "value"),
                Input("button-plot-cross_section","n_clicks")) do selected_field, colorbar_value, n_clicks
    global AppData
                
    if !isnothing(colorbar_value)
        start_val = AppData.cross.start_lonlat
        end_val   = AppData.cross.end_lonlat
        
        shapes = AppData.cross.Polygons
        cross = get_cross_section(AppData.DataTomo, start_val, end_val, Symbol(selected_field))
        cross.Polygons = shapes

        AppData = (AppData..., cross=cross)

        # increment button click to replot (will auto-replot cross-section)
        if isnothing(n_clicks) 
            n_clicks=0
        end
        return n_clicks+1
    end

end

# replot the cross-section
callback!(app,  Output("cross_section", "figure"), 
                Input("button-plot-cross_section","n_clicks"),
                State("colorbar-slider", "value")) do n_clicks, colorbar_value
    global AppData
    if !isnothing(n_clicks)
        fig_cross = plot_cross(AppData.cross, zmin=colorbar_value[1], zmax=colorbar_value[2]) 
    else
        fig_cross = plot_cross(AppData.cross)
    end

    return fig_cross
end

# open/close Curve interpretation box
callback!(app,
    Output("collapse", "is_open"),
    [Input("button-curve-interpretation", "n_clicks")],
    [State("collapse", "is_open")], ) do  n, is_open
    
    if isnothing(n); n=0 end

    if n>0
        if is_open==1
            is_open = 0
        elseif is_open==0
            is_open = 1
        end
    end
    return is_open 
        
end

callback!(app,  Output("relayout-data", "children"), 
                Input("button-update-curve","n_clicks"),
                State("shape-name","value"),            # curves potentially added to cross-section
                State("shape-linewidth","value"),       # curves potentially added to cross-section
                State("shape-color","value"),
                State("cross_section","figure")
                ) do n, name, linewidth, colorname, fig_cross

    # retrieve dataset
    if isnothing(n); n=0 end

    shapes = interpret_drawn_curve(fig_cross.layout)
    
    # update values of last shape
    if !isempty(shapes)
        id = findall(colornames.==colorname);
        col = colorvalues[id][1]

        shape = shapes[end]
        shape = (shape..., label_text=name, line_width=linewidth, line_color=col)
        shapes[end] = shape
    end

    if hasfield(typeof(AppData),:cross)
        if !isempty(AppData.cross.Polygons)
            shape = AppData.cross.Polygons[end]
            
            # update latest curve (any changes made on the plot)
            AppData.cross.Polygons[end] = shapes[end]
        end
    end
    
    return nothing 

end


callback!(app,  Output("button-add-curve","n_clicks"), 
                Input("button-add-curve","n_clicks"),
                State("cross_section","figure")
                ) do n, fig_cross

    # retrieve dataset
    if !isnothing(n)
        shapes = interpret_drawn_curve(fig_cross.layout)
        AppData.cross.Polygons = shapes
    end

    return n 
end


callback!(app,  Output("button-clear-curve","n_clicks"), 
                Input("button-clear-curve","n_clicks"),
                ) do n

    # retrieve dataset
    if !isnothing(n)
        AppData.cross.Polygons = []
    end

    return n 

end



# save current cross-section to list
callback!(app,  Output("button-add-profile","n_clicks"),
                Output("num_profiles","component_name"),
                Output("start_val", "n_submit"),
                Output("dropdown-profiles","options"),
                Input("button-add-profile","n_clicks"),
                Input("num_profiles","className"),
                Input("start_val", "n_submit"),
                State("mapview", "figure")
                
                ) do n, comp_name, n_start, fig_map
    global AppData

    # retrieve dataset
    prof_names=""
    if !isnothing(n)
        cross = AppData.cross

        n_cross = length(AppData.CrossSections)
        if cross.Number==0
            cross.Number = n_cross+1
        end

        # Add to data set
        push!(AppData.CrossSections, AppData.cross)

        prof_names = ["none"]

        for cr in AppData.CrossSections
            push!(prof_names, "profile $(cr.Number)")
        end
        
    end
    if isnothing(n_start)
        n_start=0
    end

    return n, comp_name, n_start+1, prof_names 

end

# select a profile
callback!(app,  Output("dropdown-profiles","value"),
                Output("end_val", "n_submit"),
                Input("dropdown-profiles","value"),
                Input("end_val", "n_submit")
                ) do select_profile, n_end

    global AppData
    if !isnothing(select_profile)
        if select_profile != "none"
             _, num = split(select_profile)
             n = parse(Int64,num)
             @show num, select_profile
             
             for cr in AppData.CrossSections
                @show cr.Number
                if cr.Number==n
                    @show n
                    cross = cr
                    # update AppData
                    AppData = (AppData...,  cross=cross)
                end
             end
        end
    end
    if isnothing(n_end)
        n_end=0
    end

    return select_profile, n_end+1
end


run_server(app)
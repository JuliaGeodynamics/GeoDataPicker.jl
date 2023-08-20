using Dash  
using DashBootstrapComponents
using PlotlyJS, JSON3, Printf, Statistics

# include helper functions
include("utils.jl")  # tomographic dataset

# Load data
DataTomo, DataTopo = load_dataset();

start_val = (10,41)
end_val = (10,49) 


# define the options on the lower-right
function lowerright_menu()
    html_div(style = Dict("border" => "0.5px solid", "border-radius" => 5, "margin-top" => 68), className = "three columns") do
        html_div(id = "freq-val",
        style = Dict("margin-top" => "15px", "margin-left" => "15px", "margin-bottom" => "5px")),
       
        dcc_rangeslider(
            id = "colorbar-slider",
            min = -10.,
            max = 10.,
            step = 1,
            value=[-3, 3],
            allowCross=false,
            marks = Dict([i => ("$i") for i in [-10, -5, 0, 5, 10]])
        ),

        html_div(id = "damp-val",
        style = Dict("margin-top" => "15px", "margin-left" => "15px", "margin-bottom" => "5px")),
        dcc_slider(
            id = "damp-slider",
            min = 1,
            max = 6,
            step = nothing,
            value = 1,
            marks = Dict([i => ("$(i)") for i in 1:6])
        ),

        html_div(id = "disp-val",
        style = Dict("margin-top" => "15px", "margin-left" => "15px", "margin-bottom" => "5px")),
        dcc_slider(
            id = "disp-slider",
            min = -1.,
            max = 1.,
            step = 0.1,
            value = 0.5,
            marks = Dict([i => ("$i") for i in [-1, 0, 1]])
        ),

        html_div(id = "vel-val",
        style = Dict("margin-top" => "15px", "margin-left" => "15px",  "margin-bottom" => "5px")),
        dcc_slider(
            id = "vel-slider",
            min = -100.,
            max = 100.,
            step = 1.,
            value = 0.,
            marks = Dict([i => ("$i") for i in [-100, -50, 0, 50, 100]])
        ),

        dcc_checklist(
            options = [
                Dict("label" => "horizontal cross-section", "value" => false)
            ],
            value = ["MTL", "SF"],
        ),

        html_button("plot cross-section", id="button_cross", name="plot cross-section", n_clicks=0, contentEditable=true)

    end
end

"""
Creates topo plot & line that shows the cross-section
"""
function plot_topo(DataTopo,start_val=nothing, end_val=nothing)
    xdata =  DataTopo.lon.val[:,1]
    ydata =  DataTopo.lat.val[1,:]
    zdata =  DataTopo.depth.val[:,:,1]'
    if isnothing(start_val)
        start_val = (mean(xdata), minimum(ydata)+1)
    end
    if isnothing(end_val)
        end_val = (mean(xdata), maximum(ydata)-1)
    end
    colorscale = "Viridis";
    reversescale = false;

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
                    shapes = [
                            (   type = "line", x0=start_val[1], x1=end_val[1], 
                                            y0=start_val[2], y1=end_val[2],
                                editable = true)
                            ],
                    ),
        config = (edits    = (shapePosition =  true,)),                              
    )
    return pl
end


"""
Creates topo plot & line that shows the cross-section
"""
function plot_cross(Cross::NamedTuple)
    colorscale = "Rgb";
    reversescale = true;
    println("updating cross section")
    data = Cross.data';
    data[data .== NaN] .= 0;

    x = 1:rand(1:20)
    y = 1:rand(1:10)
    @show length(x), length(y)



    pl = (  id = "fig_topo",
            data = [heatmap(x = Cross.x, 
                            y = Cross.z, 
                            z = collect(eachcol(data)),
                            colorscale   = colorscale,
                            reversescale = reversescale,
                            colorbar=attr(thickness=5)
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
                        ),
            config = (edits    = (shapePosition =  true,)),  
        )
    return pl
end


function plot_cross(cross::Nothing) 
    println("default cross section")
    cross = get_cross_section(DataTomo, (10,41), (10,29))
    pl = plot_cross(cross)
    return pl
end
plot_cross() = plot_cross(nothing)  


# This creates the topography (mapview) plot (lower left)
function create_topo_plot(DataTopo,start_val=nothing, end_val=nothing)
   

    html_div(className = "nine columns" ) do
        dbc_row([dbc_col([dcc_input(id="start_val", name="start_val", type="text", value="start: 10,40",style = Dict(:width => "100%"), debounce=true)]),
                 dbc_col([dcc_input(id="end_val", name="end_val", type="text", value="end: 10,50",style = Dict(:width => "100%"),placeholder="min")])
                 ]),

        dcc_graph(
            id = "mapview",
            
            figure    = plot_topo(DataTopo, start_val, end_val),
            animate   = true,
            clickData = true,
            config = PlotConfig(displayModeBar=false, scrollZoom = false)
        )
    

    end
    
end

# This creates the cross-section plot
function cross_section_plot()
    dcc_graph(
        id = "cross_section",
        figure = plot_cross(), 
        animate = true,
        responsive=true
        
    )
end


"""
    start_val, end_val =  get_startend_cross_section(value::JSON3.Object)

Gets the numerical values of start & end of the cross-section (which we can modify by dragging)
"""
function get_startend_cross_section(value::JSON3.Object)

    if haskey(value, Symbol("shapes[0].x0"))
        # retrieve values from line 
        x0 = value[Symbol("shapes[0].x0")]
        x1 = value[Symbol("shapes[0].x1")]
        y0 = value[Symbol("shapes[0].y0")]
        y1 = value[Symbol("shapes[0].y1")]
        start_val, end_val = (x0,y0), (x1,y1)
    else
        start_val, end_val = nothing, nothing
    end    
    return start_val, end_val
end

get_startend_cross_section(value::Any) = nothing,nothing


# sets some defaults for webpage
#app = dash(external_stylesheets = ["/assets/app.css"])  
app = dash(external_stylesheets = [dbc_themes.BOOTSTRAP])

app.title = "GMG Data picker"

# Create the main layout
app.layout = dbc_container(className = "mxy-auto") do
    html_h1("GMG Data Picker v0.1", style = Dict("margin-top" => 50, "textAlign" => "center")),

    html_div(className = "column",
        cross_section_plot()
    ),
    dcc_interval(id="plot-updater"),

    html_div(className = "row") do
        create_topo_plot(DataTopo, start_val, end_val),
        lowerright_menu()
    end,
  
    html_pre(id="relayout-data")
end

# this is the callback that is invoked if the line on the topography map is changed
callback!(app,  Output("start_val", "value"),
                Output("end_val", "value"),
                Input("mapview", "relayoutData")) do value

    retB = "start: 10,41"
    retC = "end: 10,49"

    # if we move the line value on the cross-section it will update this here:
    start_val, end_val = get_startend_cross_section(value)
    if !isnothing(start_val) 
        # Update textbox values
        retB = "start: $(@sprintf("%.2f", start_val[1])),$(@sprintf("%.2f", start_val[2]))"
        retC = "end: $(@sprintf("%.2f", end_val[1])),$(@sprintf("%.2f", end_val[2]))"

    end
    retA = [];
    
    return retB, retC
end

#Output("relayout-data", "children"), 
     

# This callback changes the cross-section line if we change the values by hand
callback!(app,  Output("mapview", "figure"), 
                Output("cross_section","figure"),
                Input("start_val", "n_submit"),
                Input("end_val", "n_submit"),
                Input("start_val", "value"),
                Input("end_val", "value")) do n_start, n_end, start_value, end_value

    if (!isnothing(start_value) ) ||
        (!isnothing(end_value)  ) 
        
        # extract values:
        start_val1 = split(start_value,":")
        start_val1 = start_val1[end]

        end_val1 = split(end_value,":")
        end_val1 = end_val1[end]

        start_val, end_val = nothing, nothing
        s_str = split(start_val1,",")
        e_str = split(end_val1,  ",")
        if length(s_str)==2 && length(e_str)==2
            if !any(isempty.(s_str)) && !any(isempty.(e_str))
                x0,y0 = parse.(Float64,s_str)
                x1,y1 = parse.(Float64,e_str)
                start_val = (x0,y0)
                end_val = (x1,y1)
            end
        end
        
        retB = plot_topo(DataTopo,start_val, end_val)
        field = :dVp_paf21

        cross = get_cross_section(DataTomo, start_val, end_val, field)
        data = plot_cross(cross)
        @show start_val typeof(cross)
        return (retB, data)

    else
        retB = plot_topo(DataTopo)
        data = plot_cross()
        return (retB, data)

    end
end


run_server(app)
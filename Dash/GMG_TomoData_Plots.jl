# functions to create the various plots shown in the GUI

colornames = ["red",    "green",    "blue",    "black", "white"]
colorvalues= ["#F80038", "#00FF00", "#0000FF", "#000000","#FFFFFF"]

"""
Creates a topo plot & line that shows the cross-section
"""
function plot_topo(AppData)    
    xdata =  AppData.DataTopo.lon.val[:,1]
    ydata =  AppData.DataTopo.lat.val[1,:]
    zdata =  AppData.DataTopo.depth.val[:,:,1]'
    start_val, end_val = get_start_end_profile(AppData.AppDataUser)

    colorscale = "Viridis";
    reversescale = false;
    shapes = [ (   type = "line",   x0=start_val[1], x1=end_val[1], 
                                    y0=start_val[2], y1=end_val[2],
                                    editable = true,
                                    line  = (color="#000000", width=4),
                                    label = (text="",))] 
                                    
    for i = 2:length(AppData.AppDataUser.Profiles)
        cr = Profiles[i]
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

#=
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
=#

function plot_cross(cross::Nothing) 
    println("default cross section")
    cross = get_cross_section(DataTomo, (10.0,41.0), (10.0,49.0))
    pl = plot_cross(cross)
    return pl
end
plot_cross() = plot_cross(nothing)  


"""

this creates the 3D plot with topography and the cross-sections
"""
function plot_3D_data(DataTopo::GeoData, DataTomo::GeoData, AppData; 
                        field=:dVp_paf21, 
                        add_currentcross=true, 
                        add_allcross=false, 
                        add_volumetric=false, 
                        add_topo=true,
                        cvals=[-4,4],
                        cvals_vol=[1,3])
    
    data_plot = [];
    if add_topo 
        color_topo = "Viridis";
        # topography surface plot
        xdata =  DataTopo.lon.val[:,:]
        ydata =  DataTopo.lat.val[:,:]
        zdata =  DataTopo.depth.val[:,:,1]
        push!(data_plot,
                    surface(x = xdata, y = ydata, z = zdata,  opacity=0.8, hoverinfo="none", 
                            contours = attr(x=attr(highlight=false, show=false, project=attr(x=false) ),y=attr(highlight=false), z=attr(highlight=false),   
                            xaxis=attr(visible=false), yaxis=attr(visible=false, showspikes=false), zaxis=attr(visible=false, showspikes=false)),
                            colorscale = color_topo,  showscale=false))
    end

    color_seismic =  "Rgb"
    if add_volumetric
        # add volume plot if requested
        vol = DataTomo.fields[field]
        push!(data_plot,
                volume( x=DataTomo.lon.val[:], y=DataTomo.lat.val[:], z=DataTomo.depth.val[:], value=vol[:], 
                        isomin=cvals_vol[1], isomax=cvals_vol[2], opacity=0.1, surface_count=17,
                        showscale=false, colorscale = color_seismic)
                       )
    end
    if add_currentcross
        # add active cross section
        cross = AppData.cross.ProfileData
        vol   = cross.fields[field]
        push!(data_plot,
                surface( x=cross.lon.val[:,:], y=cross.lat.val[:,:], z=cross.depth.val[:,:,1], surfacecolor=vol[:,:,1], 
                         contours = attr(x=attr(highlight=false),y=attr(highlight=false), z=attr(highlight=false)),
                         colorscale = color_seismic,
                         hoverinfo  = false,
                         showscale  = true,  reversescale=false,
                         cmin=cvals[1], cmax=cvals[2]))
    end

    if add_allcross
        for profile in AppData.CrossSections
            cross = profile.ProfileData
            vol   = cross.fields[field]
            push!(data_plot,
                    surface( x=cross.lon.val[:,:], y=cross.lat.val[:,:], z=cross.depth.val[:,:,1], surfacecolor=vol[:,:,1], 
                             contours = attr(x=attr(highlight=false),y=attr(highlight=false), z=attr(highlight=false)),
                             colorscale = color_seismic,
                             hoverinfo  = false,
                             showscale  = false,  reversescale=false))
        end
    end


    # create actual figure
    pl = (
        id = "fig_3D",
        
        # Topography
        data = data_plot,
        
        colorbar=Dict("orientation"=>"h", "len"=>0.5, "thickness"=>10,"title"=>"elevat"),
        layout = (  autosize=false,
                    width=1000, height=500,                 # need to check that this works fine on different screens/OS
                    scene = attr(  yaxis=attr(
                                    showspikes=false,
                                    title="Latitude",
                                    tickfont_size= 14,
                                    tickfont_color="rgb(100, 100, 100)"),
                                 xaxis=attr(
                                    showspikes=false,
                                    title="Longitude",
                                    tickfont_size= 14,
                                    tickfont_color="rgb(100, 100, 100)"
                                 ),
                                 zaxis=attr(
                                    showspikes=false,
                                    title="Depth",
                                    tickfont_size= 14,
                                    tickfont_color="rgb(10, 10, 10)"
                                 ),
                                 aspectmode="manual", 
                                 aspectratio=attr(x=3, y=3, z=1)
                                )

                    ),
        config = (edits    = (shapePosition =  true,)),                              
    )


    return pl
end

# This creates the topography (mapview) plot (lower left)
function create_topo_plot(AppData)
   
    dcc_graph(
        id = "mapview",
        figure    = [], #plot_topo(AppData),
        #animate   = true,
        #clickData = true,
        animate   = false,
        responsive=false,
        #clickData = true,
        config = PlotConfig(displayModeBar=false, scrollZoom = false)
    )

end

# This creates the cross-section plot
function cross_section_plot()
    dcc_graph(
        id = "cross_section",
        figure = [], #plot_cross(), 
        animate = false,
        responsive=false,
        config = PlotConfig(displayModeBar=true, modeBarButtonsToAdd=["drawline","drawopenpath","eraseshape","drawclosedpath"],displaylogo=false))
        
end




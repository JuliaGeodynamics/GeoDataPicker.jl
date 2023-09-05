# functions to create the various plots shown in the GUI

"""
Creates a topo plot & line that shows the cross-section
"""
function plot_topo(AppData)    
    xdata =  AppData.DataTopo.lon.val[:,1]
    ydata =  AppData.DataTopo.lat.val[1,:]
    zdata =  AppData.DataTopo.depth.val[:,:,1]'
    start_val, end_val = get_start_end_profile(AppData.AppDataUser)

    colormaps       = AppData.AppDataUser.colormaps
    colorscale_topo = colormaps[:oleron];

    colorline_selected = "#000000"      # black
    colorline_crosssections =  "#fffb00" #"#0000FF"

    color_font = "#0000FF"
    color_font = "#fffb00"  # yellow
    size_font  = 15

    shapes = [ (   type = "line",   x0=start_val[1], x1=end_val[1], 
                                    y0=start_val[2], y1=end_val[2],
                                    editable = true,
                                    line  = (color=colorline_selected, width=4),
                                    label = (text="",font=(color=color_font,size=size_font)))] 
                                    
    for i = 2:length(AppData.AppDataUser.Profiles)
        cr = AppData.AppDataUser.Profiles[i]
        shape = (   type = "line",    x0=cr.start_lonlat[1], x1=cr.end_lonlat[1], 
                                      y0=cr.start_lonlat[2], y1=cr.end_lonlat[2],
                                      editable = false,
                                      line  = (color=colorline_crosssections, width=1),
                                      label = (text="$(cr.number)",font=(color=color_font,size=size_font)), 
                                      )
        push!(shapes, shape)
    end

    pl = (
        id = "fig_topo",
        data = [heatmap(x = xdata, 
                        y = ydata, 
                        z = collect(eachcol(zdata)),
                        colorscale = colorscale_topo,
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
Creates a plot of the cross-section with all requested options
"""
function plot_cross(AppData, profile; zmax=nothing, zmin=nothing, shapes=[], field=:dVp_paf21, colormap="vik_reverse")
    AppDataUser = AppData.AppDataUser
    colormaps   = AppDataUser.colormaps
   
    # Compute the cross-section.
    # NOTE: this routine will be replaces with the one of marcel
    x_cart, z_cart, data, cross = get_cross_section(AppData, profile, field)    

    colorscale = colormaps[Symbol(colormap)];

    println("updating cross section")
    if isnothing(zmax)
        zmin, zmax = extrema(data)
    end
    curves = profile.Polygons

    shapes_data = [];
    if !isempty(curves)
        # a shape was added to the plot; add it again
        for  curve in curves
            
            if curve.type=="line"
                line = curve.data
                val  = (type = "line",   x0=line[1], x1=line[3], y0=line[2], y1=line[4], editable = true,
                            label = (text=curve.name,),
                            line  = (color=curve.color, width=curve.linewidth))
                    
            elseif curve.type=="path"
                val =  (type = "path", path=curve.data, editable = true,
                            label = (text=curve.name,),
                            line  = (color=curve.color, width=curve.linewidth))
                                
            end
            push!(shapes_data, val)
        end
    end

    pl = (  id = "fig_cross",
            data = [heatmap(x = x_cart, 
                            y = z_cart, 
                            z = collect(eachcol(data)),
                            colorscale   = colorscale,
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


#function plot_cross(cross::Nothing) 
#    println("default cross section")
#    cross = get_cross_section(DataTomo, (10.0,41.0), (10.0,49.0))
#    pl = plot_cross(cross)
#    return pl
#end
#plot_cross() = plot_cross(nothing)  


"""

this creates the 3D plot with topography and the cross-sections
"""
function plot_3D_data(AppData; 
                        field=:dVp_paf21, 
                        selected_cross=[],
                        add_volumetric=false, 
                        add_topo=true,
                        cvals=[-4,4],
                        cvals_vol=[1,3],
                        opacity_cross=1,
                        curve_select=nothing,
                        color="roma")
    if hasfield(typeof(AppData),:DataTomo)
        DataTomo        = AppData.DataTomo
        DataTopo        = AppData.DataTopo
        AppDataUser     = AppData.AppDataUser
        colormaps       = AppDataUser.colormaps
        colorscale_topo = colormaps[:oleron];
        color_seismic   = colormaps[Symbol(color)];

        data_plot = [];
        if add_topo 
            # topography surface plot
            xdata =  DataTopo.lon.val[:,:]
            ydata =  DataTopo.lat.val[:,:]
            zdata =  DataTopo.depth.val[:,:,1]
            push!(data_plot,
                        surface(x = xdata, y = ydata, z = zdata,  opacity=0.8, hoverinfo="none", 
                                contours = attr(x=attr(highlight=false, show=false, project=attr(x=false) ),y=attr(highlight=false), z=attr(highlight=false),   
                                xaxis=attr(visible=false), yaxis=attr(visible=false, showspikes=false), zaxis=attr(visible=false, showspikes=false)),
                                colorscale = colorscale_topo,  showscale=false,  cmin = -4, cmax = 4),
                                )
        end

       
        if add_volumetric
            # add volume plot if requested
            vol = DataTomo.fields[field]
            push!(data_plot,
                    volume( x=DataTomo.lon.val[:], y=DataTomo.lat.val[:], z=DataTomo.depth.val[:], value=vol[:], 
                            isomin=cvals_vol[1], isomax=cvals_vol[2], opacity=0.1, surface_count=17,
                            showscale=false, colorscale = color_seismic)
                        )
        end
        
        if !isnothing(selected_cross)
            for i in selected_cross
                profile  = AppData.AppDataUser.Profiles[i+1]
                _, _, _,_, cross = get_cross_section(AppData, profile, field)    
                vol   = cross.fields[field]
                push!(data_plot,
                        surface( x=cross.lon.val[:,:], y=cross.lat.val[:,:], z=cross.depth.val[:,:,1], surfacecolor=vol[:,:,1], 
                                contours = attr(x=attr(highlight=false),y=attr(highlight=false), z=attr(highlight=false)),
                                colorscale = color_seismic,
                                hoverinfo  = false,
                                showscale  = true, 
                                colorbar = attr(thickness=5, title=String(field)),
                                cmin = cvals[1], cmax=cvals[2],
                                opacity = opacity_cross))
            end
        end

        if !isnothing(curve_select)
            Profiles = AppData.AppDataUser.Profiles
            for prof in Profiles
                for curve in prof.Polygons
                    if !isnothing(curve_select)
                        if any(contains.(curve_select,curve.name))
                            push!(data_plot,
                                scatter3d( x=curve.lon, y=curve.lat, z=curve.depth, mode="lines",
                                        line=attr(color=curve.color, width=2),
                                        showlegend=false, label=curve.name))
                        end
                    end
                end
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
    else
        pl = ()
    end


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
        config = PlotConfig(displayModeBar=true, modeBarButtonsToAdd=["drawopenpath","eraseshape","drawclosedpath"],displaylogo=false))
        
end




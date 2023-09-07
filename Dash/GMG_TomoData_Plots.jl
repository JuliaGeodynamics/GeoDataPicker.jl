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
function plot_cross(AppData, profile; 
                    zmax=nothing, zmin=nothing,
                    field=:dVp_paf21, 
                    colormap="vik_reverse",
                    screenshot_opacity=0.5, 
                    screenshot_display=true, 
                    cross_section_opacity=1.0,
                    plot_surfaces   =   false,
                    plot_earthquakes=   false
                    )
    AppDataUser = AppData.AppDataUser
    colormaps   = AppDataUser.colormaps
    section_width = 50km;
    
    Profile             =  ProfileData(profile);                         # create a GMG structure for the profile 
    Profile, PlotCross  =  ExtractProfileData(Profile, AppData, field; section_width=section_width)   # project data onto the profile

    # Compute the cross-section.
    # NOTE: this routine will be replaces with the one of marcel
    #x_cart, z_cart, data, cross = get_cross_section(AppData, profile, field)    

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

    data_plots = []
    
    # add tomographic cross-section
    push!(data_plots, heatmap(x = PlotCross.x_cart, 
                              y = PlotCross.z_cart, 
                              z = collect(eachcol(PlotCross.data)),
                              colorscale   = colorscale,
                              colorbar=attr(thickness=5),
                              zmin=zmin, zmax=zmax, 
                              opacity = cross_section_opacity
                              ))

    if screenshot_display==true
      # Note: the name of the profile should be listed in the profuile struct
      screenshot_selected = profile.screenshot
      if !isnothing(screenshot_selected)
          if hasfield(typeof(AppData.DataScreenshots), screenshot_selected)
              screenshot  = AppData.DataScreenshots[screenshot_selected]
              ss          = image_from_screenshot(screenshot)
              push!(data_plots, image(x0=ss.x0,dx=ss.dx, y0=ss.y0, dy=ss.dy, 
                                      z=ss.z, 
                                      opacity=screenshot_opacity
                                      ))
          end
      end                                                    
    end

    if plot_surfaces 
        Names = String.(keys(Profile.SurfData))
        for (i,Surf) in enumerate(Profile.SurfData)
            x_surf = Surf.fields.x_profile
            z_surf = ustrip.(Surf.fields.MohoDepth)
            push!(data_plots, scatter(x = x_surf, y = z_surf, mode="lines",  name=Names[i]))
        end
    end

    if plot_earthquakes
        Names = String.(keys(Profile.PointData))
        for (i,Points) in enumerate(Profile.PointData)
            # Filter the earthquakes
            x_EQ = Points.fields.x_profile
            z_EQ = Points.depth.val
            ind = findall(x_EQ .< profile.end_cart)

            push!(data_plots, scatter(x = x_EQ[ind], y = z_EQ[ind], mode="markers", name=Names[i]))
                    
        end
    end

    pl = (  id = "fig_cross",
            data = data_plots,                            
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
                            tickfont_color="rgb(10, 10, 10)",
                            autorange=true
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
                        color="roma",
                        opacity_topography_3D=0.8)
    if hasfield(typeof(AppData),:DataTomo)
        DataTomo        = AppData.DataTomo
        DataTopo        = AppData.DataTopo
        AppDataUser     = AppData.AppDataUser
        colormaps       = AppDataUser.colormaps
        colorscale_topo = colormaps[:oleron];
        color_seismic   = colormaps[Symbol(color)];
        section_width   = 50km


        data_plot = [];
        if add_topo 
            # topography surface plot
            xdata =  DataTopo.lon.val[:,:]
            ydata =  DataTopo.lat.val[:,:]
            zdata =  DataTopo.depth.val[:,:,1]
            push!(data_plot,
                        surface(x = xdata, y = ydata, z = zdata,  opacity=opacity_topography_3D, hoverinfo="none", 
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

                Profile     = ProfileData(profile);                                                      # create a GMG structure for the profile 
                Profile, _  = ExtractProfileData(Profile, AppData, field; section_width=section_width)   # project data onto the profile
                
                vol   = Profile.VolData.fields[field]
                push!(data_plot,
                        surface( x=Profile.VolData.lon.val[:,:], y=Profile.VolData.lat.val[:,:], z=Profile.VolData.depth.val[:,:,1], surfacecolor=vol[:,:,1], 
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
        config = PlotConfig(displayModeBar=true, modeBarButtonsToAdd=["toimage","toImage","lasso","drawopenpath","eraseshape","drawclosedpath"],displaylogo=false))
        
end




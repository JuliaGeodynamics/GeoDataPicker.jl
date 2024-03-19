# functions to create the various plots shown in the GUI

"""
updates the topo plot & line that shows the cross-section
"""
function plot_topo(AppData,session_id)    
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
                        colorbar=attr(thickness=20, title="topography [km]", titleside="right"),
                        )
                ],
        colorbar=Dict("orientation"=>"v", "len"=>0.5, "thickness"=>20),
        layout = (  #title = "topography [km]",
                    yaxis=attr(
                        title="Latitude",
                        tickfont_size= 16,
                        tickfont_color="rgb(100, 100, 100)"
                    ),
                    xaxis=attr(
                        title="Longitude",
                        tickfont_size= 16,
                        tickfont_color="rgb(10, 10, 10)",
                        scaleanchor="y", scaleratio=1/1.65,
                    ),
                    aspectmode="manual", 
                    aspectratio=attr(x=0.8, y=1, z=1),
                    # once we save additional cross-sections, add them here
                    shapes = shapes,
                    ),

                       
        #scene = attr( aspectmode="manual", 
        #              aspectratio=attr(x=1, y=1, z=1) # change the aspect ratio so that we have an approximately orthogonal 
        #            ),
        
        config = (edits    = (shapePosition =  true,)),                              
    )

    return pl
end

"""
Creates a plot of the cross-section with all requested options
"""
# WE HERE HAVE TO UPDATE EVERYTHING WITH 
# - THE NEW TOMOGRAPHIC CROSS-SECTION --> adds a new field, colormap, opacity, color z_limits
# - the switches for tomographies --> adds plot_tomographyI and plot_tomographyII
function plot_cross(AppData, profile; 
                    zmax=nothing, zmin=nothing,
                    field=:dVp_paf21, 
                    colormap="vik_reverse",
                    screenshot_opacity=0.5, 
                    screenshot_display=true, 
                    cross_section_opacity=1.0,
                    plot_tomography = true,
                    plot_tomographyII = false,
                    plot_surfaces   =   false, selected_surf_data= [],EQmag=(0.1,9),
                    plot_earthquakes=   false, selected_EQ_data= [], section_width=50,
                    )
    AppDataUser = AppData.AppDataUser
    colormaps   = AppDataUser.colormaps
    section_width = section_width*km;
    
    # Compute the cross-section.
    Profile             =  ProfileData(profile);                         # create a GMG structure for the profile 
    Profile, PlotCross  =  ExtractProfileData(Profile, AppData, field; section_width=section_width)   # project data onto the profile

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
            x,y,closed = svg2vec(curve.data)
            if curve.type=="line"
                line = curve.data
                val  = (type = "line",   x0=line[1], x1=line[3], y0=line[2], y1=line[4], editable = true,
                            label = (text=curve.name,),
                            line  = (color=curve.color, width=curve.linewidth),
                            name  = curve.name,
                            surfacecolor=curve.color)
                    
            elseif curve.type=="path"
                val =  (type = "path", path=curve.data, editable = true,
                            label = (text=curve.name,),
                            line  = (color=curve.color, width=curve.linewidth),
                            name  = curve.name)
                                
            end
            push!(shapes_data, val)
        end
    end

    data_plots = []
    
    # add tomographic cross-section
    if plot_tomography
        push!(data_plots, heatmap(x = PlotCross.x_cart, 
                                  y = PlotCross.z_cart, 
                                  z = collect(eachcol(PlotCross.data)),
                                  colorscale   = colorscale,
                                  colorbar=attr(thickness=20, title=String(field), titleside="right"),
                                  zmin=zmin, zmax=zmax, 
                                  opacity = cross_section_opacity
                                ))
    end
    # add second tomographic cross-section  WORK IN PROGRESS!!!  
    if plot_tomographyII 
        push!(data_plots, heatmap(x = PlotCross.x_cart, 
                                  y = PlotCross.z_cart, 
                                  z = collect(eachcol(PlotCross.data)),
                                  colorscale   = colorscale,
                                  colorbar=attr(thickness=20, title=String(field), titleside="right"),
                                  zmin=zmin, zmax=zmax, 
                                  opacity = cross_section_opacity
                                  ))
    end

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
            if any(selected_surf_data .== Names[i])
                x_surf = Surf.fields.x_profile
                z_surf = ustrip.(Surf.depth.val)
                push!(data_plots, scatter(x = x_surf, y = z_surf, mode="lines",  name=Names[i]))
            end
        end
    end

    if plot_earthquakes
        Names = String.(keys(Profile.PointData))
        for (i,Points) in enumerate(Profile.PointData)
            if any(selected_EQ_data .== Names[i])
            
                # Filter the earthquakes 
                # NOTE: we should later filter by magnitude as well
                if !isnothing(Points)
                    Magn = Points.fields.Magnitude
                    if profile.vertical
                        x_EQ = Points.fields.x_profile
                        z_EQ = Points.depth.val
                        ind = findall( (x_EQ .< profile.end_cart) .&& (Magn.>EQmag[1]) .&& (Magn.<EQmag[2]))
                    else
                        x_EQ = Points.lon.val
                        z_EQ = Points.lat.val
                        ind = findall( (Magn.>EQmag[1]) .&& (Magn.<EQmag[2]))
                    end
                   

                    push!(data_plots, scatter(x = x_EQ[ind], y = z_EQ[ind], mode="markers", name=Names[i]))
                end
            end        
        end
    end

    if profile.vertical
        xlab = "Length along cross-section [km]"
        ylab = "Depth [km]"
    else
        xlab = "Longitude"
        ylab = "Latitude"
    end

    pl = (  id = "fig_cross",
            data = data_plots,                            
            colorbar=Dict("orientation"=>"v", "len"=>0.5, "thickness"=>10,"title"=>"elevat"),
            layout = (  xaxis=attr(
                            title=xlab,
                            tickfont_size= 14,
                            tickfont_color="rgb(100, 100, 100)",
                            scaleanchor="y", scaleratio=1,
                            autorange=false, range=[PlotCross.x_cart[1],PlotCross.x_cart[end]],
                            
                        ),
                        yaxis=attr(
                            title=ylab,
                            tickfont_size= 14,
                            tickfont_color="rgb(10, 10, 10)",
                            autorange=false,
                            range=[minimum(PlotCross.z_cart),0],
                        ),
                        shapes = shapes_data,
                        #aspectmode="manual", 
                        #aspectratio=attr(x=1, y=1, z=1)
                        ),
            config = (edits    = (shapePosition =  true,)),  
        )
    
    return pl
end

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
                        opacity_topography_3D=0.8,
                        selected_surfaces_data=[""], opacity_surfaces_data=1.0,
                        selected_EQ_data=[""], EQmag=(0.1, 9))

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
            zdata =  ustrip.(DataTopo.depth.val[:,:,1])
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
                profile     = AppData.AppDataUser.Profiles[i+1]
                Profile     = ProfileData(profile);                                                      # create a GMG structure for the profile 
                Profile, _  = ExtractProfileData(Profile, AppData, field; section_width=section_width)   # project data onto the profile
                
                vol   = Profile.VolData.fields[field]
                x = Profile.VolData.lon.val[:,:]
                y = Profile.VolData.lat.val[:,:]
                z = Profile.VolData.depth.val[:,:]
                col = vol[:,:]
                z[isnan.(col)] .= NaN;      # make this transparent in 3D
                push!(data_plot,
                        surface( x=x, y=y, z=z, surfacecolor=col, 
                                contours = attr(x=attr(highlight=false),y=attr(highlight=false), z=attr(highlight=false)),
                                colorscale = color_seismic,
                                showscale  = true, 
                                colorbar = attr(thickness=5, title=String(field), titleside="right"),
                                cmin = cvals[1], cmax=cvals[2],
                                opacity = opacity_cross,
                                name = "$i-$(profile.name)" , hoverinfo=("name",)))
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
                                        name = curve.name,
                                        showlegend=true,
                                        hoverinfo=("name",),
                                        surfacecolor=curve.color))
                        end
                    end
                end
            end
        end
        
        # surfaces
        Names = String.(keys(AppData.DataSurfaces))
        for (i,Surface) in enumerate(AppData.DataSurfaces)
            if any(selected_surfaces_data .== Names[i])
                
                # topography surface plot
                xdata =  Surface.lon.val[:,:]
                ydata =  Surface.lat.val[:,:]
                zdata =  ustrip.(Surface.depth.val[:,:,1])
                
                push!(data_plot,
                            surface(x = xdata, y = ydata, z = zdata,  opacity=opacity_surfaces_data, hoverinfo="none", 
                                    contours = attr(x=attr(highlight=false, show=false, project=attr(x=false) ),y=attr(highlight=false), z=attr(highlight=false),   
                                    xaxis=attr(visible=false), yaxis=attr(visible=false, showspikes=false), zaxis=attr(visible=false, showspikes=false)),
                                    color=zdata,
                                    colorbar = attr(thickness=5, title=String(field), x=1.1, titleside="right"),
                                   ),
                                    )
            end
        end

        # EQ's
        Names = String.(keys(AppData.DataPoints))
        for (i,Points) in enumerate(AppData.DataPoints)
            if any(selected_EQ_data .== Names[i])

                # Filter the earthquakes 
                # NOTE: we should later filter by magnitude as well
                Magn = Points.fields.Magnitude
                x_EQ = Points.lon.val
                y_EQ = Points.lat.val
                z_EQ = Points.depth.val
                ind = findall( (Magn.>EQmag[1]) .&& (Magn.<EQmag[2]))

                push!(data_plot, scatter3d(x = x_EQ[ind], y = y_EQ[ind], z = z_EQ[ind], mode="markers", 
                                name=Names[i], marker_size=5,  showlegend=true))

            end
        end

        # triangulated surfaces
        triangulated_surfaces = true
        if triangulated_surfaces
            println("Plotting triangulated surface")
            for surfmesh in AppDataUser.Surfaces
                mesh_plotly = prepare_mesh_plotly(surfmesh.mesh)
                push!(data_plot, 
                                mesh3d(
                                    # 8 vertices of a cube
                                    x=mesh_plotly.x, y=mesh_plotly.y, z=mesh_plotly.z,
                                    colorbar_title="z",
                                    # i, j and k give the vertices of triangles
                                    i = mesh_plotly.i, j = mesh_plotly.j, k = mesh_plotly.k,
                                    color=surfmesh.color,
                                    name="y",
                                    showscale=true,
                                )
                        )

            end
        end

        # create actual figure
        pl = (
            id = "fig_3D",
            
            # Topography
            data = data_plot,
            
            colorbar=Dict("orientation"=>"h", "len"=>0.5, "thickness"=>10,"title"=>"elevat"),
            layout = (  #autosize=false,
                        #width=1000, height=500,                 # need to check that this works fine on different screens/OS
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
                                    ),
                        showlegend=true,
                        legend=attr(orientation="h", xanchor="left")

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

   # first we have to see how large the map is to determine how we plot it
   # the idea is to have an image that fills the availiable screen
   
   #lonmin =  minimum(AppData.DataTopo.lon.val[:,1]);
   #lonmax =  maximum(AppData.DataTopo.lon.val[:,1]);
   #latmin =  minimum(AppData.DataTopo.lat.val[1,:]);
   #latmax =  maximum(AppData.DataTopo.lat.val[1,:]);

   #lon_extent = lonmax-lonmin;
   #lat_extent = latmat-latmin;

   # until plotting in map projection works here, we simply rescale the longitude axis with a factor that 
   # makes the plot look not too distorted
   # if we want to fill the available visible  space, we now have to determine the width and height on screen
   #width_lon = lon_extent*0.8;
   #height_lat = lat_extent;

   #if width_lon>height_lat
   #     plotwidth = "80vw";
   #     plotheight = string(100/0.8)*"vw";
   #else
        plotheight = "80vh";
        plotwidth  = "80vw"
   #end

   #println("AppData")
   println(keys(AppData))

    html_div(
        dcc_graph(
            id = "mapview",
            figure    = [], #plot_topo(AppData),
            #animate   = true,
            #clickData = true,
            animate   = false,
            responsive=true,
            #clickData = true,
            config = PlotConfig(displayModeBar=false, scrollZoom = false),
            # here we plot the map so that the angles look about right
            # a quick and simple way to do this is to set the aspect ratio to something smaller. Here we used a factor derived by trial and error
            # the issue is that we somehow have to make this dependent on the map itself
            style = attr(width=plotwidth, height=plotheight,padding_left=string(0.5*(100-(80/1.65)))*"vh") 
        ),
        style = attr(textalign="center")
    )

end

# This creates the cross-section plot
function cross_section_plot()
    dcc_graph(
        id = "cross_section",
        figure = [], #plot_cross(), 
        animate = false,
        responsive=true,
        config = PlotConfig(displayModeBar=true, modeBarButtonsToAdd=["toimage","toImage","lasso","drawopenpath","eraseshape","drawclosedpath"],displaylogo=false),
        style = attr(width="80vw", height="80vh"))
end




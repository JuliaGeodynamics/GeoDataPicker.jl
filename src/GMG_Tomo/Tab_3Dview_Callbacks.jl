# Callbacks for this tab
function  Tab_3Dview_Callbacks(app)

# Update the 3D plot
callback!(app,  Output("3D-image","figure"),
                Input("id-plot-3D","n_clicks"),
                State("opacity-cross-3D","value"),
                State("colorbar-slider", "value"),
                State("id-3D-isosurface-slider","value"),
                State("id-3D-topo","value"),
                State("id-3D-volume","value"),
                State("dropdown_field","value"), 
                State("selected_cross-sections", "value"),
                State("3D-selected_curves","value"),
                State("colormaps_cross","value"),
                State("opacity-topography-3D","value"),
                State("3D-selected_EQ_data","value"),
                State("3D-selected_surfaces_data","value"),
                State("opacity-surfaces-3D","value"),
                State("3D-EQ_magnitude-slider","value"),
                State("session-id","data")
                ) do n_clicks, opacity_cross, colorbar_value, colorbar_value_vol, 
                     val_topo, val_vol, field, selected_profiles,  curve_select, colormap_field, 
                     opacity_topography_3D, selected_EQ_data, selected_surfaces_data, 
                     opacity_surfaces_data, EQmag,
                     session_id 

    global AppData

    # compute profile
    AppDataLocal = get_AppData(AppData, session_id)
    pl = plot_3D_data(AppDataLocal, 
                        selected_cross=selected_profiles, 
                        add_volumetric=Bool(val_vol), 
                        add_topo=Bool(val_topo),
                        cvals=colorbar_value,
                        field=Symbol(field),
                        cvals_vol=colorbar_value_vol,
                        opacity_cross=opacity_cross,
                        curve_select=curve_select,
                        color=colormap_field,
                        opacity_topography_3D=opacity_topography_3D,
                        selected_surfaces_data=selected_surfaces_data, opacity_surfaces_data=opacity_surfaces_data,
                        selected_EQ_data=selected_EQ_data, EQmag=EQmag
                      )

    return pl
end





# Update the 3D plot
callback!(app,  Output("create-surface-curves","n_clicks"),
                Input("create-surface-curves","n_clicks"),
                State("3D-selected_profiles","value"),
                State("3D-selected_profiles","options"),
                State("3D-selected_curves_surf","value"),
                State("session-id","data"),
                State("mesh-name","value"),
                State("mesh-color","value"),
                prevent_initial_call=true
                ) do n_clicks, selected_profiles, selected_profile_options, selected_curves_surf, session_id, mesh_name, mesh_color
    
    global AppData
    AppDataUser = GeoDataPicker.get_AppDataUser(AppData,session_id)
    @show n_clicks, selected_profiles, selected_curves_surf

    
    # retrieve curves that were selected
    CurvesSelected = []
    for id in selected_profiles
        for Profile in AppDataUser.Profiles
            if Profile.number==id
                Polygons = Profile.Polygons
                for poly in Polygons
                    if poly.name == selected_curves_surf[1]
                        CurvesSelected = push!(CurvesSelected, poly)
                    end
                end
            end
        end
    end

    @show length(CurvesSelected)
    allowcircshift = CurvesSelected[1].closed

    # Create the triangulated surface from all selected curves
    mesh = triangulate_polygons(CurvesSelected[1],CurvesSelected[2], allowcircshift=allowcircshift)
    @show mesh
    for i = 2:length(CurvesSelected)-1
        mesh1 = triangulate_polygons(CurvesSelected[i],CurvesSelected[i+1], allowcircshift=allowcircshift)
        mesh = merge(mesh,mesh1)
    end
    mesh_surf = mesh_surface(mesh_color, mesh_name, mesh)
    @show mesh_name mesh_color
    # Add to plot or update if needed 
    if isempty(AppDataUser.Surfaces)
        # the new mesh will always be the first one
        push!(AppDataUser.Surfaces, mesh_surf)  
    else
        AppDataUser.Surfaces[1] = mesh_surf
    end

    AppData = set_AppDataUser(AppData, session_id, AppDataUser)

    return n_clicks
end





#=
callback!(app,  Output("button-add-mesh","n_clicks"), 
                Output("selected_meshes","options"),
                Input("button-add-mesh","n_clicks"),
                Input("button-clear-mesh","n_clicks"),
                Input("button-update-mesh","n_clicks"),
                State("session-id","data"),
                State("selected_meshes","options"), 
                State("mesh-name", "value"), 
                State("mesh-color","value"),
                State("selected_meshes","value")
                ) do n_add, n_del, n_update, fig_selected_data, session_id, mesh_names, name, 
                    color, selected_meshes
    global AppData
    AppDataLocal = get_AppData(AppData, session_id)
    
    trigger = get_trigger()
    
    # update options
    mesh_names = polygon_names(profile)

    if profile != []
        if trigger == "button-add-mesh.n_clicks"
        
            # create a curve struct from the latest shape
            if !isempty(shapes)
                curve = set_curve(shapes[end], profile; name=name, color=color, linewidth=1)

                # ensure that a curve with this name does not yet exist
                if !any(curve_names .== curve.name)
                    push!(profile.Polygons, curve)
                end
            end
        
        elseif trigger == "button-clear-mesh.n_clicks"
            id = findall(mesh_names .== selected_meshes)
            if !isempty(id)
                deleteat!(profile.Polygons, id)
                println("deleted mesh")
            end
            
        elseif trigger == "button-update-mesh.n_clicks"
            id = findall(curve_names .== selected_curves)
            if !isempty(id)
                curve_names_selected = String.(keys(fig_selected_data))
                curve = profile.Polygons[id[1]]
                if any(contains.(curve_names_selected,"shapes["))
                   # Update data & color
                   shape = fig_selected_data[Symbol(curve_names_selected[1])]
                   curve.data = shape
                   curve.shape = merge(curve.shape, (data_curve=shape, ))
                   update_curve!(curve, profile)   # update lon/lat/depth
                   println("updated data on curve")
                end
                curve.color = color
                
                profile.Polygons[id[1]] = curve
                println("updated curve: $selected_curves")
            end

        elseif trigger == "button-copy-curve.n_clicks"
                println("button-copy-curve.n_clicks")
                id = findall(curve_names .== selected_curves)
                if !isempty(id)
                    curve = deepcopy(profile.Polygons[id[1]])
                    AppDataUser = get_AppDataUser(AppData, session_id)
                    AppDataUser = merge(AppDataUser, (copy=curve,))
                    AppData     = set_AppDataUser(AppData, session_id, AppDataUser)

                    println("copied curve: $selected_curves")
                end
        elseif trigger == "button-paste-curve.n_clicks"
            
            # ensure that a curve with this name does not yet exist
            AppDataUser = get_AppDataUser(AppData, session_id)
            profile = get_active_profile(AppData, session_id, selected_profile)
            if AppDataUser.copy != []
                curve = AppDataUser.copy
                update_curve!(curve, profile)   # update lon/lat/depth

                push!(profile.Polygons, curve)
                println("pasted curve: $selected_curves")
            end

        end

    end

    curve_names = polygon_names(profile)
   
    return n_add, curve_names 
end
=#
    return app

end
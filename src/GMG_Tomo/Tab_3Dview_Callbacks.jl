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

    # Create the triangulated surface from all selected curves
    mesh = triangulate_polygons(CurvesSelected[1],CurvesSelected[2], allowcircshift=true)
    @show mesh
    for i = 2:length(CurvesSelected)-1
        mesh1 = triangulate_polygons(CurvesSelected[i],CurvesSelected[i+1], allowcircshift=true)
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


    return app

end
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


# open/close tomography box
callback!(app,
    Output("collapse-export-curves", "is_open"),
    [Input("button-export-curves", "n_clicks")],
    [State("collapse-export-curves", "is_open")], ) do  n, is_open
    
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

# Export curves to disk
callback!(app,
    Output("export-curves", "n_clicks"),
    Output("download-curves", "data"),
    Input("export-curves", "n_clicks"),
    State("curves-to-be-exported", "value"),
    State("session-id","data"),
    prevent_initial_call=true
    ) do  n_clicks, selected_curves, session_id

    global AppData
    AppDataUser = get_AppDataUser(AppData, session_id)
    Profiles = AppDataUser.Profiles

    SaveData = NamedTuple()
    for curve_name in selected_curves
      data_NT = retrieve_curves(Profiles, curve_name)

      SaveData = merge(SaveData, data_NT)
    end

    # export this to local disk
    save("ExportCurves.jld2", "Data",SaveData)
    file_data = read("ExportCurves.jld2")

    # Save data to file
    println("Downloading the selected curves to file: ExportCurves.jld2");
    println("Open this with:");
    println("julia> using JLD2, GeophysicalModelGenerator");
    println("julia> curves = load_object(\"ExportCurves.jld2\")");
    println("curves is a NamedTuple with the selected curves (vectors with different curves) the curves")
    
    return n_clicks,  dcc_send_bytes(file_data, "ExportCurves.jld2")    
end


    return app
end
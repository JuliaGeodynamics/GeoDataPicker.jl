# Callbacks for this tab

# Update the 3D plot
callback!(app,  Output("3D-image","figure"),
                Input("id-plot-3D","n_clicks"),
                State("colorbar-slider", "value"),
                State("id-3D-isosurface-slider","value"),
                State("id-3D-topo","value"),
                State("id-3D-volume","value"),
                State("dropdown_field","value"), 
                State("selected_cross-sections", "value"),
                State("session-id","data")
                ) do n_clicks, colorbar_value, colorbar_value_vol, val_topo, val_vol, field, selected_profiles, session_id 

    global AppData

    # compute profile
    AppDataLocal = get_AppData(AppData, session_id)
    pl = plot_3D_data(AppDataLocal, 
                        selected_cross=selected_profiles, 
                        add_volumetric=Bool(val_vol), 
                        add_topo=Bool(val_topo),
                        cvals=colorbar_value,
                        field=Symbol(field),
                        cvals_vol=colorbar_value_vol
                      )

    return pl
end

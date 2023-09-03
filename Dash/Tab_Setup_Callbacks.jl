
# This creates an initial session id that is unique for this session
callback!(app,  Output("session-id", "data"),
                Output("label-id","children"),
                Input("session-id", "data")
                ) do session_id

    session_id = UUIDs.uuid4()
    str = "id=$(session_id)"
    return String("$(session_id)"), str
end


# Load the data from the app
callback!(app,  Output("setup-button", "n_clicks"),
                Output("button-plot-topography", "n_clicks"),
                Output("button-plot-topography", "disabled"),
                Input("setup-button", "n_clicks"),
                State("session-id", "data"),
                State("button-plot-topography", "n_clicks"),
                State("start_val", "value"),
                State("end_val", "value")
                ) do n,  session_id, n_topo, start_value, end_value
    global AppData 
    if !isnothing(n)
        # This is some vanilla data
        DataTomo, DataTopo = load_dataset();

        # Initial cross-section
        start_val, end_val = extract_start_end_values(start_value, end_value)
        profile = ProfileUser(start_lonlat=start_val, end_lonlat=end_val)

        # User data that results from all GUI interactions
        # This should also hold info onm which data sets were loaded
        AppDataUser = (Profiles=[profile],)

        # Add the data to a NamedTuple
        data = (DataTomo=DataTomo, DataTopo=DataTopo, CrossSections=[], AppDataUser=AppDataUser)

        # Store it within the AppData global struct
        AppData = add_AppData(AppData, session_id, data)
        n_topo = 0

        plot_button_topo_disabled = false
    else
        plot_button_topo_disabled = true
        n=0
    end

    return n+1, n_topo, plot_button_topo_disabled
end

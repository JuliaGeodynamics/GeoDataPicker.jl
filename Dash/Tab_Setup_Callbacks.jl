
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
                Input("setup-button", "n_clicks"),
                State("session-id", "data"),
                State("button-plot-topography", "n_clicks"),
                ) do n,  session_id, n_topo
    global AppData 
    if !isnothing(n)
        # This is some vanilla data
        DataTomo, DataTopo = load_dataset();

        # Initial cross-section
        cross = get_cross_section(DataTomo, start_val, end_val)

        # Add the data to a NamedTuple
        data = (DataTomo=DataTomo, DataTopo=DataTopo, cross=cross, CrossSections=[])

        # Store it within the AppData global struct
        AppData = add_AppData(AppData, session_id, data)
        n_topo = 0
    else
        n=0
    end

    return n+1, n_topo
end

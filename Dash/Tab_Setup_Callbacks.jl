
# This creates an initial session id that is unique for this session
callback!(app,  Output("session-id", "data"),
                Output("label-id","children"),
                Input("session-id", "data")
                ) do session_id
    
    session_id = UUIDs.uuid4()
    str = "id=$(session_id)"
    
    # Save default Datasets to global struct
    global AppData
    AppData = add_AppData(AppData, "$session_id", (Datasets=Datasets,))

    return String("$(session_id)"), str
end




# Load the data from the app
callback!(app,  Output("setup-button", "n_clicks"),
                Output("button-plot-topography", "n_clicks"),
                Output("button-plot-topography", "disabled"),
                Output("tabs","activ_tab"),
                Output("dropdown_field","options"),
                Input("setup-button", "n_clicks"),
                State("session-id", "data"),
                State("button-plot-topography", "n_clicks"),
                State("start_val", "value"),
                State("end_val", "value"),
                State("data-screenshots","value"),
                State("data-tomo","value"),
                State("data-EQ","value"),
                State("data-surfaces","value"),
                State("data-screenshots","value"),
                ) do n,  session_id, n_topo, start_value, end_value, selected_screenshots,
                    active_tomo, active_EQ, active_surf, active_screenshots
    global AppData 
    AppDataLocal    = get_AppData(AppData, session_id)
    
    if !isnothing(n)
        println("Loading data")
        # We should really retrieve the active ones from the GUI
        Datasets = get_active_datasets(AppDataLocal.Datasets, active_tomo, active_EQ, active_surf, active_screenshots)

        # Load data
        DataTomo, DataTopo, DataPoints, DataSurfaces, DataScreenshots = load_dataset(Datasets);

        # Data sets present in the 3D tomographic data
        options_fields = [(label = String(f), value="$f" ) for f in keys(DataTomo.fields)]

        # Initial cross-section
        start_val, end_val = extract_start_end_values(start_value, end_value)
        profile = ProfileUser(start_lonlat=start_val, end_lonlat=end_val)

        # Add screenshots to profile if requested
        Profiles=[profile]
        num = 0;
        if !isempty(DataScreenshots)
            names = keys(DataScreenshots)
            for i=1:length(DataScreenshots)
                num += 1;
                profile = screenshot_2_profile(DataScreenshots[i], num, names[i])
                push!(Profiles, profile)
            end
        end

        # load colormaps
        colormaps = read_colormaps()

        # User data that results from all GUI interactions
        # This should also hold info onm which data sets were loaded
        AppDataUser = (Profiles=Profiles, copy=[], colormaps=colormaps)

        # Add the data to a NamedTuple
        data = (DataTomo=DataTomo, DataTopo=DataTopo, DataPoints=DataPoints, DataSurfaces=DataSurfaces,
                DataScreenshots=DataScreenshots, AppDataUser=AppDataUser,
                Datasets = Datasets)

        # Store it within the AppData global struct
        AppData = add_AppData(AppData, session_id, data)
        n_topo = 0

        plot_button_topo_disabled = false
        active_tab = "tab-cross"

        println("Finished loading data")

    else
        plot_button_topo_disabled = true
        n=0
        active_tab = "tab-setup"
        options_fields = []
    end

    return n+1, n_topo, plot_button_topo_disabled, active_tab, options_fields
end

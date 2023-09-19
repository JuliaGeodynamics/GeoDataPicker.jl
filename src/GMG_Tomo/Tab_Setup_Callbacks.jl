function Tab_Setup_Callbacks(app, Datasets, GUI_version)

# This creates an initial session id that is unique for this session
callback!(app,  Output("session-id", "data"),
                Output("label-id","children"),
                Input("session-id", "data")
                ) do session_id
    
    session_id = UUIDs.uuid4()
    str = "id=$(session_id), v=$(GUI_version)"
    
    # Save default Datasets to global struct
    global AppData, max_num_users
    AppData = add_AppData(AppData, "$session_id", (Datasets=Datasets, GUI_version=GUI_version))

    return String("$(session_id)"), str
end

# Load the data from the app
callback!(app,  Output("setup-button", "n_clicks"),
                Output("button-plot-topography", "n_clicks"),
                Output("button-plot-topography", "disabled"),
                Output("tabs","activ_tab"),
                Output("dropdown_field", "options"), 
                Output("loading-output-1","children"),
                Output("selected_EQ-data", "options"), 
                Output("selected_Surface-data", "options"), 
                Output("3D-selected_EQ_data","options"),
                Output("3D-selected_surfaces_data","options"),
                Input("setup-button", "n_clicks"),
                Input("output-upload_state", "children"),
                State("session-id", "data"),
                State("button-plot-topography", "n_clicks"),
                State("start_val", "value"),
                State("end_val", "value"),
                State("data-screenshots","value"),
                State("data-tomo","value"),
                State("data-EQ","value"),
                State("data-surfaces","value"),
                State("data-screenshots","value"),
                ) do n, upload_state, session_id, n_topo, start_value, end_value, selected_screenshots,
                    active_tomo, active_EQ, active_surf, active_screenshots
    global AppData 
    AppDataLocal    = get_AppData(AppData, session_id)
    
    trigger = get_trigger()
    if trigger=="setup-button.n_clicks"
        println("Loading data ...")

        # Retrieve the active ones from the GUI
        Datasets = get_active_datasets(AppDataLocal.Datasets, active_tomo, active_EQ, active_surf, active_screenshots)

        # Load data
        DATA = load_GMG(Datasets)
        DataVol         = DATA.Volume 
        DataSurfaces    = DATA.Surface
        DataPoints      = DATA.Point
        DataScreenshots = DATA.Screenshot
        DataTopo        = DATA.Topography
        DataTopo        = DataTopo[1] # We can only have one topo datasets

        # Combine volumetric data into 1 dataset
        lat     =  extrema(DataTopo.lat.val)
        lon     =  extrema(DataTopo.lon.val)
        depth   =  (-500,0)
        DataTomo = combine_VolData(DataVol; lat=lat, lon=lon, depth=depth, dims=(100,100,100))
        
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
                Datasets = Datasets, GUI_version=AppDataLocal.GUI_version)

        # Store it within the AppData global struct
        AppData = add_AppData(AppData, session_id, data)
        n_topo = 0

        plot_button_topo_disabled = false
        active_tab = "tab-cross"

        # Update dropdown menus
        options_fields      = get_options_vector(DataTomo.fields)
        options_EQ_fields   = get_options_vector(DataPoints)
        options_Surf_fields = get_options_vector(DataSurfaces)
        
        println("Finished loading data")
        load_output=""

        
    elseif trigger=="output-upload_state.children"
        
        # we just uploaded a new state file

        plot_button_topo_disabled = false
        active_tab = "tab-cross"
        n_topo = 0

        # Update dropdown menus
        options_fields      = get_options_vector(AppDataLocal.DataTomo.fields)
        options_EQ_fields   = get_options_vector(AppDataLocal.DataPoints)
        options_Surf_fields = get_options_vector(AppDataLocal.DataSurfaces)
        
    else
        plot_button_topo_disabled = true
        n=0
        active_tab = "tab-setup"
        options_fields = []
        options_EQ_fields = []
        options_Surf_fields = []
        load_output=""

    end

    return n+1, n_topo, plot_button_topo_disabled, active_tab, options_fields, "", 
           options_EQ_fields, options_Surf_fields,options_EQ_fields, options_Surf_fields
end


# Save state
callback!(app,
    Output("save-state", "n_clicks"), 
    Output("download-state", "data"),
    Input("save-state", "n_clicks"),
    State("session-id", "data"), 
    prevent_initial_call=true
) do n_save, session_id
    global AppData 
    AppDataLocal    = get_AppData(AppData, session_id)

    # Save this as local file
    save("State.jld2", "AppDataState",AppDataLocal)

    file_data = read("State.jld2")

    # Save data to file
    println("Downloading the current state to file: State.jld2")

    return n_save, dcc_send_bytes(file_data, "State.jld2")
end


# Upload state
callback!(app,
    Output("output-upload_state_n", "children"),
    Output("data-tomo", "options"),
    Output("data-tomo", "value"),
    Output("data-EQ", "options"),
    Output("data-EQ", "value"),
    Output("data-surfaces", "options"),
    Output("data-surfaces", "value"),
    Output("data-screenshots", "options"),
    Output("data-screenshots", "value"),
    Output("data-topography", "options"),
    Output("data-topography", "value"),
    
    Input("upload-state", "contents"),
    State("upload-state", "filename"),
    State("upload-state", "last_modified"),
    State("session-id", "data"),
    prevent_initial_call=true
) do contents, filename, last_modified, session_id
    global AppData 
    AppDataLocal    = get_AppData(AppData, session_id)

    if !(contents isa Nothing)

        # process uploaded binary stream and save it to file
        filename_dir = parse_uploaded_jld2_file(contents, filename, "uploaded_data");

        AppDataLocal_uploaded = load_object(filename_dir)
        if !hasfield(typeof(AppDataLocal_uploaded),:GUI_version)
            error("Statefile does not seem to be valid. fields are: $(keys(AppDataLocal_uploaded))")
        end
        if AppDataLocal.GUI_version != AppDataLocal_uploaded.GUI_version 
            println("Warning: Statefile was written for GUI v.$(AppDataLocal_uploaded.GUI_version), and the current one has v.$(AppDataLocal.GUI_version)")
        end
        
        # Save data into global structure
        AppData = add_AppData(AppData, session_id, AppDataLocal_uploaded)
    end

    AppDataLocal    = get_AppData(AppData, session_id)

    # update menus in Setup Tab_Setup_Callbacks
    options_vol     = dataset_options(AppDataLocal.Datasets, "Volume")[1]
    values_vol      = dataset_options(AppDataLocal.Datasets, "Volume")[2]
    options_point   = dataset_options(AppDataLocal.Datasets, "Point")[1]
    values_point    = dataset_options(AppDataLocal.Datasets, "Point")[2]
    options_surface = dataset_options(AppDataLocal.Datasets, "Surface")[1]
    values_surface  = dataset_options(AppDataLocal.Datasets, "Surface")[2]
    options_screen  = dataset_options(AppDataLocal.Datasets, "Screenshot")[1]
    values_screen   = dataset_options(AppDataLocal.Datasets, "Screenshot")[2]
    options_topo    = dataset_options(AppDataLocal.Datasets, "Topography")[1]
    values_topo     = dataset_options(AppDataLocal.Datasets, "Topography")[2]
    println("Loaded statefile ")

    return "",  options_vol,        values_vol,
                options_point,      values_point,
                options_surface,    values_surface,
                options_screen,     values_screen, 
                options_topo,       values_topo
end

    return app

end

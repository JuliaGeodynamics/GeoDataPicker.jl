# callbacks for the cross-sections tab
function Tab_CrossSections_Callback(app)


################### CALLBACKS RELATED TO TOPOGRAPHY PLOT ################
################## WILL POTENTIALLY BE MOVED TO A DIFFERENT FILE

# this is the callback that is invoked if the line on the topography map is changed
callback!(app,  Output("start_val", "value"),
                Output("end_val", "value"),
                Input("mapview", "relayoutData"),
                Input("mapview", "clickData"),
                State("selected_profile","value"),
                State("checklist_orientation", "value"),
                State("input-depth","value"),
                State("session-id","data"),
                State("start_val", "value"),
                State("end_val", "value")
                ) do value, clickData, selected_profile, vertical, depth, session_id, retStart, retEnd
    global AppData
    AppDataLocal    = get_AppData(AppData, session_id)
    trigger         = get_trigger()

    # if we move the line value on the cross-section it will update this here:
    start_val, end_val = get_startend_cross_section(value)
    if !isempty(trigger)
        AppDataUser = get_AppDataUser(AppData, session_id)
  
        # Update textbox values
        if !isnothing(start_val)
            retStart = "start: $(@sprintf("%.2f", start_val[1])),$(@sprintf("%.2f", start_val[2]))"
            retEnd   = "end: $(@sprintf("%.2f", end_val[1])),$(@sprintf("%.2f", end_val[2]))"
        end
               
        # Update the active cross-section (number 0) accordingly
        if !isnothing(start_val)
            profile = ProfileUser(number=0, start_lonlat=start_val, end_lonlat=end_val, vertical=vertical, depth=depth)
            AppDataLocal = update_profile(AppDataLocal, profile, num=0)
            AppData = add_AppData(AppData, session_id, AppDataLocal)
        end

    else
        # set the initial cross-section
        retStart = "start: 5.0,46.0"
        retEnd   = "end: 12.0,44.0"
    end

   return retStart, retEnd
end

# add, remove or change profiles
callback!(app,  Output("button-add-profile", "n_clicks"),
                Output("selected_profile", "options"),
                Output("selected_cross-sections","options"),

                Output("3D-selected_profiles","options"),

                Input("button-add-profile", "n_clicks"),
                Input("button-delete-profile", "n_clicks"),
                Input("button-update-profile", "n_clicks"),
                Input("setup-button", "n_clicks"),
                Input("output-upload_state_n", "children"),      # changes if we upload state
                Input("upload-profiles_n","children"),           # changes if we upload profiles   
                State("session-id","data"),
                State("selected_profile", "value"),
                ) do n_add, n_del, n_up, n_setup, upload_state, upload_profiles_n, session_id, selected_profile
    
    global AppData
    AppDataUser = get_AppDataUser(AppData, session_id)
    trigger = get_trigger()

    if hasfield(typeof(AppDataUser), :Profiles)
        profile = deepcopy(AppDataUser.Profiles[1])         # retrieve profile
        number_profiles =  get_number_profiles(AppDataUser.Profiles)    # get numbers
    end
    
    if trigger == "button-add-profile.n_clicks"
        profile = deepcopy(AppDataUser.Profiles[1])    
        profile.number = maximum(number_profiles)+1         # new number
        push!(AppDataUser.Profiles, profile)               # add to data structure 
        AppData = set_AppDataUser(AppData, session_id, AppDataUser)
        println("Added profile: vertical=$(profile.vertical)")
    elseif trigger == "button-delete-profile.n_clicks"
        if !isnothing(selected_profile) 
            if selected_profile>0
                id = findall(number_profiles .== selected_profile)
                Profiles = AppDataUser.Profiles

                deleteat!(Profiles, id)
                number_profiles =  get_number_profiles(AppDataUser.Profiles)    # get numbers
            end
        end
    elseif trigger == "button-update-profile.n_clicks"
        if !isnothing(selected_profile) 
            id = findall(number_profiles .== selected_profile)
            profile = deepcopy(AppDataUser.Profiles[1])           # main profile
            profile_selected = AppDataUser.Profiles[id[1]]        # profile to be updated

            # update the coordinates (but leave polygons)
            profile_selected.start_lonlat = profile.start_lonlat
            profile_selected.end_lonlat   = profile.end_lonlat
            profile_selected.start_cart   = profile.start_cart
            profile_selected.end_cart     = profile.end_cart
            profile_selected.vertical     = profile.vertical
            profile_selected.depth        = profile.depth
            
        end
    elseif trigger=="output-upload_state.children"

    end

    # Get options and values
    if  hasfield(typeof(AppDataUser), :Profiles)
        options = get_profile_options(AppDataUser.Profiles)
    else
        options = [(label="default profile", value=0)] 
    end
    
    return n_add, options, options, options
end

# Main feedback that updates the topography plot
callback!(app,  Output("mapview", "figure"),
                Output("button-add-profile","disabled"),
                Output("button-update-profile","disabled"),
                Output("button-delete-profile","disabled"),
                Output("selected_profile","value"),
                Output("button-plot-cross_section","n_clicks"),
                Input("button-plot-topography","n_clicks"),
                Input("selected_profile","value"),
                Input("selected_profile","options"),
                Input("start_val","n_submit"), 
                Input("end_val","n_submit"), 
                Input("input-depth","n_submit"), 
                Input("output-upload_state", "children"),
                State("checklist_orientation", "value"),
                State("start_val", "value"),
                State("end_val", "value"),
                State("input-depth","value"),
                State("session-id","data"),
                State("button-plot-cross_section","n_clicks"),
                prevent_initial_call=true
                ) do n_clicks, selected_profile, selected_profile_options, n_start_value, n_end_value, n_depth, upload_state, vertical, start_value, end_value, depth, session_id, n_clicks_cross
    global AppData
    AppDataLocal = get_AppData(AppData, session_id)

    trigger = get_trigger()
    if (!isnothing(n_clicks))  
        AppDataUser = get_AppDataUser(AppData, session_id)

        # extract numerical values of start & end
        start_val, end_val = extract_start_end_values(start_value, end_value)
        if vertical==true
            depth  = nothing
        end

        profile = ProfileUser(number=0, start_lonlat=start_val, end_lonlat=end_val, vertical=vertical, depth=depth)
        
        if !isnothing(selected_profile)
            if selected_profile>0
                if hasfield(typeof(AppDataUser),:Profiles)
                    number_profiles =  get_number_profiles(AppDataUser.Profiles)    # get numbers
                    id = findall(number_profiles .== selected_profile)
                    if !isempty(id)
                        profile = deepcopy(AppDataUser.Profiles[id[1]])
                        profile.number = 0
                      
                    end
                end
            end
        end
        

        AppDataUser.Profiles[1] = profile
        AppData = set_AppDataUser(AppData, session_id, AppDataUser)
        AppDataLocal   = get_AppData(AppData, session_id)
        AppDataLocal = update_profile(AppDataLocal, profile, num=0)
        AppData = add_AppData(AppData, session_id, AppDataLocal)

        fig_topo       = plot_topo(AppDataLocal,session_id)
        but_add_prof_disabled=false
        but_up_prof_disabled=false
        but_del_prof_disabled=false

    else
        fig_topo = [];
        but_add_prof_disabled = true 
        but_up_prof_disabled  = true
        but_del_prof_disabled = true
    end
    if isnothing(n_clicks_cross)
        n_clicks_cross=0
    else
        n_clicks_cross += 1
    end

    #selected_profile = 0
    return fig_topo, but_add_prof_disabled, but_up_prof_disabled, but_del_prof_disabled, selected_profile, n_clicks_cross
end


############ THIS SHOULD BE THE END OF ALL THE CALLBACKS FOR THE TOPOGRAPHY PLOT ###################


############ CALLBACKS FOR CROSS SECTION PLOT ###############

# open/close Curve interpretation box
callback!(app,
    Output("collapse", "is_open"),
    [Input("button-curve-interpretation", "n_clicks")],
    [State("collapse", "is_open")], ) do  n, is_open
    
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

# open/close EQ interpretation box
callback!(app,
    Output("collapse-EQ", "is_open"),
    [Input("button-EQ", "n_clicks")],
    [State("collapse-EQ", "is_open")], ) do  n, is_open
    
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

# open/close Surfaces box
callback!(app,
    Output("collapse-Surfaces", "is_open"),
    [Input("button-Surfaces", "n_clicks")],
    [State("collapse-Surfaces", "is_open")], ) do  n, is_open
    
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

# open/close screenshot box
callback!(app,
    Output("collapse-Screenshots", "is_open"),
    [Input("button-Screenshots", "n_clicks")],
    [State("collapse-Screenshots", "is_open")], ) do  n, is_open
    
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

# open/close tomography I box
callback!(app,
    Output("collapse-Tomography", "is_open"),
    [Input("button-Tomography", "n_clicks")],
    [State("collapse-Tomography", "is_open")], ) do  n, is_open
    
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

# open/close tomography II box
callback!(app,
    Output("collapse-TomographyII", "is_open"),
    [Input("button-TomographyII", "n_clicks")],
    [State("collapse-TomographyII", "is_open")], ) do  n, is_open
    
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

# open/close Curve interpretation box
callback!(app,
    Output("input-depth", "disabled"),
    [Input("checklist_orientation", "value")] ) do  vertical
    
    if isnothing(vertical); vertical=true; end
    
    return vertical 
end


# CALLBACK FOR THE PLOT CROSS-SECTION BUTTON
callback!(app,  Output("cross_section", "figure"), 
                Output("3D-selected_curves","options"),
                Output("curves-to-be-exported","options"),
                Output("3D-selected_curves_surf","options"),
                Input("button-plot-cross_section","n_clicks"),
                #Input("dropdown_field","n_clicks"), # test if this triggers correctly
                State("dropdown_field","value"),
                State("dropdown_fieldII","value"),
                State("colorbar-slider", "value"),
                State("session-id","data"),
                State("selected_profile","value"),
                State("colormaps_cross","value"),
                State("screenshot-display","value"),
                State("screenshot-opacity","value"),
                State("tomography-opacity","value"),
                State("tomography-display","value"),
                State("tomography-displayII","value"),
                State("EQ-display","value"),
                State("Surfaces-display","value"),
                State("selected_Surface-data","value"),
                State("selected_EQ-data","value"),
                State("EQ-section_width","value"),
                State("EQ-minMag","value"),
                State("EQ-maxMag","value"),
                
                ) do n_clicks,
                    field, fieldII, colorbar_value, session_id, selected_profile, colormap_field, screenshot_display, screenshot_opacity, cross_section_opacity,
                    plot_tomography, plot_tomographyII, plot_earthquakes, plot_surfaces, selected_surf_data, selected_EQ_data, section_width,
                    EQ_minMag, EQ_maxMag

    AppDataLocal = get_AppData(AppData, session_id)
    profile = get_active_profile(AppData, session_id, selected_profile)

    # now update the cross section plot
    # here we simply aggregate the different n_clicks values
    N_CLICKS = n_clicks + n_clicks_dropdown

    @show profile session_id
    if (N_CLICKS>0) && !isnothing(profile)
        @show profile
        fig_cross = plot_cross(AppDataLocal, profile, 
                                zmin=colorbar_value[1], zmax=colorbar_value[2], field=Symbol(field), colormap=colormap_field,
                                screenshot_display=screenshot_display, screenshot_opacity=screenshot_opacity, 
                                cross_section_opacity=cross_section_opacity,
                                plot_tomography = plot_tomography,
                                plot_tomographyII = plot_tomographyII,
                                plot_surfaces = plot_surfaces, selected_surf_data= selected_surf_data,
                                plot_earthquakes=plot_earthquakes,selected_EQ_data=selected_EQ_data,
                                section_width=section_width, EQmag = (EQ_minMag,EQ_maxMag),
                                ) 
        
        curve_names = get_curve_names(AppDataLocal.AppDataUser.Profiles)
        @show keys(fig_cross)
    else
        fig_cross = []
        curve_names = []
    end

    return fig_cross, curve_names, curve_names, curve_names
end

# ???
callback!(app,  Output("button-add-curve","n_clicks"), 
                Output("selected_curves","options"),
                Input("button-add-curve","n_clicks"),
                Input("button-clear-curve","n_clicks"),
                Input("button-update-curve","n_clicks"),
                Input("button-copy-curve","n_clicks"),
                Input("button-paste-curve","n_clicks"),
                Input("cross_section","figure"),
                Input("cross_section", "relayoutData"),
                State("session-id","data"),
                State("selected_profile","value"),
                State("selected_curves","options"), 
                State("shape-name", "value"), 
                State("shape-color","value"),
                State("selected_curves","value")
                ) do n_add, n_del, n_update, n_copy, n_paste, fig_cross, fig_selected_data, session_id, selected_profile, curve_names, name, 
                    color, selected_curves
    global AppData
    AppDataLocal = get_AppData(AppData, session_id)
    
    trigger = get_trigger()
    shapes =  get_current_shapes(fig_cross)
    profile = get_active_profile(AppData, session_id, selected_profile)

    # update options
    curve_names = polygon_names(profile)

    if profile != []
        if trigger == "button-add-curve.n_clicks"
        
            # create a curve struct from the latest shape
            if !isempty(shapes)
                curve = set_curve(shapes[end], profile; name=name, color=color, linewidth=1)

                # ensure that a curve with this name does not yet exist
                if !any(curve_names .== curve.name)
                    push!(profile.Polygons, curve)
                end
            end
        
        elseif trigger == "button-clear-curve.n_clicks"
            id = findall(curve_names .== selected_curves)
            if !isempty(id)
                deleteat!(profile.Polygons, id)
                println("deleted curve")
            end
            
        elseif trigger == "button-update-curve.n_clicks"
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



# export/import button & field
callback!(app,
    Output("collapse-export-import", "is_open"),
    [Input("button-export-import", "n_clicks")],
    [State("collapse-export-import", "is_open")], ) do  n, is_open
    
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


# Export profiles to disk
callback!(app,
    Output("button-export-profiles", "n_clicks"),
    Output("download-profiles", "data"),
    Input("button-export-profiles", "n_clicks"),
    State("session-id","data"),
    prevent_initial_call=true
    ) do  n_clicks, session_id

    global AppData
    AppDataUser = get_AppDataUser(AppData, session_id)
    Profiles    = AppDataUser.Profiles

    # export this to local disk
    save("ExportProfiles.jld2", "Profiles",Profiles)
    file_data = read("ExportProfiles.jld2")

    # Save data to file
    println("Downloading the exported profiles to file: ExportProfiles.jld2");
    println("Open this with:");
    println("julia> using JLD2, GeophysicalModelGenerator");
    println("julia> Profiles = load_object(\"ExportProfiles.jld2\")");
    println("Profiles is a NamedTuple with the selected profiles and curves")
    println("You can import it again at a later stage & overwrite the current profiles")
    
    
    return n_clicks,  dcc_send_bytes(file_data, "ExportProfiles.jld2")    
end


# Import profiles from disk
callback!(app,
    Output("upload-profiles_n", "children"),
    Output("upload-profiles_component","children"),     # this is a bug workaround - see https://github.com/plotly/dash-core-components/issues/816
    Input("upload-profiles", "contents"),
    State("upload-profiles", "filename"),
    State("upload-profiles", "last_modified"),
    State("session-id", "data"),
    prevent_initial_call=true
    ) do   contents,filename, last_modified, session_id
    global AppData 
    
    @show filename, contents
    children = ""
    if !(contents isa Nothing)
        println("uploading Profiles with filename $filename")

        # process uploaded binary stream and save it to file
        filename_dir = parse_uploaded_jld2_file(contents, filename, "uploaded_data_profiles");

        Profiles_uploaded = load_object(filename_dir)
        
        # do some basic checking
        if !isa(Profiles_uploaded, Vector{ProfileUser})
            error("Profiles_uploaded appears to not have the correct type")
        else
            println("Uploading profiles:")
            for prof in Profiles_uploaded
                println(" $(prof.name)")
            end
        end
        AppDataUser = get_AppDataUser(AppData, session_id)
        
        # Merge the new profiles with the existing ones if the coordinates match
        Profiles_existing = AppDataUser.Profiles
        for prof_upload in Profiles_uploaded
            for (i,prof_exist) in enumerate(Profiles_existing)
                if prof_exist.start_lonlat == prof_upload.start_lonlat &&
                     prof_exist.end_lonlat == prof_upload.end_lonlat
                     Profiles_existing[i] = prof_upload;
                end
            end
        end

        for prof in Profiles_existing
            Profiles_uploaded = push!(Profiles_uploaded, prof)
        end
        Profiles_uploaded = unique(Profiles_uploaded)

        # Save data into global structure
        AppDataUser = merge(AppDataUser, (Profiles=Profiles_uploaded,))
        AppData     = set_AppDataUser(AppData, session_id, AppDataUser)
        
        println("Merge new profiles with existing ones (replacing the ones with duplicate names)")
        children = zip(contents, filename, last_modified)

        return children, dcc_upload(id="upload-profiles", children=dbc_button("Import Profiles"))
    end

    return nothing
end





return app

end
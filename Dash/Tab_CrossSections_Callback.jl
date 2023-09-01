# callbacks for the cross-sections tab


# Main feedback that updates the topography plot
callback!(app,  Output("mapview", "figure"),
                Input("button-plot-topography","n_clicks"),
                State("session-id","data")) do n_clicks, session_id
    
    @show n_clicks, session_id
    
    if !isnothing(n_clicks)  
        AppDataLocal = get_AppData(AppData, session_id)
        fig_topo = plot_topo(AppDataLocal)
        selected_field = AppDataLocal.cross.selected_field;

    else
        fig_topo = [];
    end
 
    return fig_topo
end


#=
# this is the callback that is invoked if the line on the topography map is changed
callback!(app,  Output("start_val", "value"),
                Output("end_val", "value"),
                Output("colorbar-slider", "value"),
                Input("mapview", "relayoutData"),
                Input("dropdown_field","value"),
                Input("mapview", "clickData"),
                Input("colorbar-slider", "value"),
                State("session-id","data")
                ) do value, selected_field, clickData, colorbar_value, session_id
    global AppData
    AppDataLocal = get_AppData(AppData, session_id)

    # if we move the line value on the cross-section it will update this here:
    if AppDataLocal.move_cross==false
        start_val, end_val = get_startend_cross_section(value)
    else
        start_val = AppData.cross.start_lonlat
        end_val   = AppData.cross.end_lonlat
    end
    if isnothing(start_val)
        start_val = AppData.cross.start_lonlat
    end
    if isnothing(end_val)
        end_val = AppData.cross.end_lonlat
    end
    
    shapes = AppDataLocal.cross.Polygons
    cross = get_cross_section(AppDataLocal.DataTomo, start_val, end_val, Symbol(selected_field))
    cross.Polygons = shapes

    # update cross-section in AppData
    AppDataLocal = (AppDataLocal..., cross=cross,move_cross=false);

    # Update textbox values
    retStart = "start: $(@sprintf("%.2f", start_val[1])),$(@sprintf("%.2f", start_val[2]))"
    retEnd   = "end: $(@sprintf("%.2f", end_val[1])),$(@sprintf("%.2f", end_val[2]))"

    

    return retStart, retEnd, colorbar_value
end




# Updates the topography plot if we change the numerical start/end values or if we push the plot topo button
callback!(app,  Output("mapview", "figure"),
                Output("dropdown_field", "value"),
                Input("button-plot-topography","n_clicks"),
                State("start_val", "n_submit"),
                State("end_val", "n_submit"),
                State("start_val", "value"),
                State("end_val", "value"),
                State("session_id","data")) do n_clicks, n_start, n_end, start_value, end_value, session_id
                    
    println("changed topo")
    AppDataLocal = get_AppData(AppData, session_id)

    #=
    @show AppDataLocal
    if isnothing(n_start); n_start=0 end
    if isnothing(n_end); n_end=0 end
   
    if n_start>0 || n_end>0

            # extract numerical values of start & end
            start_val, end_val = extract_start_end_values(start_value, end_value)

            # compute new cross-section
            selected_field = AppData.cross.selected_field;
            shapes = AppData.cross.Polygons
            if AppData.active_crosssection==0
                cross = get_cross_section(AppData.DataTomo, start_val, end_val, selected_field)
            else
                cross = AppData.cross;
            end
            cross.Polygons = shapes;

            # perhaps empty shapes, as this is a new cross-section?

            # update cross-section in AppData
            AppData = (AppData..., cross=cross, move_cross=true);
            
            # update topo plot
            fig_topo = plot_topo(AppData)

    else
        fig_topo = plot_topo(AppDataLocal)
        selected_field = AppDataLocal.cross.selected_field;

    end
    =#
    fig_topo = plot_topo(AppDataLocal)
    selected_field = AppDataLocal.cross.selected_field;

    return fig_topo, String(selected_field)
    
end

# Updates the cross-section if we change the field or color axes
callback!(app,  Output("button-plot-cross_section","n_clicks"), 
                Input("dropdown_field","value"),
                Input("colorbar-slider", "value"),
                Input("button-plot-cross_section","n_clicks"),
                State("session_id","data")) do selected_field, colorbar_value, n_clicks, session_id
    global AppData
    AppDataLocal = get_AppData(AppData, session_id)

    if !isnothing(colorbar_value)
        start_val = AppDataLocal.cross.start_lonlat
        end_val   = AppDataLocal.cross.end_lonlat
        
        shapes = AppDataLocal.cross.Polygons
        cross = get_cross_section(AppDataLocal.DataTomo, start_val, end_val, Symbol(selected_field))
        cross.Polygons = shapes

        AppDataLocal = (AppDataLocal..., cross=cross)

        # increment button click to replot (will auto-replot cross-section)
        if isnothing(n_clicks) 
            n_clicks=0
        end
        return n_clicks+1
    end

end

# replot the cross-section
callback!(app,  Output("cross_section", "figure"), 
                Input("button-plot-cross_section","n_clicks"),
                State("colorbar-slider", "value"),
                State("session_id","data")) do n_clicks, colorbar_value, session_id
    global AppData
    AppDataLocal = get_AppData(AppData, session_id)
    if !isnothing(n_clicks)
        fig_cross = plot_cross(AppDataLocal.cross, zmin=colorbar_value[1], zmax=colorbar_value[2]) 
    else
        fig_cross = plot_cross(AppDataLocal.cross)
    end

    return fig_cross
end

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

callback!(app,  Output("relayout-data", "children"), 
                Input("button-update-curve","n_clicks"),
                State("shape-name","value"),            # curves potentially added to cross-section
                State("shape-linewidth","value"),       # curves potentially added to cross-section
                State("shape-color","value"),
                State("cross_section","figure"),
                State("session_id","data")
                ) do n, name, linewidth, colorname, fig_cross, session_id
    
    # retrieve dataset
    AppDataLocal = get_AppData(AppData, session_id)
    if isnothing(n); n=0 end

    shapes = interpret_drawn_curve(fig_cross.layout)
    
    # update values of last shape
    if !isempty(shapes)
        id = findall(colornames.==colorname);
        col = colorvalues[id][1]

        shape = shapes[end]
        shape = (shape..., label_text=name, line_width=linewidth, line_color=col)
        shapes[end] = shape
    end

    if hasfield(typeof(AppDataLocal),:cross)
        if !isempty(AppDataLocal.cross.Polygons)
            shape = AppDataLocal.cross.Polygons[end]
            
            # update latest curve (any changes made on the plot)
            AppDataLocal.cross.Polygons[end] = shapes[end]
        end
    end
    
    return nothing 

end


callback!(app,  Output("button-add-curve","n_clicks"), 
                Input("button-add-curve","n_clicks"),
                State("cross_section","figure"),
                State("session_id","data")
                ) do n, fig_cross, session_id

    # retrieve dataset
    if !isnothing(n)
        AppDataLocal = get_AppData(AppData, session_id)
        shapes = interpret_drawn_curve(fig_cross.layout)
        AppDataLocal.cross.Polygons = shapes

        if AppDataLocal.active_crosssection>0
            @show AppDataLocal.active_crosssection

            CrossSections = AppDataLocal.CrossSections
            for i=1:length(CrossSections)
                if CrossSections[i].Number == AppDataLocal.active_crosssection
                    CrossSections[i] = AppDataLocal.cross;
                    CrossSections[i].Number = AppDataLocal.active_crosssection
                end
            end
            AppDataLocal.CrossSections = CrossSections
        end
    end

    return n 
end


callback!(app,  Output("button-clear-curve","n_clicks"), 
                Input("button-clear-curve","n_clicks"),
                ) do n

    # retrieve dataset
    if !isnothing(n)
        AppData.cross.Polygons = []
    end

    return n 

end



# save current cross-section to list
callback!(app,  Output("button-add-profile","n_clicks"),
                Output("num_profiles","component_name"),
                Output("start_val", "n_submit"),
                Output("dropdown-profiles","options"),
                Input("button-add-profile","n_clicks"),
                Input("num_profiles","className"),
                Input("start_val", "n_submit"),
                State("mapview", "figure"),
                State("session_id","data")
                ) do n, comp_name, n_start, fig_map, session_id
    global AppData
    AppDataLocal = get_AppData(AppData, session_id)

    tr = callback_context().triggered;
    @show tr

    if !isempty(tr)
        trigger = callback_context().triggered[1]
        @show trigger 
    end

    # retrieve dataset
    prof_names=[""]
    if !isnothing(n)
        cross = AppDataLocal.cross
        n_cross = length(AppDataLocal.CrossSections)
        if cross.Number==0
            cross.Number = n_cross+1
        end
        # Add to data set
        push!(AppDataLocal.CrossSections, AppDataLocal.cross)
        # Update profile names
        prof_names = profile_names(AppData)

    end
    if isnothing(n_start)
        n_start=0
    end
    return n, comp_name, n_start+1, prof_names 
    
   
end

# select a profile
callback!(app,  Output("dropdown-profiles","value"),
                Output("end_val", "n_submit"),
                Input("dropdown-profiles","value"),
                Input("end_val", "n_submit"),
                State("session_id","data")
                ) do select_profile, n_end, session_id

    global AppData
    AppDataLocal = get_AppData(AppData, session_id)
    if !isnothing(select_profile)
        if select_profile != "none"
             _, num = split(select_profile)
             n = parse(Int64,num)
             @show num, select_profile
             
             for cr in AppDataLocal.CrossSections
                @show cr.Number
                if cr.Number==n
                    @show n
                    cross = cr
                    # update AppData
                    AppDataLocal = (AppDataLocal...,  cross=cross, active_crosssection=n)
                end
             end
        else
            AppDataLocal = (AppDataLocal...,  active_crosssection=0)
        end
    end
    if isnothing(n_end)
        n_end=0
    end

    return select_profile, n_end+1
end

# delete a profile
callback!(app,  Output("button-delete-profile","n_clicks"),
                Input("button-delete-profile","n_clicks"),
                State("dropdown-profiles","value"),
                State("session_id","data")
                ) do n_delete, select_profile, session_id

    global AppData
    AppDataLocal = get_AppData(AppData, session_id)
    if !isnothing(n_delete)
        if select_profile != "none"
            _, num = split(select_profile)
            n = parse(Int64,num)
             
            CrossSections = AppDataLocal.CrossSections 
            id_delete = 0
            for i = 1:length(AppDataLocal.CrossSections)
                if CrossSections[i].Number==n
                    id_delete=i
                    @show id_delete
                    deleteat!(CrossSections, id_delete)
                end
            end
            @show id_delete
            @show length(CrossSections)
            # delete x-section
            
            # update AppData
            AppDataLocal = (AppDataLocal...,  CrossSections=CrossSections, active_crosssection=0)

        else
            AppDataLocal = (AppDataLocal...,  active_crosssection=0)
        end
    end
    if isnothing(n_delete)
        n_delete=0
    end
    @show n_delete
   # prof_names = profile_names(AppData)

    return n_delete+1, "none"
end

=#
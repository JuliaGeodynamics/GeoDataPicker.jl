

function Tab_Map()
    dbc_row([

            # plot topography
            dbc_col(html_div(create_topo_plot(AppData))),
            
            # various menus for profile selection @ lower right
            dbc_col(
                dbc_card([
                    dcc_markdown("### Profile options"),
                    dcc_markdown(" **Vertical profile:** Select 'vertical' and then insert the starting and ending point. After that, click on the '+' to add this profile to the list."),
                    dbc_radioitems(id="checklist_orientation",options=[(label="vertical", value=true),(label="horizontal", value=false)], inline=true, value=true),
                    dbc_row([
                    dbc_col([dcc_input(id="start_val", name="start_val", type="text", value="start: 5,46",style = Dict(:width => "100%"), debounce=true)]),
                    dbc_col([dcc_input(id="end_val", name="end_val", type="text", value="end: 10,45",style = Dict(:width => "100%"),placeholder="min")])
                    ]),
                    dbc_row([dbc_col(dbc_label("depth [km]")), dbc_col(dbc_input(value=100,type="number",id="input-depth", disabled=true))]),
                    dbc_row(dbc_col(dbc_button("Plot profile location", id="button-plot-topography", disabled=true), width=12),justify="center"),
                    dbc_row(dbc_buttongroup([dbc_button(" - ", id="button-delete-profile", disabled=true),
                    dbc_button("update", id="button-update-profile", disabled=true),
                    dbc_button(" + ", id="button-add-profile", disabled=true)]), justify="center"),
                    dbc_card(dbc_radioitems(id="selected_profile",options=[(label="Profile 0", value="Profile 0")]))
                ]), align="center", 
            width=2),
        
    ])
    
end


function Tab_CrossSection()
    html_div([
        dbc_col([
            # plot with cross-section
            dbc_row([dbc_col([cross_section_plot()], width=10),
                     dbc_col([
                                dbc_row([dbc_button("Curve Interpretation",id="button-curve-interpretation"),
                                         dbc_collapse(
                                             dbc_card(dbc_cardbody([
                                                dbc_row([
                                                    dbc_row(dbc_label("Options"),justify="center"),
                                                   # dbc_checkbox(label="lock curve", id="lock-curve"),

                                                     dbc_row([dbc_col(dbc_label("Name:"),align="center", width=5),
                                                             dbc_col(dbc_input(placeholder="Name of curve",id="shape-name"), width=6)]),

                                                    dbc_row([dbc_col(dbc_label("Linewidth:"),align="center", width=5),
                                                             dbc_col(dbc_input(placeholder="Linewidth",id="shape-linewidth", value="1", type="number"))
                                                            ]),

                                                    dbc_row([dbc_col(dbc_label("Colors:"),align="center", width=5),
                                                            dbc_col(dcc_dropdown(options=colornames,id="shape-color", value="black", clearable=false))
                                                           ]),

                                                    dbc_button("Update props of last curve",id="button-update-curve"),
                                                    dbc_button("Add all curves to profile",id="button-add-curve"),
                                                    dbc_button("Clear all curves",id="button-clear-curve"),
                                                    
                                                ])
                                                ])),
                                             id="collapse",
                                             is_open=false,
                                         ),
                                         dbc_button("Plot cross-section",id="button-plot-cross_section")
                                ])

                        
                            ], align="center"),
                    ], justify="center"),

            # info below plot
            dbc_row([
                    dbc_col([dcc_input(id="start_val", name="start_val", type="text", value="start: 5,46",style = Dict(:width => "100%"), debounce=true)]),
                    dbc_col([dcc_dropdown(
                                    id="dropdown_field",
                                    options = options_fields,
                                    value = "dVp_paf21",
                                    clearable=false, placeholder="Select Dataset",
                                ),
                                ]),
                    dbc_col([ dcc_rangeslider(
                                    id = "colorbar-slider",
                                    min = -5.,
                                    max = 5.,
                                    #step = .1,
                                    value=[-3, 3],
                                    allowCross=false,
                                    #marks = Dict([i => ("$i") for i in [-10, -5, 0, 5, 10]])
                                ),    
                                ]),
                    dbc_col([dcc_input(id="end_val", name="end_val", type="text", value="end: 10,45",style = Dict(:width => "100%"),placeholder="min")])
                    ]),
            ], width=12),

            # lower row | topography plot & buttons
            dbc_row([
                # plot topography
                dbc_col([create_topo_plot(AppData)]),
                
                # various menus @ lower right
                dbc_col([
                    dbc_row(dbc_col(dcc_markdown("Profile options")),justify="center"),
                    dbc_row(dbc_radioitems(id="checklist_orientation",options=[(label="vertical", value=true),(label="horizontal", value=false)], inline=true, value=true)),
                    dbc_row([dbc_col(dbc_label("depth [km]")), dbc_col(dbc_input(value=100,type="number",id="input-depth", disabled=true))]),
                    dbc_row([dbc_button("Plot topography", id="button-plot-topography", disabled=true)]),
                    dbc_row([dbc_buttongroup([dbc_button("add", id="button-add-profile", disabled=true),
                                              dbc_button("update", id="button-update-profile", disabled=true),
                                              dbc_button("delete", id="button-delete-profile", disabled=true)])]),
                    #dbc_row([dcc_dropdown(options=["none"], id="dropdown-profiles", placeholder="Select profile", disabled=true)]),
                    #dbc_row([dcc_dropdown(options=["none"], id="dropdown-profiles", placeholder="Select profile", disabled=true)]),
                    dbc_row(dbc_radioitems(id="selected_profile",options=[(label="Profile 0", value="Profile 0")]))

                ], align="center", width=3)
                #dbc_col([
                #    dbc_row([html_button(id="button-select", name="select", n_clicks=0, contentEditable=true)])
                #])
            ])
    ])

end


function Tab_CrossSection()
        dbc_row([dbc_col([
            # plot with cross-section
            dbc_row([dbc_col([cross_section_plot()], width=8),
                    ], justify="center"),

            # info below plot
            dbc_row([
                    dbc_col([dcc_input(id="start_val", name="start_val", type="text", value="start: 5,46",style = Dict(:width => "100%"), debounce=true)]),
                    dbc_col([dcc_dropdown(
                                    id="dropdown_field",
                                    options = [],
                                    value = "DataTomo_dVp_paf21",
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
                                ),    
                                ]),
                    dbc_col([dcc_input(id="end_val", name="end_val", type="text", value="end: 10,45",style = Dict(:width => "100%"),placeholder="min")])
                    ]),
            ], width=12),

            # lower row | topography plot & buttons
                dbc_row([
                # plot topography
                dbc_col(html_div(create_topo_plot(AppData)), lg=(width=5, offset=2)),
                
                
                    # various menus @ lower right
                    dbc_col(
                        dbc_card([
                                  dcc_markdown("Profile options"),
                        dbc_radioitems(id="checklist_orientation",options=[(label="vertical", value=true),(label="horizontal", value=false)], inline=true, value=true),
                        dbc_row([dbc_col(dbc_label("depth [km]")), dbc_col(dbc_input(value=100,type="number",id="input-depth", disabled=true))]),
                        dbc_row(dbc_col(dbc_button("Plot profile location", id="button-plot-topography", disabled=true), width=12),justify="center"),
                        dbc_row(dbc_buttongroup([dbc_button(" - ", id="button-delete-profile", disabled=true),
                                                dbc_button("update", id="button-update-profile", disabled=true),
                                                dbc_button(" + ", id="button-add-profile", disabled=true)]), justify="center"),
                                                
                         dbc_card(dbc_radioitems(id="selected_profile",options=[(label="Profile 0", value="Profile 0")]))]), align="center", width=2),
                

                    #])), align="center", width=2),
                #dbc_col([
                #    dbc_row([html_button(id="button-select", name="select", n_clicks=0, contentEditable=true)])
                #])

                dbc_col([
                    dbc_row([dbc_button("Curve Interpretation",id="button-curve-interpretation"),
                             dbc_collapse(
                                 dbc_card(dbc_cardbody([
                                    dbc_row([
                                        dbc_row(dbc_label("Options"),justify="center"),
                                         dbc_row([dbc_col(dbc_input(placeholder="Name",   id="shape-name")),
                                                  dbc_col(dbc_input(id="shape-color",     type="color"), width=4) ])
                                                 ]),
                                        dbc_row( dbc_card(dbc_radioitems(id="selected_curves",options=[(label="",)]))),

                                        dbc_row(dbc_buttongroup([   dbc_button(" - ",id="button-clear-curve"),
                                                                    dbc_button("update",id="button-update-curve"),
                                                                    dbc_button(" + ",id="button-add-curve")]), justify="center"),

                                        dbc_row(dbc_buttongroup([   dbc_button("copy",id="button-copy-curve"),
                                                                    dbc_button("paste",id="button-paste-curve")
                                                                    ]), justify="center")          
                                        
                                    ])
                                    
                                  ),
                                 id="collapse",
                                 is_open=false,
                             ),

                             dbc_button("Earthquakes",id="button-EQ"),
                             dbc_collapse(
                                dbc_card(dbc_cardbody([
                                   dbc_row([
                                       dbc_row(dbc_switch(label="Display", id="EQ-display", value=false),justify="center"),
                                       dbc_row(dbc_inputgroup([dbc_inputgrouptext("width"),     dbc_input(id="EQ-section_width", value=50, type="number")])),
                                       dbc_row(dbc_inputgroup([dbc_inputgrouptext("max Mw"),    dbc_input(id="EQ-minMag", value=0.1, type="number")])),
                                       dbc_row(dbc_inputgroup([dbc_inputgrouptext("min Mw"),    dbc_input(id="EQ-maxMag", value=8, type="number")])),
                                       dbc_row( dbc_card(dbc_checklist(id="selected_EQ-data",options=[]))),
                                    ])
                                    ])),
                                    id="collapse-EQ",
                                    is_open=false,
                                    ),
                            dbc_button("Surfaces",id="button-Surfaces"),
                            dbc_collapse(
                               dbc_card(dbc_cardbody([
                                  dbc_row([
                                      dbc_row(dbc_switch(label="Display", id="Surfaces-display", value=false),justify="center"),
                                      dbc_row( dbc_card(dbc_checklist(id="selected_Surface-data",options=[]))),
                                    ])
                                    ])),
                                    id="collapse-Surfaces",
                                    is_open=false,
                                    ),

                            dbc_button("Screenshots",id="button-Screenshots"),
                            dbc_collapse(
                                dbc_card(dbc_cardbody([
                                    dbc_col([dbc_switch(label="Display", id="screenshot-display", value=true),
                                             dcc_slider(min=0.0,max=1.0,marks=Dict(0=>"0",0.5=>"opacity",1=>"1"),value=1.0, id = "screenshot-opacity", tooltip=attr(placement="bottom")),    
                                            ]),
                                    ])),
                                    id="collapse-Screenshots",
                                    is_open=false,
                                    ),
                                   
                            dbc_button("Tomographic data",id="button-Tomography"),
                            dbc_collapse(
                                dbc_card(dbc_cardbody([
                                    dbc_col([
                                             dcc_slider(min=0.0,max=1.0,marks=Dict(0=>"0",0.5=>"opacity",1=>"1"),value=0.9, id = "tomography-opacity", tooltip=attr(placement="bottom")),    
                                             dcc_dropdown(id="colormaps_cross", options = [String.(keys(colormaps))...], value = "roma",clearable=false, placeholder="Colormap")
                                            ]),
                                    ])),
                                    id="collapse-Tomography",
                                    is_open=false,
                                    ),

                            dbc_button("Plot cross-section",id="button-plot-cross_section")
                                
                    ])

            
                ], align="center", width=2),
        
            ])
    ])
    
end
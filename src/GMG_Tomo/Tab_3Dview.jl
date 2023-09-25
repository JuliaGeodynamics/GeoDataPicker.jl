# Tab 2
function Tab_3Dview()
    dbc_col([
        dcc_graph(
            id = "3D-image",
            figure    = [], #plot_3D_data(DataTopo, DataTomo, AppData),
            animate = false,
            responsive=false,
            config = PlotConfig(displayModeBar=true, scrollZoom = true),
            style = attr(width="95vw", height="60vh",padding_left="1vw")
        ),
        dbc_row([dbc_col([dbc_button("Plot 3D",id="id-plot-3D"),
                          dbc_card([  dbc_checkbox(id="id-3D-topo",     label="topography",             value=true),
                                    dcc_slider(min=0.0,max=1.0,marks=Dict(0=>"0",0.5=>"opacity",1=>"1"),value=0.7, id = "opacity-topography-3D", tooltip=attr(placement="bottom")),    
                                ]),

                          dbc_card([ 
                            dbc_checkbox(id="id-3D-volume",   label="volumetric date",        value=false),
                            dcc_rangeslider(id = "id-3D-isosurface-slider", 
                                        min = 0., max = 3., value=[1, 3],
                                        allowCross=false,
                                    )
                                ]), 

                           dbc_col(dbc_card([dbc_label("curves:"),
                                    dcc_dropdown(id="3D-selected_curves",options=[("",)],multi=true),
                                ]))

                            ], width=3), 
                            
                            dbc_col([dbc_card([dbc_label("cross-sections:"),
                                            dbc_checklist(id="selected_cross-sections",options=[(label="",)]),
                                            dbc_col(dcc_slider(min=0.0,max=1.0,marks=Dict(0=>"0",0.5=>"opacity",1=>"1"),value=1.0, id = "opacity-cross-3D", tooltip=attr(placement="bottom")))
                                        ]),
                            dbc_col(dbc_card([dbc_label("Earthquakes:"),
                                        dcc_dropdown(id="3D-selected_EQ_data",options=[("",)],multi=true),
                                        dcc_rangeslider(id = "3D-EQ_magnitude-slider", 
                                                            min = 0.1, max = 9, value=[0.1, 9.0],
                                                            allowCross=false,
                                                        )
                                                        
                                        ])),
                            dbc_col(dbc_card([dbc_label("Surfaces:"),
                                        dcc_dropdown(id="3D-selected_surfaces_data",options=[("",)],multi=true),
                                        dbc_col(dcc_slider(min=0.0,max=1.0,marks=Dict(0=>"0",0.5=>"opacity",1=>"1"),value=1.0, id = "opacity-surfaces-3D", tooltip=attr(placement="bottom")))
                                        ]))

                                    ]
                                    , width=3),
                            #=
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
                            =#

                             dbc_col(dbc_card([dbc_label("create triangulated surface from curves:"),
                                    dcc_dropdown(id="3D-selected_curves_surf",options=[("",)],multi=true),
                                    dbc_label("profiles in the correct order:"),
                                    dcc_dropdown(id="3D-selected_profiles",options=[("",)],multi=true),
                                    dbc_row(dbc_col(dbc_button("Create surface", id="create-surface-curves"), width=6))
                                ]), width=3)

                ]),

              


    ])

end
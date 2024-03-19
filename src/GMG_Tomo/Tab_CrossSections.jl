
function tab_cross_section()
    dbc_row([
        dbc_col([
            dbc_row([dbc_button("Plot cross-section",id="button-plot-cross_section",color="danger"),
                     dbc_button("Curve Interpretation",id="button-curve-interpretation"),
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
                               dbc_row(dbc_inputgroup([dbc_inputgrouptext("width [km]"),     dbc_input(id="EQ-section_width", value=50, type="number")])),
                               dbc_row(dbc_inputgroup([dbc_inputgrouptext("min Magnitude"),    dbc_input(id="EQ-minMag", value=0.1, type="number")])),
                               dbc_row(dbc_inputgroup([dbc_inputgrouptext("max Magnitude"),    dbc_input(id="EQ-maxMag", value=8, type="number")])),
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
                           
                    dbc_button("Tomographic data I",id="button-Tomography"),
                    dbc_collapse(
                        dbc_card(dbc_cardbody([
                            dbc_col([
                                dbc_row(dbc_switch(label="Display", id="tomography-display", value=true),justify="center"),
                                dbc_row(dbc_switch(label="Contour", id="tomography-contour", value=false),justify="center"),
                                dcc_dropdown(id="dropdown_field",options = [],value = "DataTomo_dVp_paf21",clearable=false, placeholder="Select Dataset"),
                                dcc_rangeslider(id = "colorbar-slider",min = -5.,max = 5.,value=[-3, 3],allowCross=false),
                                dcc_slider(min=0.0,max=1.0,marks=Dict(0=>"0",0.5=>"opacity",1=>"1"),value=0.9, id = "tomography-opacity", tooltip=attr(placement="bottom")),    
                                dcc_dropdown(id="colormaps_cross", options = [String.(keys(colormaps))...], value = "roma",clearable=false, placeholder="Colormap")
                                ]),
                            ])),
                            id="collapse-Tomography",
                            is_open=false,
                            ),
                          
                    dbc_button("Tomographic data II",id="button-TomographyII"),
                    dbc_collapse(
                        dbc_card(dbc_cardbody([
                            dbc_col([
                                dbc_row(dbc_switch(label="Display", id="tomography-displayII", value=false),justify="center"),
                                dbc_row(dbc_switch(label="Contour", id="tomography-contourII", value=false),justify="center"),
                                dcc_dropdown(id="dropdown_fieldII",options = [],value = "DataTomo_dVp_paf21",clearable=false, placeholder="Select Dataset"),
                                dcc_rangeslider(id = "colorbar-sliderII",min = -5.,max = 5.,value=[-3, 3],allowCross=false),
                                dcc_slider(min=0.0,max=1.0,marks=Dict(0=>"0",0.5=>"opacity",1=>"1"),value=0.9, id = "tomography-opacityII", tooltip=attr(placement="bottom")),    
                                dcc_dropdown(id="colormaps_crossII", options = [String.(keys(colormaps))...], value = "roma",clearable=false, placeholder="Colormap")
                                ]),
                            ])),
                            id="collapse-TomographyII",
                            is_open=false,
                            ),
                            
                    dbc_button("Export/Import",id="button-export-import"),
                    dbc_collapse(
                            dbc_card(dbc_cardbody([
                            dbc_col([
                               dbc_card([dbc_row(dbc_label("Curves to be exported:"),justify="center"),
                               dcc_dropdown(id="curves-to-be-exported",options=[("",)],multi=true),
                               dbc_button("Export Curves",id="export-curves"),
                               dcc_download(id="download-curves", base64=true),
                                ])]),
                            dbc_card([  
                            dbc_button("Export Profiles",id="button-export-profiles"),
                            dcc_download(id="download-profiles", base64=true),
                            html_div(id="upload-profiles_component", dcc_upload(id="upload-profiles", children=dbc_button("Import Profiles"))),
                            html_div(id="upload-profiles_n"),  
                            ])

                           ])),
                           id="collapse-export-import",
                           is_open=false,
                           ),
                              
            ])

    
        ]   , align="center", width=2),

        # plot with cross-section
        dbc_col([cross_section_plot()], align="center", width=10),
    ])
    
end
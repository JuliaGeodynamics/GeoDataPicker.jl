# Tab 2
function Tab_Data()

    dbc_col([
        dbc_row([dbc_label("id=",id="label-id")]),

        dbc_row([   dbc_col(dbc_card([dbc_label("Tomograpy datasets", align="center", color="secondary", check=true),
                                        dbc_checklist(options=dataset_options(Datasets, "Volumetric")[1], 
                                                      value=dataset_options(Datasets, "Volumetric")[2],
                                                      id="data-tomo")
                                        ])),
                    dbc_col(dbc_card([dbc_label("EQ datasets", align="center", color="secondary", check=true),
                                        dbc_checklist(options=dataset_options(Datasets, "Point")[1], 
                                                        value=dataset_options(Datasets, "Point")[2],
                                                        id="data-EQ")
                                        ])),
                    dbc_col(dbc_card([dbc_label("Surfaces", align="center", color="secondary", check=true),
                                        dbc_checklist(options=dataset_options(Datasets, "Surface")[1], 
                                                        value=dataset_options(Datasets, "Surface")[2], 
                                                        id="data-surfaces")
                                        ])),
                    dbc_col(dbc_card([dbc_label("Screenshots", align="center", color="secondary", check=true),
                                        dbc_checklist(options=dataset_options(Datasets, "Screenshot")[1], 
                                                        value=dataset_options(Datasets, "Screenshot")[2],
                                        id="data-screenshots")
                                        ])),

                    dbc_col(dbc_card([dbc_label("Topography", align="center", color="secondary", check=true),
                                        dbc_checklist(options=dataset_options(Datasets, "Topography")[1], 
                                                        value=dataset_options(Datasets, "Topography")[2],
                                        id="data-topography")
                                        ])),
            ]),
        
            dbc_col(dbc_row(dbc_col([ dbc_col(dbc_button("Load Setup",id="setup-button", color="success"), width=3),
                                  dbc_col(dcc_loading(id="loading-1",type="default", children=html_div(id="loading-output-1"), color="green"), width=3),
                                  #dcc_upload(html_button("Upload File"), id="upload-state")
                                  ]), justify="end")),
            html_div(id="output-upload_state"),
        ])
        
    
end
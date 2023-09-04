# Tab 2
function Tab_3Dview()
    dbc_col([
        dcc_graph(
            id = "3D-image",
            figure    = [], #plot_3D_data(DataTopo, DataTomo, AppData),
            animate = false,
            responsive=false,
            config = PlotConfig(displayModeBar=true, scrollZoom = true)
        ),
        dbc_row([dbc_col([dbc_button("Plot 3D",id="id-plot-3D"),
                          dbc_checkbox(id="id-3D-topo",     label="topography",             value=true),
                          dbc_card([ 
                            dbc_checkbox(id="id-3D-volume",   label="volumetric date",        value=false),
                            dcc_rangeslider(id = "id-3D-isosurface-slider", 
                                        min = 0., max = 3., value=[1, 3],
                                        allowCross=false,
                                    )
                                ]), 
                            ], width=3), 
                            
                            dbc_col(dbc_card([dbc_label("cross-sections:"),
                                            dbc_checklist(id="selected_cross-sections",options=[(label="",)]),
                                            dbc_col([dbc_col(dbc_label("opacity:")),dbc_col(dcc_slider(id="opacity-cross-3D",min=0,max=1,value=1))])
                                    ]), width=3),

                            dbc_col(dbc_card([dbc_label("curves:"),
                                    dcc_dropdown(id="3D-selected_curves",options=[("",)],multi=true),
                            ]), width=3)


                ])

    ])

end
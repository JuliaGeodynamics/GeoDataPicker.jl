# Tab 2
function Tab2()
    dbc_col([
        dcc_graph(
            id = "3D-image",
            figure    = plot_3D_data(DataTopo::GeoData, DataTomo::GeoData, AppData),
            animate = false,
            responsive=false,
            config = PlotConfig(displayModeBar=true, scrollZoom = true)
        ),
        dbc_row([dbc_col([dbc_button("Plot 3D",id="id-plot-3D"),
                          dbc_checkbox(id="id-3D-topo",     label="topography",          value=true),
                          dbc_checkbox(id="id-3D-cross",    label="active cross-section",value=true),
                          dbc_checkbox(id="id-3D-cross-all",label="all cross-sections",value=false), 
                          dbc_checkbox(id="id-3D-volume",   label="volumetric date",value=false),
                          dcc_rangeslider(id = "id-3D-isosurface-slider", 
                                    min = 0., max = 3., value=[1, 3],
                                    allowCross=false,
                                ), 
                            ], width=4)
                ])

    ])

end
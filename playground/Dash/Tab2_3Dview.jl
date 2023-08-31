# Tab 2
function Tab2()
    dbc_col([
        dcc_graph(
            id = "3D images",
            figure    = plot_3D_data(DataTopo::GeoData, DataTomo::GeoData, AppData),
            animate   = true,
            clickData = true,
            config = PlotConfig(displayModeBar=true, scrollZoom = true)
        )

    ])
end
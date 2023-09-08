using Dash, PlotlyJS

app = dash()

function make_plot()
    plot(
        [
            bar(x=["giraffes", "orangutans", "monkeys"], y=rand(1:20, 3), name="SF"),
            bar(x=["giraffes", "orangutans", "monkeys"], y=rand(3:20, 3), name="Montreal")
        ],
        Layout(
            title="Dash Data Visualization",
            barmode="group",
        )
    )
end

app.layout = html_div() do
    html_h1("GMG Data Picker v0.1", style = Dict("margin-top" => 50, "textAlign" => "center")),
    dbc_tabs(
        [
            dbc_tab(
                label="Tab one",
                children=[dcc_graph(figure=make_plot())]
            ),
            dbc_tab(
                label="Tab two",
                children=[dcc_graph(figure=make_plot())]
            )
        ]
    )
end

run_server(app, "0.0.0.0", debug=false)


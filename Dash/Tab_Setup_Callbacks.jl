
callback!(app,  Output("label-id", "children"),
                Input("session-id", "data"),
                Input("setup-button", "n_clicks")
                ) do session_id, n

    @show session_id
    @show UUIDs.uuid4()
    return "id=$(session_id)"
end
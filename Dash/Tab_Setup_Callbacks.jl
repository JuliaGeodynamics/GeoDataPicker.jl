
# This creates an initial session id that is unique for this session
callback!(app,  Output("session-id", "data"),
                Output("label-id","children"),
                Input("session-id", "data")
                ) do session_id

    session_id = UUIDs.uuid4()
    str = "id=$(session_id)"
    return session_id.value, str
end
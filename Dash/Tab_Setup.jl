# Tab 2
function Tab_Data()

    dbc_col([
        dbc_row([dbc_label("id=",id="label-id")]),

        dbc_row([   dbc_col(dbc_card([dbc_label("Tomograpy datasets", align="center", color="secondary", check=true),
                                        dbc_checklist(options=["Paffrath"], id="data-tomo")
                                        ])),
                    dbc_col(dbc_card([dbc_label("EQ datasets", align="center", color="secondary", check=true),
                                        dbc_checklist(options=["test"], id="data-EQ")
                                        ])),
                    dbc_col(dbc_card([dbc_label("Surfaces", align="center", color="secondary", check=true),
                                        dbc_checklist(options=["test"], id="data-surfaces")
                                        ])),
                    dbc_col(dbc_card([dbc_label("Screenshots", align="center", color="secondary", check=true),
                                        dbc_checklist(options=["test"], id="data-screenshots")
                                        ])),
            ]),
        
        dbc_col(dbc_row([dbc_button("Load Setup",id="setup-button", color="success")], justify="right"), width=3),
        ])
        
    
end
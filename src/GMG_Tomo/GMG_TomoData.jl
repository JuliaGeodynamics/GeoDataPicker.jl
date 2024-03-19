# This is the main file with the GUI to interpret tomographic data
# Note that it calls other files with GUI components for each of the tabs.

# set the initial cross-section
start_val = (5.0,46.0)
end_val = (12.0,44.0) 

# read available colormaps
colormaps=read_colormaps()  # colormaps

# Create a global variable with the data structure. Note that we will 
global AppData
AppData = NamedTuple()

# Define the main layout
function main_layout(Datasets, max_num_users)
    dbc_container(className = "mxy-auto", fluid=true, [
        dbc_col(dbc_row([
                dbc_dropdownmenu(
                        [dcc_upload(dbc_dropdownmenuitem("Upload state",   disabled=false,  id="load-state", n_clicks=0), id="upload-state"), 
                         dbc_dropdownmenuitem("Download state", disabled=false, id="save-state", n_clicks=0),
                         dcc_download(id="download-state", base64=true),
                         #dbc_dropdownmenuitem(divider=true),
                        ],
                        label="File",
                        id="id-dropdown-file"),

                        dbc_col(html_img(src="assets/LogoPicker.png",height="100vh",)),
                        dbc_col(html_img(src="assets/GMG_Logo_new.png",height="100vh",),  width=2),
                       
                        ]),
                        ),

            dbc_tabs(
                [
                    dbc_tab(tab_id="tab-setup",label="Setup",             children = [tab_data(Datasets)]),
                    dbc_tab(tab_id="tab-map", label="Map",    children = [tab_map()]),
                    dbc_tab(tab_id="tab-cross", label="Cross-sections",    children = [tab_cross_section()]),
                    dbc_tab(tab_id="tab-3D", label="3D view",           children = [tab_3Dview()])
                ],
            id = "tabs", active_tab="tab-setup",

            ),
            html_div(id="output-upload_state_n"),     # fake (needed to have an output for uploading state)

        dcc_store(id="session-id", data =  "")     # gives a unique number of our session
    ])

end

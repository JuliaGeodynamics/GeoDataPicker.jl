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
function main_layout(Datasets)
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

                        html_h1("Data Picker", style = Dict("margin-top" => 0, "textAlign" => "center")),
                        html_h5("GeophysicalModelGenerator", style = Dict("margin-top" => 0, "textAlign" => "center")),
                        
                        ]),
                        ),

            dbc_tabs(
                [
                    dbc_tab(tab_id="tab-setup",label="Setup",             children = [Tab_Data(Datasets)]),
                    dbc_tab(tab_id="tab-cross", label="Cross-sections",    children = [Tab_CrossSection()]),
                    dbc_tab(tab_id="tab-3D", label="3D view",           children = [Tab_3Dview()])
                ],
            id = "tabs", active_tab="tab-setup",

            ),
            
        dcc_store(id="session-id", data =  "")     # gives a unique number of our session
    ])

end

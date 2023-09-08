# This is the main file with the GUI to interpret tomographic data
# Note that it calls other files with GUI components for each of the tabs.
using Dash  
using DashBootstrapComponents
using PlotlyJS, JSON3, Printf, Statistics
using UUIDs
using JLD2
using Base64

# The version of this GUI (to be saved in statefiles)
GUI_version = "0.1.2"

# include helper functions
include("./GMG_Tomo/GMG_colormaps.jl")
include("./GMG_Tomo/utils.jl")            
include("./GMG_Tomo/utils_curves.jl")
include("./GMG_Tomo/GMG_TomoData_Plots.jl")
include("./GMG_Tomo/Tab_CrossSections.jl")
include("./GMG_Tomo/Tab_3Dview.jl")
include("./GMG_Tomo/Tab_Setup.jl")

# Specify datasets (will later be read in from ascii file)
include("./GMG_Tomo/Default_datasets.jl")

# set the initial cross-section
start_val = (5.0,46.0)
end_val = (12.0,44.0) 


# read available colormaps
colormaps=read_colormaps()  # colormaps

# Create a global variable with the data structure. Note that we will 
global AppData
AppData = NamedTuple()

# Sets some defaults for the layout of webpage
app = dash(external_stylesheets = [dbc_themes.BOOTSTRAP], prevent_initial_callbacks=false)

app.title = "GMG Data Picker"
#data_fields = keys(DataTomo.fields)
#options_fields = [(label = String(f), value="$f" ) for f in data_fields]


# Create the layout of the main GUI. Note that the layout of the different tabs is specified in separate routines
#app.layout = dbc_container(className = "mxy-auto") do
    
function main_layout()
    dbc_container([
        dbc_col(dbc_row([
                dbc_dropdownmenu(
                        [dcc_upload(dbc_dropdownmenuitem("Upload state",   disabled=false,  id="load-state", n_clicks=0), id="upload-state"), 
                         dbc_dropdownmenuitem("Download state", disabled=false, id="save-state", n_clicks=0),
                         dcc_download(id="download-state", base64=true),
                         #dbc_dropdownmenuitem(divider=true),
                        ],
                        label="File",
                        id="id-dropdown-file"),

                        html_h1("GMG Data Picker v0.1", style = Dict("margin-top" => 50, "textAlign" => "center")),
                        
                        ]),
                        ),

            dbc_tabs(
                [
                    dbc_tab(tab_id="tab-setup",label="Setup",             children = [Tab_Data()]),
                    dbc_tab(tab_id="tab-cross", label="Cross-sections",    children = [Tab_CrossSection()]),
                    dbc_tab(tab_id="tab-3D", label="3D view",           children = [Tab_3Dview()])
                ],
            id = "tabs", active_tab="tab-setup",

            ),
            
        dcc_store(id="session-id", data =  "")     # gives a unique number of our session
    ])

end

app.layout = main_layout()
    

# Specify different callbacks for the different tabs:
include("./GMG_Tomo/Tab_Setup_Callbacks.jl")    
include("./GMG_Tomo/Tab_CrossSections_Callback.jl")    
include("./GMG_Tomo/Tab_3Dview_Callbacks.jl")    

run_server(app, debug=false)


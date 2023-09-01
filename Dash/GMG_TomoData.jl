# This is the main file with the GUI to interpret tomographic data
# Note that it calls other files with GUI components for each of the tabs.

using Dash  
using DashBootstrapComponents
using PlotlyJS, JSON3, Printf, Statistics

# include helper functions
include("utils.jl")  # tomographic dataset
include("GMG_TomoData_Plots.jl")
include("Tab_CrossSections.jl")
include("Tab_3Dview.jl")
include("Tab_Setup.jl")

# Load data
DataTomo, DataTopo = load_dataset();

# xtract data
data_fields =  keys(DataTomo.fields)

# set the initial cross-section
start_val = (5.0,46.0)
end_val = (12.0,44.0) 
cross = get_cross_section(DataTomo, start_val, end_val)

# Create a global variable with the data structure
# REMARK: we need to remove this!
global AppData
AppData = (DataTomo=DataTomo, DataTopo=DataTopo, cross=cross, move_cross=false, 
           CrossSections=[], active_crosssection=0);        # this will later hold the cross-section and plot data




# sets some defaults for webpage
app = dash(external_stylesheets = [dbc_themes.BOOTSTRAP], prevent_initial_callbacks=true)

app.title = "GMG Data Picker"
options_fields = [(label = String(f), value="$f" ) for f in data_fields]

# Create the layout of the main GUI. Note that the layout of the different tabs is specified in separate routines
app.layout = dbc_container(className = "mxy-auto") do
    dbc_col(dbc_row(
            dbc_dropdownmenu(
                    [dbc_dropdownmenuitem("Load", disabled=true),
                     dbc_dropdownmenuitem("Save", disabled=true),
                     dbc_dropdownmenuitem(divider=true),
                    ],
                    label="File",
                    id="id-dropdown-file")),
                    width=2),

        html_h1("GMG Data Picker v0.1", style = Dict("margin-top" => 50, "textAlign" => "center")),
        dbc_tabs(
            [
                dbc_tab(label="Setup",             children = [Tab_Data()]),
                dbc_tab(label="Cross-sections",    children = [Tab_CrossSection()]),
                dbc_tab(label="3D view",           children = [Tab_3Dview()])
            ]

    ),
        
    dcc_store(id="id-topo", data=DataTopo.lat)

end




# Specify different callbacks for the different tabs:
include("./Tab_CrossSections_Callback.jl")    
include("./Tab_3Dview_Callbacks.jl")    

run_server(app, debug=false)

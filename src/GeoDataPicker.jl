module GeoDataPicker

using Dash  
using DashBootstrapComponents
using PlotlyJS, JSON3, Printf, Statistics
using UUIDs
using JLD2
using Base64, HTTP
using Meshes, Interpolations, LinearAlgebra

export GMG_TomoData, AppData, max_num_users
using GeophysicalModelGenerator

# Load all files
include("GMG_Tomo/Default_datasets.jl")
include("GMG_Tomo/GMG_colormaps.jl")
include("GMG_Tomo/utils.jl")            
include("GMG_Tomo/utils_curves.jl")
include("GMG_Tomo/GMG_TomoData_Plots.jl")
include("GMG_Tomo/Tab_CrossSections.jl")
include("GMG_Tomo/Tab_3Dview.jl")
include("GMG_Tomo/Tab_Setup.jl")
include("GMG_Tomo/GMG_TomoData.jl")
include("GMG_Tomo/Tab_Setup_Callbacks.jl")
include("GMG_Tomo/Tab_CrossSections_Callback.jl")
include("GMG_Tomo/Tab_3Dview_Callbacks.jl")
include("CreateSurfaces.jl")

global AppData, max_num_users
max_num_users = 10
#AppData = NamedTuple()

# Ultimately, we plan to have different GUI's to create geodynamic models
# GMG_Tomo is to interpret tomographic data; other tools could focus on 
# creating geodynamic model setups from mapview drawings
"""
    GMG_TomoData(; Datasets = Default_datasets(dir = pkgdir(GeoDataPicker)),  host = HTTP.Sockets.localhost, port = 8050, max_num_user=10)

Starts a GUI to interpret tomographic data; you can change the default dataset file
""" 
function GMG_TomoData(; Datasets = Default_datasets(dir = pkgdir(GeoDataPicker)),  host = HTTP.Sockets.localhost, port = 8050, max_num_user=10)
    cd(joinpath(pkgdir(GeoDataPicker),"src"))
    GUI_version = "0.1.2"
    global max_num_users

    # Setup main app
    #app = dash(external_stylesheets=[dbc_themes.CYBORG])
    app = dash(external_stylesheets = [dbc_themes.BOOTSTRAP], prevent_initial_callbacks=false)

    app.title = "GMG Data Picker"
    app.layout = main_layout(Datasets, max_num_users)
        
    # Specify different callbacks for the different tabs:
    app = Tab_Setup_Callbacks(app, Datasets, GUI_version)
    app = Tab_CrossSections_Callback(app)
    app = Tab_3Dview_Callbacks(app)

    run_server(app, host, port, debug=false)
end


end # module DataPicker

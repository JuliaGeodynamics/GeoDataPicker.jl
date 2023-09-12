module GMG_DataPicker

using Dash  
using DashBootstrapComponents
using PlotlyJS, JSON3, Printf, Statistics
using UUIDs
using JLD2
using Base64

export GMG_TomoData, AppData
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


global AppData

# Ultimately, we plan to have different GUI's to create geodynamic models
# GMG_Tomo is to interpret tomographic data; other tools could focus on 
# creating geodynamic model setups from mapview drawings
"""
    GMG_TomoData(;datasets="Default_datasets.jl") 

Starts a GUI to interpret tomographic data; you can change the default dataset file
""" 
function GMG_TomoData(; Datasets = nothing)
    GUI_version = "0.1.2"

    # read input datasets
    Datasets=Default_datasets()

    # include helper functions
    colormaps=read_colormaps()  # colormaps

    # Setup main app
    #app = dash(external_stylesheets=[dbc_themes.CYBORG])
    app = dash(external_stylesheets = [dbc_themes.BOOTSTRAP], prevent_initial_callbacks=false)

    app.title = "GMG Data Picker"
    app.layout = main_layout(Datasets)
        
    # Specify different callbacks for the different tabs:
    app = Tab_Setup_Callbacks(app, Datasets, GUI_version)
    app = Tab_CrossSections_Callback(app)
    app = Tab_3Dview_Callbacks(app)

    run_server(app, debug=false)

end


end # module DataPicker

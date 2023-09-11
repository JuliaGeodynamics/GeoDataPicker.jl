module GMG_DataPicker

export GMG_TomoData, AppData

global AppData

# Ultimately, we plan to have different GUI's to create geodynamic models
# GMG_Tomo is to interpret tomographic data; other tools could focus on 
# creating geodynamic model setups from mapview drawings
"""
    GMG_TomoData(;datasets="Default_datasets.jl") 

Starts a GUI to interpret tomographic data; you can change the default dataset file
""" 
function GMG_TomoData(; default_datasets="src/GMG_Tomo/Default_datasets.jl")
    include(default_datasets)
    include("./src/GMG_Tomo/GMG_TomoData.jl")
end


end # module DataPicker

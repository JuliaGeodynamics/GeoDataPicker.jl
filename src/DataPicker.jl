module DataPicker

export GMG_TomoData
# Ultimately, we plan to have different GUI's to create geodynamic models
# GMG_Tomo is to interpret tomographic data; other tools could focus on 
# creating geodynamic model setups from mapview drawings 
function GMG_TomoData()
    include("./src/GMG_Tomo/GMG_TomoData.jl")
end


end # module DataPicker

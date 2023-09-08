module DataPicker

export GMG_TomoData
# Ultimately, we plan to have different GUI's to create geodynamic models
# GMG_Tomo is to interpret tomographic data; other tools could focus on 
# creating geodynamic model setups from mapview drawings 
function GMG_TomoData()
    include("./src/GMG_TomoData.jl")
end

#include("ReadSVG_geomIO.jl")
#include("DistanceToSurf.jl")

end # module DataPicker

# workflow for data picking
# WORKAROUND FOR NOW: USE THE PROVIDED MATLAB APP
using GeophysicalModelGenerator


# define the data sets that are to be used
ProfileCoordFile = "/Users/mthiel/PROJECTS/CURRENT/SPP2017/TomographyProcessing/TestSave.txt"
ProfileNumber    = 3;

DataSetName = [ "TomoPaffrath2021"
                "TomoPiromallo2003"
                "TomoMitterbauer"
                "MohoAD_Mrokzek2022"
                "MohoEU_Mrokzek2022"
                "MohoPA_Mrokzek2022"
                "ISC_Seismicity"
                ]

DataSetFile = [ "/Users/mthiel/PROJECTS/CURRENT/SPP2017/TomographyProcessing/Paffrath2021/Paffrath2021.jld2"
                "/Users/mthiel/PROJECTS/CURRENT/SPP2017/TomographyProcessing/Piromallo2003/Piromallo2003.jld2"
                "/Users/mthiel/PROJECTS/CURRENT/SPP2017/TomographyProcessing/Mitterbauer2011/Mitterbauer2011.jld2"
                "/Users/mthiel/PROJECTS/CURRENT/SPP2017/TomographyProcessing//Moho_models/Mrozek2022/Mrozek_Moho_Grid_EU.jld2"
                "/Users/mthiel/PROJECTS/CURRENT/SPP2017/TomographyProcessing//Moho_models/Mrozek2022/Mrozek_Moho_Grid_AD.jld2"
                "/Users/mthiel/PROJECTS/CURRENT/SPP2017/TomographyProcessing//Moho_models/Mrozek2022/Mrozek_Moho_Grid_PA.jld2"
                "/Users/mthiel/PROJECTS/CURRENT/SPP2017/TomographyProcessing/ISC/isc_seis_alps.jld2"
                ]


DataSetType = [ "Vol"
                "Vol"
                "Vol"
                "Surf"
                "Surf"
                "Surf"
                "Point"
                ]

DimsVolCross        = (200,200)
DimsSurfCross       = (100,)
WidthPointProfile   = 10km


# 2. process the profiles
include("ProfileProcessing.jl")
ExtractedData = ExtractProfileData(ProfileCoordFile,ProfileNumber,DataSetName,DataSetFile,DataSetType,DimsVolCross,DimsSurfCross,WidthPointProfile)


# 3. interpret using a Makie app (or any other one)

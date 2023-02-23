# workflow for data picking
# WORKAROUND FOR NOW: USE THE PROVIDED MATLAB APP

# define the data sets that are to be used
ProfileCoordFile = "./PickTest/PickedProfiles.txt"
ProfileNumber    = 1;

DataSetName = [ "TomoPaffrath2021"
                "TomoPiromallo2003"
                "MohoAD_Mrokzek2022"
                "MohoEU_Mrokzek2022"
                "ISC_Seismicity"
                ]

DataSetFile = [ "./Paffrath2021/Paffrath2021.jld2"
                "./Piromallo2003/Piromallo2003.jld2"
                ".//Moho_models/Mrozek2022/Mrozek_Moho_Grid_EU.jld2"
                ".//Moho_models/Mrozek2022/Mrozek_Moho_Grid_AD.jld2"
                "./ISC/isc_seis_alps.jld2"
                ]


DataSetType = [ "Vol"
                "Vol"
                "Surf"
                "Surf"
                "Point"
                ]

DimsVolCross        = (100,100)
DimsSurfCross       = (100,)
WidthPointProfile   = 10km


# 2. process the profiles
include("ProfileProcessing.jl")
ExtractedData = ExtractProfileData(ProfileCoordFile,ProfileNumber,DataSetName,DataSetFile,DataSetType,DimsVolCross,DimsSurfCross,WidthPointProfile)


# 3. interpret using a Makie app (or any other one)

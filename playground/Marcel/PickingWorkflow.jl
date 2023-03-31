# workflow for data picking
# WORKAROUND FOR NOW: USE THE PROVIDED MATLAB APP
using GeophysicalModelGenerator
using MATLAB


# define the data sets that are to be used
ProfileCoordFile = "./ProfilesAlps.txt"
ProfileNumber    = 15;

DataSetName = [ "TomoPaffrath2021"
                "TomoPiromallo2003"
                "TomoMitterbauer2011"
                "TomoLippitsch2003"
                "TomoHua2017"
                "TomoZhao2016"
                "TomoZhu2015"
                "MohoAD_Mrokzek2022"
                "MohoEU_Mrokzek2022"
                "MohoPA_Mrokzek2022"
                "MohoAD_Spada2013"
                "MohoEU_Spada2013"
                "MohoTY_Spada2013"
                "ISC_Seismicity"
                "AlpArraySeismicity"
                ]

DataSetFile = [ "/Users/mthiel/PROJECTS/CURRENT/SPP2017/TomographyProcessing/DataDubrovnik/Paffrath2021.jld2"
                "/Users/mthiel/PROJECTS/CURRENT/SPP2017/TomographyProcessing/DataDubrovnik/Piromallo2003.jld2"
                "/Users/mthiel/PROJECTS/CURRENT/SPP2017/TomographyProcessing/DataDubrovnik/Mitterbauer2011.jld2"
                "/Users/mthiel/PROJECTS/CURRENT/SPP2017/TomographyProcessing/DataDubrovnik/Lippitsch2003.jld2"
                "/Users/mthiel/PROJECTS/CURRENT/SPP2017/TomographyProcessing/DataDubrovnik/Hua2017.jld2"
                "/Users/mthiel/PROJECTS/CURRENT/SPP2017/TomographyProcessing/DataDubrovnik/Zhao_Pwave.jld2"
                "/Users/mthiel/PROJECTS/CURRENT/SPP2017/TomographyProcessing/DataDubrovnik/Zhu2015.jld2"
                "/Users/mthiel/PROJECTS/CURRENT/SPP2017/TomographyProcessing/DataDubrovnik/Mrozek_Moho_Grid_EU.jld2"
                "/Users/mthiel/PROJECTS/CURRENT/SPP2017/TomographyProcessing/DataDubrovnik/Mrozek_Moho_Grid_AD.jld2"
                "/Users/mthiel/PROJECTS/CURRENT/SPP2017/TomographyProcessing/DataDubrovnik/Mrozek_Moho_Grid_PA.jld2"
                "/Users/mthiel/PROJECTS/CURRENT/SPP2017/TomographyProcessing/DataDubrovnik/Spada_Moho_Adria_Grid.jld2"
                "/Users/mthiel/PROJECTS/CURRENT/SPP2017/TomographyProcessing/DataDubrovnik/Spada_Moho_Europe_Grid.jld2"
                "/Users/mthiel/PROJECTS/CURRENT/SPP2017/TomographyProcessing/DataDubrovnik/Spada_Moho_Tyrrhenia_Grid.jld2"
                "/Users/mthiel/PROJECTS/CURRENT/SPP2017/TomographyProcessing/DataDubrovnik/isc_seis_alps.jld2"
                "/Users/mthiel/PROJECTS/CURRENT/SPP2017/TomographyProcessing/DataDubrovnik/AlpArraySeis.jld2"
                ]


DataSetType = [ "Vol"
                "Vol"
                "Vol"
                "Vol"
                "Vol"
                "Vol"
                "Vol"
                "Surf"
                "Surf"
                "Surf"
                "Surf"
                "Surf"
                "Surf"
                "Point"
                "Point"
                ]

DimsVolCross        = (500,600)
DimsSurfCross       = (100,)
WidthPointProfile   = 20km


# 2. process the profiles
include("ProfileProcessing.jl")
ExtractedData = ExtractProfileData(ProfileCoordFile,ProfileNumber,DataSetName,DataSetFile,DataSetType,DimsVolCross,DimsSurfCross,WidthPointProfile)

# 3. save data as MATLAB
fn = "Profile"*string(ProfileNumber)
write_matfile(fn*".mat"; ProfileData=ExtractedData,)

# Specify the default datasets to be displayed in the GUI.
# Data can be store locally or online
# true @ the end implies that we activate the checkbox in the GUI

"""
    Datasets:: Vector{GMG_Dataset} =  Default_datasets()
    
Set of datasets to start the GUI
"""
function Default_datasets(;dir="")

    Datasets = Vector{GMG_Dataset}()

    # Volumetric (tomographic) data
    push!(Datasets, GMG_Dataset("DataTomo","Volume",joinpath(dir,"src/AlpsModels.jld2"), true))
    push!(Datasets, GMG_Dataset("Paffrath2021_Vp","Volume","https://seafile.rlp.net/f/5c8c851af6764b5db20d/?dl=1", false))
    push!(Datasets, GMG_Dataset("Hua2017_Vp","Volume","https://seafile.rlp.net/f/1fb68b74e5d742d39e62/?dl=1", false))
    push!(Datasets, GMG_Dataset("Koulakov2015_Vp","Volume","https://seafile.rlp.net/f/997e7efeb4c54fb693eb/?dl=1", false)) 
    push!(Datasets, GMG_Dataset("Lippitsch2003_Vp","Volume","https://seafile.rlp.net/f/30232fd6aceb452485c3/?dl=1", false))
    push!(Datasets, GMG_Dataset("Mitterbauer2011_Vp","Volume","https://seafile.rlp.net/f/ab41397ff00c4fcf858e/?dl=1", false))
    push!(Datasets, GMG_Dataset("Najafabadi2022_Vp","Volume","https://seafile.rlp.net/f/4483d252ee75486a80dc/?dl=1", false))
    push!(Datasets, GMG_Dataset("Piromallo2003_Vp","Volume","https://seafile.rlp.net/f/f3957e30ea4048ef94d7/?dl=1", false))
    push!(Datasets, GMG_Dataset("Plomerova2022_Vp","Volume","https://seafile.rlp.net/f/abccb8d3302b4ef5af17/?dl=1", false))
    push!(Datasets, GMG_Dataset("Zhao2016_Vp","Volume","https://seafile.rlp.net/f/e81a6d075f6746609973/?dl=1", false))
    push!(Datasets, GMG_Dataset("Zhu2015_Vp","Volume","https://seafile.rlp.net/f/f062c4b3a235415cbaf0/?dl=1", false))
    push!(Datasets, GMG_Dataset("NEWTON21_anisotropic_Vp","Volume","https://seafile.rlp.net/f/7862a29a1f44405bbebd/?dl=1", false))
    push!(Datasets, GMG_Dataset("Menichelli2023_Vp","Volume","https://seafile.rlp.net/f/84a5b5e5eec04c2b98e3/?dl=1", false))

    push!(Datasets, GMG_Dataset("GyPSuMS_Global_Vp","Volume","https://seafile.rlp.net/f/10721a3c4fbe4a81bcae/?dl=1", false))
    push!(Datasets, GMG_Dataset("Rappisi2022_iso_Vp","Volume","https://seafile.rlp.net/f/e787e08216384d2683f4/?dl=1", false))
    push!(Datasets, GMG_Dataset("Rappisi2022_slabs_Vp","Volume","https://seafile.rlp.net/f/607765fcd47c46ce8ed5/?dl=1", false))
    push!(Datasets, GMG_Dataset("Rappisi2022_Vp","Volume","https://seafile.rlp.net/f/5b89d5e1289f492b8a28/?dl=1", false))
    push!(Datasets, GMG_Dataset("Lippitsch2003_2_Vp","Volume","https://seafile.rlp.net/f/266fb30910c048119f4f/?dl=1", false))
    push!(Datasets, GMG_Dataset("MIT08_Pwave","Volume","https://seafile.rlp.net/f/bda0cb39537641e9a1e5/?dl=1", false))
    push!(Datasets, GMG_Dataset("Koulakov_Europe_Vp","Volume","https://seafile.rlp.net/f/e8f9e8c6506a4304bc1d/?dl=1", false))
    push!(Datasets, GMG_Dataset("HMSL-P06_percent_Vp","Volume","https://seafile.rlp.net/f/fdd495e109b34d14a768/?dl=1", false))
    push!(Datasets, GMG_Dataset("Giacomuzzi_2023_Vp","Volume","https://seafile.rlp.net/f/ca8eb5385bd24fc8ad5c/?dl=1", false))
    push!(Datasets, GMG_Dataset("Diehl2009_Vp","Volume","https://seafile.rlp.net/f/b9f1ed56565f4d02ab09/?dl=1", false))
    push!(Datasets, GMG_Dataset("Amaru2007_Vp","Volume","https://seafile.rlp.net/f/70052f317315479bb4ce/?dl=1", false))
    

    # Vs:
    push!(Datasets, GMG_Dataset("CSEM_Vs","Volume","https://seafile.rlp.net/f/4bde77eb63fe4740b5de/?dl=1", false))
    push!(Datasets, GMG_Dataset("ElSharkawy_Vs","Volume","https://seafile.rlp.net/f/c7eb8d7a24d648b6af3f/?dl=1", false))
    push!(Datasets, GMG_Dataset("Kaestle2018_Vs","Volume","https://seafile.rlp.net/f/36145dfa7dce4d9b8eeb/?dl=1", false))
    push!(Datasets, GMG_Dataset("Koulakov2009_Vs","Volume","https://seafile.rlp.net/f/980e7fc6b9134434bb6a/?dl=1", false))
    push!(Datasets, GMG_Dataset("Kind_ReceiverFunctions","Volume","https://seafile.rlp.net/f/2c34b58b03bc4259aecb/?dl=1", false))
    
    push!(Datasets, GMG_Dataset("CaPaREA2023_Crust_Timko_Vs","Volume","https://seafile.rlp.net/f/89d1f97f1c574701b0ac/?dl=1", false))
    push!(Datasets, GMG_Dataset("CaPaREA2023_Mantle_Timko_Vs","Volume","https://seafile.rlp.net/f/a0bc30b88446437199ed/?dl=1", false))
    push!(Datasets, GMG_Dataset("CaPaREA2023_abs_Timko_Vs","Volume","https://seafile.rlp.net/f/fab7ce65d89d4826bfa3/?dl=1", false))
    push!(Datasets, GMG_Dataset("REVEAL_rel_avg_AK135_Vs","Volume","https://seafile.rlp.net/f/52ff0b02f689412c973d/?dl=1", false))
    push!(Datasets, GMG_Dataset("GyPSuMS_Global_Vs","Volume","https://seafile.rlp.net/f/db7dbdf8131a4253957a/?dl=1", false))
    push!(Datasets, GMG_Dataset("CAM2022_Vs","Volume","https://seafile.rlp.net/f/3ba88f5359af47bca42a/?dl=1", false))
    push!(Datasets, GMG_Dataset("CSEM_Europe_Vs","Volume","https://seafile.rlp.net/f/6e05832d0b454fb4941d/?dl=1", false))
    #push!(Datasets, GMG_Dataset("CSEM_Europe_Vs","Volume","https://seafile.rlp.net/f/fdc6204b200d42689395/?dl=1", false))
    push!(Datasets, GMG_Dataset("LSP_Eucrust1_0_Vs","Volume","https://seafile.rlp.net/f/f8a7abd3e54f470895d4/?dl=1", false))
    push!(Datasets, GMG_Dataset("Fichtner_CSEM_Vs","Volume","https://seafile.rlp.net/f/0016408107f14046aebe/?dl=1", false))
    push!(Datasets, GMG_Dataset("3DLGL-TPESv_Global_Vs","Volume","https://seafile.rlp.net/f/8bb33587aaa840c98d2a/?dl=1", false))
    push!(Datasets, GMG_Dataset("SAVANI_US_Global_Vs","Volume","https://seafile.rlp.net/f/2e503d2a917e439cb141/?dl=1", false))
    push!(Datasets, GMG_Dataset("SAVANI_Medit_Vs","Volume","https://seafile.rlp.net/f/fb08038c8f524231a389/?dl=1", false))
    

    # Topography
    push!(Datasets, GMG_Dataset("AlpsTopo","Topography",joinpath(dir,"src/AlpsTopo.jld2"), true))
    push!(Datasets, GMG_Dataset("topography","Topography","https://seafile.rlp.net/f/3edb4a0531c14dc687ef/?dl=1", false))

    # Screenshots
    push!(Datasets, GMG_Dataset("Handy_etal_SE_ProfileA","Screenshot","https://seafile.rlp.net/f/516015cb6d6442bdb96c/?dl=1", false))
    push!(Datasets, GMG_Dataset("Handy_etal_SE_ProfileB","Screenshot","https://seafile.rlp.net/f/ec5508f57ed7488ebe17/?dl=1", false))
    push!(Datasets, GMG_Dataset("Handy_etal_SE_ProfileC","Screenshot","https://seafile.rlp.net/f/a2aeb47b8cd24caebcbe/?dl=1", false))
    push!(Datasets, GMG_Dataset("Handy_etal_SE_Profile1","Screenshot","https://seafile.rlp.net/f/5ffe580e765e4bd1bafe/?dl=1", false))
    push!(Datasets, GMG_Dataset("Handy_etal_SE_Profile2","Screenshot","https://seafile.rlp.net/f/c0c1746f307f4f81ace4/?dl=1", false))
    push!(Datasets, GMG_Dataset("Handy_etal_SE_Profile3","Screenshot","https://seafile.rlp.net/f/d5fa21f1586c4e99a7e8/?dl=1", false))
    push!(Datasets, GMG_Dataset("Handy_etal_SE_Profile4","Screenshot","https://seafile.rlp.net/f/3c106428b55b4a1ba278/?dl=1", false))
    push!(Datasets, GMG_Dataset("Handy_etal_SE_Profile5","Screenshot","https://seafile.rlp.net/f/aa359b5fd2f74aca9824/?dl=1", false))
    push!(Datasets, GMG_Dataset("Handy_etal_SE_Profile7","Screenshot","https://seafile.rlp.net/f/9fc382311b4b46eba339/?dl=1", false))
    push!(Datasets, GMG_Dataset("Handy_etal_SE_Profile8","Screenshot","https://seafile.rlp.net/f/c5e0cbc23f3f4726acef/?dl=1", false))
    push!(Datasets, GMG_Dataset("Handy_etal_SE_Profile9","Screenshot","https://seafile.rlp.net/f/7b13f68f166243e29751/?dl=1", false))
    push!(Datasets, GMG_Dataset("Handy_etal_SE_Profile10","Screenshot","https://seafile.rlp.net/f/c06bdf88f5524710b991/?dl=1", false))
    push!(Datasets, GMG_Dataset("Handy_etal_SE_Profile11","Screenshot","https://seafile.rlp.net/f/903a334981624193b42b/?dl=1", false))
    push!(Datasets, GMG_Dataset("Handy_etal_SE_Profile12","Screenshot","https://seafile.rlp.net/f/912565f798cc4b49a36b/?dl=1", false))
    push!(Datasets, GMG_Dataset("Handy_etal_SE_Profile13","Screenshot","https://seafile.rlp.net/f/25feccd84b7442ebae23/?dl=1", false))
    push!(Datasets, GMG_Dataset("Handy_etal_SE_Profile14","Screenshot","https://seafile.rlp.net/f/b8116c78d133491fa8cd/?dl=1", false))
    push!(Datasets, GMG_Dataset("Handy_etal_SE_Profile15","Screenshot","https://seafile.rlp.net/f/dea33499de3e4d459615/?dl=1", false))
    push!(Datasets, GMG_Dataset("Handy_etal_SE_Profile16","Screenshot","https://seafile.rlp.net/f/7d7f1c2d774e479a9f56/?dl=1", false))
    push!(Datasets, GMG_Dataset("Handy_etal_SE_Profile17","Screenshot","https://seafile.rlp.net/f/9ece95e1099c48af9b96/?dl=1", false))
    push!(Datasets, GMG_Dataset("Handy_etal_SE_Profile18","Screenshot","https://seafile.rlp.net/f/b43e940fd0034dcd8bef/?dl=1", false))

    # Moho surfaces
    push!(Datasets, GMG_Dataset("Mroczek2022_Moho_Grid_AD","Surface","https://seafile.rlp.net/f/12c120c5724745e2b27b/?dl=1", false))
    push!(Datasets, GMG_Dataset("Mroczek2022_Moho_Grid_EU","Surface","https://seafile.rlp.net/f/483d9c7c808a4087ba9e/?dl=1", false))
    push!(Datasets, GMG_Dataset("Mroczek2022_Moho_Grid_PA","Surface","https://seafile.rlp.net/f/217eaf5c87d14adcb9c9/?dl=1", false))
    push!(Datasets, GMG_Dataset("EUCrust_07_old","Surface","https://seafile.rlp.net/f/10f867e410bb4d95b3fe/?dl=1",               false))
    push!(Datasets, GMG_Dataset("Spada2013_Moho_Adria","Surface","https://seafile.rlp.net/f/f4fd12f8bcf2460099d4/?dl=1",     false))
    push!(Datasets, GMG_Dataset("Spada2013_Moho_Europe","Surface","https://seafile.rlp.net/f/10c06397c23a4611bf5e/?dl=1",    false))
    push!(Datasets, GMG_Dataset("Spada2013_Moho_Tyrrhenia","Surface","https://seafile.rlp.net/f/f3833ae6d0474b34b88c/?dl=1", false))
    
    push!(Datasets, GMG_Dataset("EUCrust_07",  "Surface","https://seafile.rlp.net/f/a0cd969dab184f34ac07/?dl=1",               false))
    push!(Datasets, GMG_Dataset("MohoEUCrust", "Surface","https://seafile.rlp.net/f/61c3bce2b0f949fdb7bc/?dl=1",              false))
    push!(Datasets, GMG_Dataset("EUCrust_08",  "Surface","https://seafile.rlp.net/f/45d5fd297eba4e9d9849/?dl=1",              false))
    push!(Datasets, GMG_Dataset("Grad09_EU",  "Surface","https://seafile.rlp.net/f/d42b694387f0458b840e/?dl=1",              false))
    push!(Datasets, GMG_Dataset("Grad07_EU",  "Surface","https://seafile.rlp.net/f/8ca2a3b40b2a41a5858d/?dl=1",              false))
    
    # Other surfaces
    push!(Datasets, GMG_Dataset("Spooner2020_Consolidated_Sediments","Surface", "https://seafile.rlp.net/f/26253974062243e0b115/?dl=1", false))
    push!(Datasets, GMG_Dataset("Spooner2020_UpperCrust","Surface", "https://seafile.rlp.net/f/17b497c66dde47289abf/?dl=1", false))
    push!(Datasets, GMG_Dataset("Spooner2020_LowerCrust","Surface", "https://seafile.rlp.net/f/d6b45186de94418b8ec3/?dl=1", false))
    push!(Datasets, GMG_Dataset("Spooner2020_LithosphericMantle","Surface", "https://seafile.rlp.net/f/ec96eceba19a41e8bd56/?dl=1", false))
    push!(Datasets, GMG_Dataset("Spooner2020_LithosphericMantle_bottom","Surface",     "https://seafile.rlp.net/f/28f63341d9ca4afeb62c/?dl=1", false))

    # Seismicity
    push!(Datasets, GMG_Dataset("AlpArraySeis","Point","https://seafile.rlp.net/f/87d565882eda40689666/?dl=1", false))
    push!(Datasets, GMG_Dataset("ISC","Point","https://seafile.rlp.net/f/fed98ad058df4f2c8d28/?dl=1", false))
    push!(Datasets, GMG_Dataset("CLASS","Point","https://seafile.rlp.net/f/4c574d9610b34b34ad9a/?dl=1", false))
    push!(Datasets, GMG_Dataset("isc24_MedS","Point","https://seafile.rlp.net/f/d800de0823b142a099b5/?dl=1", false))
    push!(Datasets, GMG_Dataset("Najafabadi2021","Point","https://seafile.rlp.net/f/a57aeed44d23443f9bf3/?dl=1", false))


    return Datasets

end



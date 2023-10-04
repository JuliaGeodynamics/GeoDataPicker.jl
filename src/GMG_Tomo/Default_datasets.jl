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

    push!(Datasets, GMG_Dataset("CSEM_Vs","Volume","https://seafile.rlp.net/f/4bde77eb63fe4740b5de/?dl=1", false))
    push!(Datasets, GMG_Dataset("ElSharkawy_Vs","Volume","https://seafile.rlp.net/f/c7eb8d7a24d648b6af3f/?dl=1", false))
    push!(Datasets, GMG_Dataset("Kaestle2018_Vs","Volume","https://seafile.rlp.net/f/36145dfa7dce4d9b8eeb/?dl=1", false))
    push!(Datasets, GMG_Dataset("Koulakov2009_Vs","Volume","https://seafile.rlp.net/f/980e7fc6b9134434bb6a/?dl=1", false))
    push!(Datasets, GMG_Dataset("Kind_ReceiverFunctions","Volume","https://seafile.rlp.net/f/2c34b58b03bc4259aecb/?dl=1", false))

    

    # Topography
    push!(Datasets, GMG_Dataset("AlpsTopo","Topography",joinpath(dir,"src/AlpsTopo.jld2"), true))

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
    push!(Datasets, GMG_Dataset("EUCrust_07","Surface","https://seafile.rlp.net/f/10f867e410bb4d95b3fe/?dl=1",               false))
    push!(Datasets, GMG_Dataset("Spada2013_Moho_Adria","Surface","https://seafile.rlp.net/f/f4fd12f8bcf2460099d4/?dl=1",     false))
    push!(Datasets, GMG_Dataset("Spada2013_Moho_Europe","Surface","https://seafile.rlp.net/f/10c06397c23a4611bf5e/?dl=1",    false))
    push!(Datasets, GMG_Dataset("Spada2013_Moho_Tyrrhenia","Surface","https://seafile.rlp.net/f/f3833ae6d0474b34b88c/?dl=1", false))

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
   

    return Datasets

end



# Specify the default datasets to be displayed in the GUI.
# Data can be store locally or online
# true @ the end implies that we activate the checkbox in the GUI

Datasets = Vector{GMG_Dataset}()

# Volumetric (tomographic) data
push!(Datasets, GMG_Dataset("DataTomo","Volumetric","AlpsModels.jld2", true))

# Topography
push!(Datasets, GMG_Dataset("AlpsTopo","Topography","AlpsTopo.jld2", true))

# Screenshots
push!(Datasets, GMG_Dataset("Handy_etal_SE_ProfileA","Screenshot","Handy_etal_SE_ProfileA.jld2", false))
push!(Datasets, GMG_Dataset("Handy_etal_SE_Profile1","Screenshot","https://seafile.rlp.net/f/5ffe580e765e4bd1bafe/?dl=1", false))
push!(Datasets, GMG_Dataset("Handy_etal_SE_Profile2","Screenshot","https://seafile.rlp.net/f/c0c1746f307f4f81ace4/?dl=1", false))
push!(Datasets, GMG_Dataset("Handy_etal_SE_Profile3","Screenshot","https://seafile.rlp.net/f/d5fa21f1586c4e99a7e8/?dl=1", false))

# Moho surfaces
push!(Datasets, GMG_Dataset("Mrozek_Moho_Grid_AD","Surface","https://seafile.rlp.net/f/12c120c5724745e2b27b/?dl=1", false))
push!(Datasets, GMG_Dataset("Mrozek_Moho_Grid_EU","Surface","https://seafile.rlp.net/f/483d9c7c808a4087ba9e/?dl=1", false))
push!(Datasets, GMG_Dataset("Mrozek_Moho_Grid_PA","Surface","https://seafile.rlp.net/f/217eaf5c87d14adcb9c9/?dl=1", false))

# Seismicity
push!(Datasets, GMG_Dataset("AlpArraySeis","Point","https://seafile.rlp.net/f/87d565882eda40689666/?dl=1", false))

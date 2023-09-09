# Specify the default datasets to be displayed in the GUI.
# Data can be store locally or online
# true @ the end implies that we activate the checkbox in the GUI

Datasets = Vector{GMG_Dataset}()

# Volumetric (tomographic) data
push!(Datasets, GMG_Dataset("DataTomo","Volume","src/AlpsModels.jld2", true))

# Topography
push!(Datasets, GMG_Dataset("AlpsTopo","Topography","src/AlpsTopo.jld2", true))

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
push!(Datasets, GMG_Dataset("Mrozek_Moho_Grid_AD","Surface","https://seafile.rlp.net/f/12c120c5724745e2b27b/?dl=1", false))
push!(Datasets, GMG_Dataset("Mrozek_Moho_Grid_EU","Surface","https://seafile.rlp.net/f/483d9c7c808a4087ba9e/?dl=1", false))
push!(Datasets, GMG_Dataset("Mrozek_Moho_Grid_PA","Surface","https://seafile.rlp.net/f/217eaf5c87d14adcb9c9/?dl=1", false))

# Seismicity
push!(Datasets, GMG_Dataset("AlpArraySeis","Point","https://seafile.rlp.net/f/87d565882eda40689666/?dl=1", false))

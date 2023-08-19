# various helper routines 
using GeophysicalModelGenerator, GMT, JLD2


"""
    DataTomo, DataTopo =  load_dataset(fname::String="AlpsModels.jld2"; grid_name="@earth_relief_02m.grd")

This loads a 3D tomographic dataset from the file `fname` (prepared with the GeophysicalModelGenerator and saves as `*.jld2` format).
It also uses GMT to download the corresponding topographic map for the region

"""
function load_dataset(fname::String="AlpsModels.jld2"; grid_name="@earth_relief_02m.grd")
    DataTomo = load_object(fname)
    lon = extrema(DataTomo.lon.val)
    lat = extrema(DataTomo.lat.val)
    
    DataTopo = ImportTopo(lat=[lat...], lon=[lon...],file=grid_name)
    return DataTomo, DataTopo
end

"""
Extracts a cross-section from a tomographic dataset
"""
function get_cross_section(DataAlps; lon=0)

    cross=CrossSection(DataAlps, Lon_level=lon)

    return cross
end


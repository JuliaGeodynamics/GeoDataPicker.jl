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
    x,z,data = get_cross_section(DataAlps, start_value=(10,41), end_value=(10,49), field=:dVp_paf21)

Extracts a cross-section from a tomographic dataset and returns this as cartesian values (x,z) formatted for the Plotly heatmap format
"""
function get_cross_section(DataAlps::GeoData, start_value=(10,41), end_value=(10,49), field=:dVp_paf21)

    # retrieve the cross-section in GeoData format
    cross   =   CrossSection(DataAlps, Start=start_value, End=end_value)

    # transfer it to cartesian data
    p           = ProjectionPoint(Lon=minimum(cross.lon.val),Lat=minimum(cross.lat.val));
    cross_cart  = Convert2CartData(cross,p)
    x_cross     = FlattenCrossSection(cross_cart);
    x           = x_cross[:,1];
    z           = cross_cart.z.val[1,:,1]

    if !hasfield(typeof(cross.fields), field)
        error("The dataset does not have field $field")
    end

    data        = cross_cart.fields[field][:,:,1]

    # now transfer 

    return (x=x,z=z,data=data)
end


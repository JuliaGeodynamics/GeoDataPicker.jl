# various helper routines 
using GeophysicalModelGenerator, GMT, JLD2


"""
structure that holds info about the project
"""
mutable struct Profile
    ProfileData::GeoData        # the geodata with profile info
    
    start_lonlat::NTuple        # start of profile in lon/lat
    end_lonlat::NTuple          # start of profile in lon/lat

    start_cart::Number          # start of profile in cartesian coords
    end_cart::Number            # start of profile in cartesian coords

    z_cart::Vector              # 1D vector with z-coordinates (or y, in case of horizontal profile)
    x_cart::Vector              # 1D vector with x-coordinates (along profile)
    
    x_lon::Vector               # 1D vector with lon values
    x_lat::Vector               # 1D vector with lat values

    data::Matrix                # the current data displayed
    
    Polygons::Vector            # Interpreted polygons along the profile         
    
    # Intersection points       # Vector with intersection points of other profiles with the current one (to be added
end

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
    cross   =   CrossSection(DataAlps, Start=start_value, End=end_value, Interpolate=true)

    # transfer it to cartesian data
    p           = ProjectionPoint(Lon=minimum(cross.lon.val),Lat=minimum(cross.lat.val));
    cross_cart  = Convert2CartData(cross,p)
    x_cross     = FlattenCrossSection(cross_cart);
    x_cart      = x_cross[:,1];
    z_cart      = cross_cart.z.val[1,:,1]

    x_lon       = cross.lon.val[:,1];
    x_lat       = cross.lat.val[1,:];
    

    if !hasfield(typeof(cross.fields), field)
        error("The dataset does not have field $field")
    end

    data        = cross_cart.fields[field][:,:,1]

    # add this to the profile structure
    start_lonlat = (minimum(cross.lon.val), minimum(cross.lat.val))
    end_lonlat   = (maximum(cross.lon.val), maximum(cross.lat.val))
    
    start_cart   = minimum(x_cart)         
    end_cart     = maximum(x_cart)         

    profile = Profile(cross, start_lonlat, end_lonlat, start_cart, end_cart, z_cart, x_cart, x_lon, x_lat, data, [])

    return profile
end



"""
    start_val, end_val =  get_startend_cross_section(value::JSON3.Object)

Gets the numerical values of start & end of the cross-section (which we can modify by dragging)
"""
function get_startend_cross_section(value::JSON3.Object)

    if haskey(value, Symbol("shapes[0].x0"))
        @show value
        # retrieve values from line 
        x0 = value[Symbol("shapes[0].x0")]
        x1 = value[Symbol("shapes[0].x1")]
        y0 = value[Symbol("shapes[0].y0")]
        y1 = value[Symbol("shapes[0].y1")]
        start_val, end_val = (x0,y0), (x1,y1)
    else
        start_val, end_val = nothing, nothing
    end    
    return start_val, end_val
end

get_startend_cross_section(value::Any) = nothing,nothing


"""
    This interprets a curve that is drawn on the figure; can be a line or path
"""
function interpret_drawn_curve(data::JSON3.Object)
    @show data
    type=nothing
    data_curve=nothing
    try
        shapes = data.shapes
        data_curve = []
        type = data.shapes[1].type
        if type=="path" 
            data_curve = data.shapes[1].path        # this is in SVG format
        elseif type=="line"
            data_curve = [data.shapes[1].x0, data.shapes[1].y0, data.shapes[1].x1, data.shapes[1].y1]
        else
            error("unknown curve shape")    
        end
    catch 
        try 
            data_curve = data[Symbol("shapes[0].path")]
        catch
            data_curve = [  data[Symbol("shapes[0].x0")],
                            data[Symbol("shapes[0].y0")],
                            data[Symbol("shapes[0].x1")],
                            data[Symbol("shapes[0].y1")]]
        end
        type = "path"
    end    
    #
    @show data_curve, type

    return (type, data_curve)
end

interpret_drawn_curve(data::Nothing) = (nothing, nothing)
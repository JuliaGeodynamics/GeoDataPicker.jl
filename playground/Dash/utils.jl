# various helper routines 
using GeophysicalModelGenerator, JLD2
#using GMT


"""
structure that holds info about the project
"""
mutable struct Profile
    Number :: Int64             # Number of the profile

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
    selected_field::Symbol      # currently selected field
    
    Polygons::Vector            # Interpreted polygons along the profile         
    
    # Intersection points       # Vector with intersection points of other profiles with the current one (to be added
end

"""
    DataTomo, DataTopo =  load_dataset(fname::String="AlpsModels.jld2"; grid_name="@earth_relief_02m.grd")

This loads a 3D tomographic dataset from the file `fname` (prepared with the GeophysicalModelGenerator and saves as `*.jld2` format).
It also uses GMT to download the corresponding topographic map for the region

"""
function load_dataset(fname::String="AlpsModels.jld2"; topo_name="AlpsTopo.jld2", grid_name="@earth_relief_02m.grd")
    DataTomo = load_object(fname)
    lon = extrema(DataTomo.lon.val)
    lat = extrema(DataTomo.lat.val)
    
    #DataTopo = ImportTopo(lat=[lat...], lon=[lon...],file=grid_name)
    DataTopo = load_object(topo_name)
    
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
    start_lonlat = Float64.(start_value)
    end_lonlat   = Float64.(end_value)
    
    start_cart   = minimum(x_cart)         
    end_cart     = maximum(x_cart)         

    profile = Profile(0, cross, start_lonlat, end_lonlat, start_cart, end_cart, z_cart, x_cart, x_lon, x_lat, data, field, [])

    return profile
end



"""
    start_val, end_val =  get_startend_cross_section(value::JSON3.Object)

Gets the numerical values of start & end of the cross-section (which we can modify by dragging)
"""
function get_startend_cross_section(value::JSON3.Object)

    if haskey(value, Symbol("shapes[0].x0"))
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
function interpret_drawn_curve(data::JSON3.Object, modify_data)
    type=nothing
    data_curve=nothing
    @show data
    
    shapes_vec = []
    fieldnames_data = keys(data)

    if any(fieldnames_data .== Symbol("shapes"))
        shapes = data.shapes
        @show shapes

        for shape in shapes

            if !isempty(shape)
                data_curve  = []
                type        = shape.type
                label_text  = shape.label.text 
                label_text="alps"
                
                line_color = "#444"
                line_width  = "4"

                names = keys(shape)
                if any(names.==:line)
                    line_color  = shape.line.color
                    line_width  = shape.line.width
                end

                if type=="path" 
                    data_curve = shape.path        # this is in SVG format
                elseif type=="line"
                    data_curve = [shape.x0, shape.y0, shape.x1, shape.y1]
                else
                    error("unknown curve shape")    
                end

                dat = (type=type, data_curve=data_curve, label_text=label_text, line_color=line_color, line_width=line_width)
                push!(shapes_vec, dat)
            end  
        end

    end

    return shapes_vec
end

interpret_drawn_curve(data::Nothing) = []


function extract_start_end_values(start_value, end_value)

    # extract values:
    start_val1 = split(start_value,":")
    start_val1 = start_val1[end]

    end_val1 = split(end_value,":")
    end_val1 = end_val1[end]

    start_val, end_val = nothing, nothing
    s_str = split(start_val1,",")
    e_str = split(end_val1,  ",")
    if length(s_str)==2 && length(e_str)==2
        if !any(isempty.(s_str)) && !any(isempty.(e_str))
            x0,y0 = parse.(Float64,s_str)
            x1,y1 = parse.(Float64,e_str)
            start_val = (x0,y0)
            end_val = (x1,y1)
        end
    end

    return start_val, end_val
end
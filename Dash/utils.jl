# various helper routines 
using GeophysicalModelGenerator, JLD2
#using GMT
import Base:show 

"""
    Structure that holds info about the profiles within the project. 
    Note that we do not store actual data here, but only things that can be changed by the user from the GUI 
"""
mutable struct ProfileUser
    number   :: Int64                   # Number of the profile
    name     :: Union{Nothing,String}   # optional name
    vertical :: Bool                    # vertical profile or not?
    
    start_lonlat::NTuple                # start of profile in lon/lat
    end_lonlat::NTuple                  # end of profile in lon/lat

    depth :: Union{Nothing, Float64}    # depth (only active if vertical == false)
    start_cart::Number                  # start of profile in cartesian coords
    end_cart::Union{Nothing, Float64}   # end of profile in cartesian coords

    Polygons::Vector                    # Interpreted polygons along this profile         
end

"""
    function ProfileUser(;  number=0, 
        name=nothing, 
        vertical=true,
        start_lonlat=(), 
        end_lonlat=(), 
        depth=nothing,
        start_cart=0,
        end_cart = nothing,
        Polygons=[])

Create a user profile with keywords
"""
function ProfileUser(;  number=0, 
                        name=nothing, 
                        vertical=true,
                        start_lonlat=(), 
                        end_lonlat=(), 
                        depth=nothing,
                        start_cart=0,
                        end_cart = nothing,
                        Polygons=[])
    if isnothing(name)
        name = "$number"
    end
    if !isnothing(depth)
        vertical = false
    end

    return ProfileUser(number,name,vertical,Float64.(start_lonlat), Float64.(end_lonlat), depth, start_cart, end_cart, Polygons)
end

# Print info 
function show(io::IO, g::ProfileUser)
    if g.vertical
        println(io, "Vertical profile ($(g.number))")
        println(io, "  lon/lat   : $(g.start_lonlat)-$(g.end_lonlat) ")
    else
        println(io, "Horizontal profile ($(g.number))")
        println(io, "  depth     : $(g.depth) ")
    end
    println(io, "  # polygons: $(length(g.Polygons)) ")

    return nothing
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

    if !hasfield(typeof(cross.fields), field)
        error("The dataset does not have field $field")
    end

    # add this to the profile structure
    start_lonlat = Float64.(start_value)
    end_lonlat   = Float64.(end_value)
    
    start_cart   = minimum(x_cart)         
    end_cart     = maximum(x_cart)         
  
    profile = Profile(  start_lonlat=start_lonlat,  end_lonlat=end_lonlat, 
                        start_cart=start_cart,      end_cart=end_cart)

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
function interpret_drawn_curve(data::JSON3.Object)
    type=nothing
    data_curve=nothing
    
    shapes_vec = []
    fieldnames_data = keys(data)

    if any(fieldnames_data .== Symbol("shapes"))
        shapes = data.shapes

        for shape in shapes

            if !isempty(shape)
                data_curve  = []
                type        = shape.type
                label_text  = shape.label.text 
                
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

    return Float64.(start_val), Float64.(end_val)
end

function profile_names(AppData)

    prof_names = ["none"]
    for cr in AppData.CrossSections
        push!(prof_names, "profile $(cr.Number)")
    end

    return prof_names
end


"""
    AppData = add_AppData(AppData::NamedTuple, session_id::String, new_data::NamedTuple)

This adds data to the global AppData structure
"""
function add_AppData(AppData::NamedTuple, session_id::String, new_data::NamedTuple)
  
  # Store it within the AppData
  data_local  = NamedTuple{(Symbol(session_id),)}((new_data,))

  # Update local data - note that this will overwrite data if a data set with session_id already exist
  AppData     = merge(AppData, data_local)

  @show length(AppData)

  if length(AppData)>10
        println("More than 10 datasets stored in AppData dataset- we may want to limit this automatically")
  end

  return AppData
end

"""
    data = get_AppData(AppData::NamedTuple, session_id::String)

Retrieves data from the global data set if it exists; other
"""
function get_AppData(AppData::NamedTuple, session_id::String)
  
    if haskey(AppData, Symbol(session_id))
        data = AppData[Symbol(session_id)]
    else
        data = nothing
    end
    return data
end
  
"""
    data = get_AppDataUser(AppData::NamedTuple, session_id::String)

Retrieves GUI user data from the global data set if it exists; other
"""
function get_AppDataUser(AppData::NamedTuple, session_id::String)
  
    if haskey(AppData, Symbol(session_id))
        data = AppData[Symbol(session_id)].AppDataUser
    else
        data = nothing
    end
    return data
end

"""
    AppData = set_AppDataUser(AppData::NamedTuple, session_id::String, AppDataUser)

Retrieves GUI user data from the global data set if it exists; other
"""
function set_AppDataUser(AppData::NamedTuple, session_id::String, AppDataUser)
    
    # first update local structure with AppDataUser
    AppDataLocal = get_AppData(AppData, session_id)
    AppDataLocal = add_AppData(AppDataLocal, "AppDataUser", AppDataUser)

    AppData = add_AppData(AppData, session_id, AppDataLocal)

    return AppData
end


"""
    data = get_AppDataUser(AppData::NamedTuple, session_id::String)

Retrieves data from the global data set if it exists; other
"""
function get_AppDataUser(AppData::NamedTuple, session_id::String)
  
    data = nothing
    if haskey(AppData, Symbol(session_id))
        if haskey(AppData[Symbol(session_id)], :AppDataUser)
            data = AppData[Symbol(session_id)].AppDataUser
        end
    else
    end
    return data
end


function get_start_end_profile(AppDataUser; num=0)
    id = find_profile_index(AppDataUser.Profiles, num)
    start_lonlat = AppDataUser.Profiles[id].start_lonlat
    end_lonlat   = AppDataUser.Profiles[id].end_lonlat

    return start_lonlat, end_lonlat
end


get_number_profiles(Profiles::Vector{ProfileUser}) =  [prof.number for prof in Profiles]

"""

Gives the index of the profile given its number (in case numbers are scrambled)
"""
function find_profile_index(Profiles::Vector{ProfileUser}, num::Int64)
    num_vec = get_number_profiles(Profiles)
    id = findall(num_vec .== num)
    if length(id)>0
        id = id[1]
    end
    return id
end


"""
    AppDataUser = update_profile(AppDataUser, profile::ProfileUser; num=0)

updates the profile with number `num`
"""
function update_profile(AppData, profile::ProfileUser; num=0)
    id = find_profile_index(AppData.AppDataUser.Profiles, num)

    if !isempty(id)
        AppData.AppDataUser.Profiles[id] = profile
    end

    return AppData
end



function add_profile(AppData, profile::ProfileUser; num=0)
    id = find_profile_index(AppData.AppDataUser.Profiles, num)

    if !isempty(id)
        AppData.AppDataUser.Profiles[id] = profile
    end

    return AppData
end


function get_profile_options(Profiles)
   options =  [(label="profile $(prof.number)", value=prof.number) for prof in Profiles]
   return options
end

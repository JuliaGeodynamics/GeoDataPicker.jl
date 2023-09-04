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
    if vertical==true
        depth  = nothing
    else
        end_lonlat = deepcopy(start_lonlat)
    end

    if !(start_lonlat == ()) & !isnothing(start_lonlat)
        @show start_lonlat
        start_lonlat = Float64.(start_lonlat)
    end
    if !(end_lonlat == ()) & !isnothing(end_lonlat)
        end_lonlat = Float64.(end_lonlat)
    end

    return ProfileUser(number,name,vertical, start_lonlat, end_lonlat, depth, start_cart, end_cart, Polygons)
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
function get_cross_section(AppData::NamedTuple, profile::ProfileUser, field=:dVp_paf21)

    # retrieve the cross-section in GeoData format
    if profile.vertical == true
        # extract vertical profile
        cross   =   CrossSection(AppData.DataTomo, Start=profile.start_lonlat, End=profile.end_lonlat, Interpolate=true)

        # transfer it to cartesian data
        p           = ProjectionPoint(Lon=minimum(cross.lon.val),Lat=minimum(cross.lat.val));
        cross_cart  = Convert2CartData(cross,p)
        x_cross     = FlattenCrossSection(cross_cart);
        x_cart      = x_cross[:,1,1];
        z_cart      = cross_cart.z.val[1,:,1]
        profile.start_cart = x_cart[1]
        profile.end_cart   = x_cart[end]

        if !hasfield(typeof(cross.fields), field)
            error("The dataset does not have field $field")
        end
    
        data = cross_cart.fields[field][:,:,1]'
    else
        cross_cart  = CrossSection(AppData.DataTomo,  Depth_level=-profile.depth, Interpolate=true)
        x_cart      = cross_cart.lon.val[:,1]
        z_cart      = cross_cart.lat.val[1,:]
        
        if !hasfield(typeof(cross_cart.fields), field)
            error("The dataset does not have field $field")
        end
    
        data = cross_cart.fields[field][:,:,1]'
    end


    # add this to the profile structure

    return x_cart,z_cart,data,cross_cart
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
   options = [(label="default profile", value=0)]
   for i=2:length(Profiles) 
        prof = Profiles[i]
        if prof.vertical
            val  = (label="profile $(prof.number)", value=prof.number) 
        else
            val  = (label="profile $(prof.number) (z=$(prof.depth))", value=prof.number) 
        end
        push!(options,val)
   end

   return options
end


"""
    trigger::String = get_trigger()

returns the trigger callback (simplifies code)
"""
function get_trigger()

    tr = callback_context().triggered;
    trigger = []
    if !isempty(tr)
        trigger = callback_context().triggered[1]
        trigger = trigger[1]
    end
    return trigger
end

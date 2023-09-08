# various helper routines 
using GeophysicalModelGenerator, JLD2
#using GMT
import Base:show 
import GeophysicalModelGenerator: load_GMG, ProfileData, ExtractProfileData


"""
    Structure that holds info about the profiles within the project. 
    Note that we do not store actual data here, but only things that can be changed by the user from the GUI 
"""
mutable struct ProfileUser
    number   :: Int64                           # Number of the profile within the GUI
    name     :: Union{Nothing,String}           # optional name
    vertical :: Bool                            # vertical profile or not?
    
    start_lonlat::NTuple                        # start of profile in lon/lat
    end_lonlat::NTuple                          # end of profile in lon/lat

    depth :: Union{Nothing, Float64}            # depth (only active if vertical == false)
    start_cart::Number                          # start of profile in cartesian coords
    end_cart::Union{Nothing, Float64}           # end of profile in cartesian coords

    Polygons    ::  Vector                      # Interpreted polygons along this profile         
    
    screenshot  :: Union{Nothing, Symbol}       # is there a screenshot along this profile & if yes: which one?
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
        Polygons=[],
        screenshot::Union{Nothing,Symbol} = nothing)

Create a user profile with keywords
"""
function ProfileUser(;  number=0, 
                        name=nothing, 
                        vertical=true,
                        start_lonlat=(), 
                        end_lonlat=(), 
                        depth=nothing,
                        start_cart=0,
                        Polygons=[],
                        screenshot = nothing)
    if isnothing(name)
        name = "$number"
    end
    if vertical==true
        depth  = nothing
    else
        end_lonlat = deepcopy(start_lonlat)
    end

    if !(start_lonlat == ()) & !isnothing(start_lonlat)
        start_lonlat = Float64.(start_lonlat)
    end
    if !(end_lonlat == ()) & !isnothing(end_lonlat)
        end_lonlat = Float64.(end_lonlat)
    end

    if vertical 
        # Vertical cross-sections in GMG  are given in GeoData format (lon/lat). 
        # For visualisation purposes, we transfer that to cartesian data.
        # For some functions we need to know the start & end points of this cartesian cross-section (for example to tranfer curves from cartesian -> lonlat )
        # That's why we store start_cart & end_cart here. 
        #
        # Here, we precompute this with a low resolution grid.
        lon = sort([start_lonlat[1], end_lonlat[1]])
        lat = sort([start_lonlat[2], end_lonlat[2]])
        
        Lon,Lat,Depth = XYZGrid(range(lon...,10), range(lat...,10), range(-100,0,10))
        FakeData  = GeoData(Lon,Lat,Depth, (Data=Depth,))
        
        @show lon,lat, start_lonlat, end_lonlat
        CrossFake = CrossSection(FakeData, Start=start_lonlat, End=end_lonlat, dims=(10,10))  
        
        
        x_cart    = FlattenCrossSection(CrossFake)

        end_cart  = x_cart[end]
    else
        end_cart = nothing
    end

    return ProfileUser(number,name,vertical, start_lonlat, end_lonlat, depth, start_cart, end_cart, Polygons, screenshot)
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
    if !isnothing(g.screenshot)
        println(io, "  screenshot: $(g.screenshot) ")
    end
    return nothing
end


"""
    P = ProfileData(prof::ProfileUser)
Helper function to convert a `ProfileUser` dataset to a `ProfileData` dataset (as defined in GMG)
"""
function  ProfileData(prof::ProfileUser)
    if prof.vertical
        P = ProfileData(start_lonlat=prof.start_lonlat, end_lonlat=prof.end_lonlat)
    else
        P = ProfileData(depth=prof.depth)
    end
    return P
end

"""
    Prof, PlotData = ExtractProfileData(Prof::ProfileData, AppData::NamedTuple, field; section_width=50km)

Helper function to project data onto the profile `Prof`. Also returns the data to plot this cross-section
"""
function  ExtractProfileData(Profile::ProfileData, AppData::NamedTuple, field::Symbol; section_width=50km)

    ExtractProfileData!(Profile, AppData.DataTomo, AppData.DataSurfaces, AppData.DataPoints, section_width=section_width)
    if Profile.vertical
        PlotData = (x_cart = Profile.VolData.fields.x_profile[:,1], z_cart=Profile.VolData.depth.val[1,:])
    else
        PlotData = (x_cart = Profile.VolData.lon.val[:,1], z_cart=Profile.VolData.lat.val[1,:])
    end
    PlotData = merge(PlotData, (data=Profile.VolData.fields[field][:,:,1]',))

    return Profile, PlotData
end

"""
    x,z,data = get_cross_section(DataAlps, profile::ProfileUser, field=:DataTomo_dVp_hua)

Extracts a cross-section from a tomographic dataset and returns this as cartesian values (x,z) formatted for the Plotly heatmap format
"""
function get_cross_section(AppData::NamedTuple, profile::ProfileUser, field=:DataTomo_dVp_hua)

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
        cross       = CrossSection(AppData.DataTomo,  Depth_level=-profile.depth, Interpolate=true)
        cross_cart  = cross;
        x_cart      = cross_cart.lon.val[:,1]
        z_cart      = cross_cart.lat.val[1,:]
        
        if !hasfield(typeof(cross_cart.fields), field)
            error("The dataset does not have field $field")
        end
        
        data = cross_cart.fields[field][:,:,1]'
    end


    # add this to the profile structure

    return x_cart,z_cart,data,cross_cart, cross
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

Retrieves data from the global data set if it exists; otherwise returns nothing
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

        if !isnothing(prof.screenshot)
            str = "$(prof.number) - $(prof.screenshot) "
        else
            str = "profile $(prof.number)"
        end
     
       if !(prof.vertical)
            str = str*"(z=$(prof.depth))"
        end
 
        val  = (label=str, value=prof.number) 
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

"""

This creates PlotlyJS image data from a GMG Screenshot object 
"""
function image_from_screenshot(screenshot::GeoData)

    # Transfer 2 cartesian data
    p           = ProjectionPoint(Lon=minimum(screenshot.lon.val),Lat=minimum(screenshot.lat.val));
    ss_cart     = Convert2CartData(screenshot,p)
    x_ss        = FlattenCrossSection(ss_cart);
    x_cart      = x_ss[1,:];
    z_cart      = ss_cart.z.val[:,1]

    if !hasfield(typeof(screenshot.fields),:colors)
        error("This doesn't seem to be a valid GMG screenshot!")
    end

    # we need to have the colors in a specific format
    siz  =  size(screenshot.fields[:colors][1])
    siz  =  siz[2:-1:1]
    dat  =  zeros(3,siz...);

    for i=1:3
        dat[i,:,:] = screenshot.fields[:colors][i][:,:,1]'
    end
    dat=Int64.(dat*255)

    x0 = x_cart[1]
    y0 = z_cart[1]
    dx = (x_cart[end]-x0)/siz[1]
    dy = (z_cart[end]-y0)/siz[2]
    
    return (x0=x0,dx=dx, y0=y0, dy=dy, z=dat)
end


"""
Takes a GeoData screenshot & adds it to a profile
"""
function screenshot_2_profile(cross::GeoData, number::Int64, screenshot::Symbol)

    name = String(screenshot)
    start_lonlat = (cross.lon.val[1],   cross.lat.val[1])
    end_lonlat   = (cross.lon.val[end], cross.lat.val[end])
    if abs( diff([extrema(cross.depth.val)...])[1])>1e-10
        vertical = true
        depth = nothing
    else
        vertical = false
        depth = cross.depth.val[1]
    end
    start_cart = 0
    Polygons   = []


    Prof = ProfileUser(; number=number, name=name, vertical=vertical,
                         start_lonlat=start_lonlat, end_lonlat=end_lonlat, 
                         depth=depth,
                         start_cart=start_cart,
                         Polygons=Polygons,
                         screenshot = screenshot);

    return Prof
end


function dataset_options(Datasets::Vector{GMG_Dataset}, Type::String)
    options = Vector{String}()
    values  = Vector{String}()
    for data in Datasets
        if data.Type==Type
            push!(options,data.Name)
            if data.active
                push!(values,data.Name)
            end
        end
    end
    return options, values
end


""" 
    Dataset = get_active_datasets(Dataset, active_tomo, active_EQ, active_surf, active_screenshots)

This changes the value of datasets in `Dataset` based on whether they are activated in the GUI or not
"""
function get_active_datasets(Datasets, active_tomo, active_EQ, active_surf, active_screenshots)

    active = [active_tomo...,active_EQ..., active_surf..., active_screenshots...]
    for (i,data) in enumerate(Datasets)
        if any( active .== data.Name)
            Datasets[i].active = true
        end
    end
    return Datasets

end


"""
    filename_dir = parse_uploaded_jld2_file(contents, filename, dir="uploaded_data")

    This parses the data uploaded and saves it to `filename` in directory `dir` (created if necessary).
    It returns the directory and name of the file, so we can load it easily 
"""
function parse_uploaded_jld2_file(contents, filename, dir="uploaded_data")
    if !occursin("jld2", filename)
        error("You need to upload a *.jld2 file!")
    end
    mkpath(dir) # create if needed

    content_type, content_string = split(contents, ',')
    decoded = base64decode(content_string)
    str = String(decoded)       # decode

    save_name = joinpath(dir, filename)
    write(save_name, str)        # write to file

    return save_name
end


"""
    options = get_options_vector(DataFields::NamedTuple)

Simple routine that helps to create the various dropdown menus we have in the GUI
"""
function get_options_vector(DataFields::NamedTuple)

    options = [(label = String(f), value="$f" ) for f in keys(DataFields)]

    return options
end


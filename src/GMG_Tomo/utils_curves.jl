
"""
Holds info about curves
"""
mutable struct Curve
    name     :: Union{Nothing,String}   # optional name
    color    :: Any                     # color
    linewidth :: Float64
    type     :: String
    shape    :: NamedTuple              # holds the shape (for plotting)
    data     :: Any
    lon      :: Vector
    lat      :: Vector
    depth    :: Vector
    closed   :: Bool
end


"""
    This creates a Curve structure, that holds info about hand-drawn curves on profiles 
"""
function set_curve(shape, profile::ProfileUser; name="test", color="#000000", linewidth=1)

    # Later, we will add a routine here that transfers the `shape` to a 3D polygon, 
    # given the info about the profile it is drawn onto 
    lon = [];
    lat = [];
    depth = [];
    if isnothing(color)
        color = "#000000"
    end
    type = shape.type
    
    x,y,closed = svg2vec(shape.data_curve)

    # convert profile to lon,lat,depth depending on profile orientation
    lon,lat,depth = convert_curve_profile(x,y,profile, closed)

    return Curve(name, color,linewidth,  type, shape, shape.data_curve, lon, lat, depth, closed)
end


"""
    update_curve!(curve::Curve, profile::ProfileUser)

If a curve is copied from one profile to another one, the x/y coordinates are still ok, but the lon/lat/depth not necessarily.
This routine updates those
"""
function update_curve!(curve::Curve, profile::ProfileUser)

    x,y,closed = svg2vec(curve.shape.data_curve)
    lon,lat,depth = convert_curve_profile(x,y,profile, closed)
    
    # update
    curve.lon   = lon
    curve.lat   = lat
    curve.depth = depth
    
    return nothing
end


"""
    lon,lat,depth = convert_curve_profile(x,y,profile)

Converts picture coordinates of curve to real coordinates
"""
function convert_curve_profile(x,y,profile,closed=false)
    if profile.vertical==false
        # horizontal depth slice; in this case x,y correspond to lon,lat
        lon,lat,depth = x, y, -ones(size(x))*profile.depth
    else
        Δ_lonlat =  profile.end_lonlat .- profile.start_lonlat
        Δ_cart   =  profile.end_cart - profile.start_cart 
        lon      =  (x .- profile.start_cart)./Δ_cart .*  Δ_lonlat[1] .+ profile.start_lonlat[1]
        lat      =  (x .- profile.start_cart)./Δ_cart .*  Δ_lonlat[2] .+ profile.start_lonlat[2]
        depth    =  y;
    end
    if closed
        push!(lon,lon[1])
        push!(lat,lat[1])
        push!(depth,depth[1])
    end

    return lon,lat,depth
end


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

"""
    x,y,closed = svg2vec(path)
Takes an SVG path & transfers it to 2 vectors with `x,y` coordinates & whether the curve is closed or not
"""
function svg2vec(path)
    closed = false
    if  path[1]=='M'
        if path[end] == 'Z'
            closed = true
            path = path[1:end-1]
        end

        path_coords = split(path[2:end], "L") 
        n = length(path_coords)
        x = zeros(n)
        y = zeros(n)
        for i = 1:n
            x[i], y[i] =  parse.(Float64,split(path_coords[i],","))
        end
    else
        x,y=[],[]
    end

    return  x,y, closed
end

"""
helper function to retrieve the polygon names 
"""
function polygon_names(profile::ProfileUser)

    poly_names = []
    for p in profile.Polygons
        push!(poly_names, "$(p.name)")
    end

    return poly_names
end

polygon_names(profile::Nothing) = []


"""
    profile = get_active_profile(AppData, session_id, selected_profile)
returns the currently active profile (or an empty vector if none is selected)
"""
function get_active_profile(AppData, session_id, selected_profile)

    trigger = get_trigger()
    profile = nothing
    if !isempty(trigger)
        # load current profile and all shapes on plot
        AppDataUser = get_AppDataUser(AppData, session_id)
        if hasfield(typeof(AppDataUser), :Profiles)    
            number_profiles =  get_number_profiles(AppDataUser.Profiles)    # get numbers
            id = findall(number_profiles .== selected_profile)
            
            if !isempty(id)
                id = id[1]
                profile = AppDataUser.Profiles[id]
            end
        end
    end

    return profile
end

function get_current_shapes(fig_cross)
    trigger = get_trigger()
    shapes = []
    if !isempty(trigger)
        # load all shapes on plot
        if any(keys(fig_cross) .== :layout)
            shapes = interpret_drawn_curve(fig_cross.layout)
        end
    end
    return shapes
end

"""
    names = get_curve_names(Profiles)
returns a list with unique names of all curves
"""
function get_curve_names(Profiles)
    names = []
    for prof in Profiles
        for curv in prof.Polygons
            push!(names,curv.name)
        end
    end
    return unique(names)
end

"""
    data = retrieve_curves(Profiles, curve_name::String)
This retrieves curves with name `curve_name` from `Profiles` and collects them in a NamedTuple
"""
function retrieve_curves(Profiles, curve_name::String)

     # loop over all curves & collect curves with the given name
     curve_data = []
     for prof in Profiles
       for poly in prof.Polygons
         if poly.name == curve_name
           @show poly.name, prof.name
           push!(curve_data, poly)
         end
       end
     end
     data_NT = NamedTuple{(Symbol(curve_name),)}( (curve_data,) )

     return data_NT
end

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

    return Curve(name, color,linewidth,  type, shape, shape.data_curve, lon, lat, depth)
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
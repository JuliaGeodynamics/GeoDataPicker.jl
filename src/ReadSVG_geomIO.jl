# This reads an Inkscape (or Affinity Design) file and returns the curves 
using LightXML, WriteVTK, GeometryBasics, FileIO, LinearAlgebra

export parse_SVG, create_surfaces, Write_STL, Write_Paraview


"""
    label, coord = parse_path(path::XMLElement; use_label=true)

This parses a path in a *.SVG file and returns the name of the curve and its coordinates (in the reference frame of the SVG file).
`use_label` can be set to false (in case we don't use inkscape to generate the *.SVG file)

"""
function parse_path(path::XMLElement; use_label=true)
    if use_label
        label =  attribute(path,"label");
    else
        label =  attribute(path,"id");
    end

    # extract data
    d  =  split(attribute(path,"d"));   # the data as vector
    n  = size(d,1)
    coord = zeros(n,2)
    k = 1;
    for i=1:n
        row = d[i]
        if contains(row,",")
            values = parse.(Float64,split(row,","))
            coord[k,1] = values[1]
            coord[k,2] = values[2]
            k += 1;
        end
    end

    return label, coord[1:k-1,:]
end


"""
    Reference structure, used to go from pixels to real coordinates
"""
struct Reference{T}
    xrefPaper :: NTuple{2,T} # lower left coordinate in pixels
    yrefPaper :: NTuple{2,T} # spacing in x/y 
    xref      :: NTuple{2,T} # lower left coordinate in real units
    yref      :: NTuple{2,T} 
end


"""
    Ref = get_reference(xmlroot::XMLElement; is_inkscape=true)

Retrieves the reference of the current *.SVG file, which is a struct that contains the lower left coordinates and spacing in pixels and real units
"""
function get_reference(xmlroot::XMLElement; is_inkscape=true)
    Ref = []
    for c in LightXML.child_nodes(xmlroot) 
        if is_elementnode(c)
            layer = XMLElement(c)  # this makes an XMLElement instance

            label = attribute(layer, "label");
            id    = attribute(layer, "id");

            if is_inkscape
                layerLabel = label
            else
                layerLabel = id
            end

            if !isnothing(layerLabel)
                
                if contains(layerLabel,"Reference")   
                    for p in LightXML.child_nodes(layer) 
                        if is_elementnode(p)
                            path = XMLElement(p)  #     
                            label, coord = parse_path(path)
                          
                            CoordRef_values = parse.(Float64,split(LightXML.attribute(path,"CoordRef"),","))

                            # create the reference structure that is used to transfer pixels -> real coordinates
                            xrefPaper = (coord[1,1], coord[2,1])
                            #yrefPaper = (height - coord[1,2], height - coord[2,2])
                            yrefPaper = (coord[1,2], coord[2,2])
                            
                            xref      = (CoordRef_values[1],CoordRef_values[3])
                            yref      = (CoordRef_values[2],CoordRef_values[4])
                         
                            Ref     = Reference(xrefPaper, yrefPaper, xref, yref)   # assign struct
                        end
                    end
                end
            end

        end
    end

    return Ref
end


"""
    coord_real = pixel2real(coord::Matrix{T}, Ref::Reference)

Transfers a curve from pixel coordinates (SVG file) to real coordinates, using the image reference
"""
function  pixel2real(coord::Matrix{T}, CoordRef::Reference) where T
    pixel_ll = (CoordRef.xrefPaper[1], CoordRef.yrefPaper[1])
    pixel_Δ  = (CoordRef.xrefPaper[2]-CoordRef.xrefPaper[1], CoordRef.yrefPaper[2]-CoordRef.yrefPaper[1])
    
    coord_ll = (CoordRef.xref[1], CoordRef.yref[1])
    coord_Δ  = (CoordRef.xref[2]-CoordRef.xref[1], CoordRef.yref[2]-CoordRef.yref[1])
    coord_shifted = copy(coord);
    for i=1:size(coord,1)
        coord_shifted[i,:] =  (coord_shifted[i,:] .- pixel_ll)./pixel_Δ  
        coord_shifted[i,:] =  coord_shifted[i,:].*coord_Δ .+ coord_ll
    end

    return coord_shifted
end


"""
    coord3D = create_coord3D(coord2D, layerLabel)

Creates a 3D curve out of the 2D coordinates, while taking the label of the layer into account
"""
function create_coord3D(coord2D::Matrix{T}, layerLabel::String) where T
    n = size(coord2D,1)
    labels = split(layerLabel,"_")
    if size(labels,1)==2
        labels[2] = replace(labels[2],"m"=>"-")
        labels[2] = replace(labels[2],"p"=>"+")
        coord3D = ones(n,3)* parse(Float64, labels[2])
        if  labels[1]=="HZ"
            coord3D[:,1:2] = coord2D
        elseif labels[1]=="EW"
            coord3D[:,1] = coord2D[:,1]
            coord3D[:,3] = coord2D[:,2]
        elseif labels[1]=="NS"
            coord3D[:,2:3] = coord2D[:,1:2]
        else
            error("unknown direction")
        end
    else
        coord3D = coord2D
    end

    return coord3D
end


"""
    Curves = parse_SVG(fname::String; is_inkscape=true, verbose=true)

This parses an SVG file; reads all thr curves on the file and transforms them to real coordinates and finally puts the results (with 3D curves) into a NamedTuple
"""
function parse_SVG(fname::String; is_inkscape=true, verbose=true)

    # Read raw data
    raw_file_contents = read(fname, String);

    # Read SVG file
    xml_file = parse_string(raw_file_contents);
    xmlroot = LightXML.root(xml_file);
    @assert LightXML.name(xmlroot) == "svg";            # ensure it is an svg file

    viewBox = attribute(xmlroot, "viewBox");

    if isnothing(viewBox)
        error("no viewBox indicated in file $fname")
    else
        viewBox = parse.(Int64,split(viewBox));

        width = viewBox[3];
        height = viewBox[4];
    end

    # get the reference frame of the image (needs to be a layer called "Reference")
    CoordRef = get_reference(xmlroot);      

    # go through all the layers in the file & extract curves
    Curves = NamedTuple()
    for c in LightXML.child_nodes(xmlroot) 
        if is_elementnode(c)
            layer = XMLElement(c)  # this makes an XMLElement instance

            label = attribute(layer, "label");
            id    = attribute(layer, "id");

            if is_inkscape
                layerLabel = label
            else
                layerLabel = id
            end

            if !isnothing(layerLabel) 
                if layerLabel[1]!='#' && !contains(layerLabel,"Reference") # if label starts with #, do not interpret
                    for p in LightXML.child_nodes(layer) 
                        if is_elementnode(p) 
                            path = XMLElement(p)  #     
                            label, coord = parse_path(path)
                            coord_real = pixel2real(coord, CoordRef);  # transfer to real coordinates
                            
                            coord3D = create_coord3D(coord_real, layerLabel) 

                            # if a curve with the same name already exist, add it to a tuple
                            # if not, create a tuple
                            if haskey(Curves,Symbol(label))
                                coord_data = (Curves[Symbol(label)]..., coord3D)
                            else
                                coord_data = (coord3D,)
                            end
                            NT_local = NamedTuple{(Symbol(label),)}((coord_data,))

                            Curves = merge(Curves,NT_local)
                        end
                    end

                end
            end
        end
    end

    if verbose
        println("Parsed file $fname and read following curves:")

        names = propertynames(Curves)
        for n in names
            println(" $n")
        end
    end

    return Curves
end


"""
    Surfaces = create_surfaces(Curves::NamedTuple; STL=true)

This creates surfaces/matrixes from 3D lines that are read from the `*.svg` files.
The lines all need to have the same number of points.
By default, it will create triangulated surfaces which can be saved as `*.stl` files. Optionally, it can generate matrixes (`STL==false`).
"""
function create_surfaces(Curves::NamedTuple; STL=true)

    Surfaces = NamedTuple()
    labels = keys(Curves)
    for (i, curve) in enumerate(Curves)
        NT_local = create_surfaces(curve, labels[i]; STL=STL)

        if !isempty(NT_local)
            Surfaces = merge(Surfaces, NT_local)
        end
    end

    return Surfaces
end

"""
    create_surfaces(curve::NTuple{Matrix}, label; STL=true)

Creates a 3D mesh from a tuple of lines (with 3D coordinates) as a triangulated surfaces (`STL=true`) or as a matrix (`STL=false`).
"""
function create_surfaces(curve::NTuple{N,Matrix}, label; STL=true) where N

    np = size(curve[1],1)
    if all(size.(curve,1) .== np)
        n = length(curve)
        X,Y,Z = zeros(np,n),  zeros(np,n),  zeros(np,n)
        for j=1:n
            X[:,j] = curve[j][:,1]
            Y[:,j] = curve[j][:,2]
            Z[:,j] = curve[j][:,3]
        end

        # Transfer to matrix of points
        if STL
            Pts = Point{3}.(X,Y,Z);             # using GeometryBasics
            Tr  = convert_to_triangles(Pts)     # create triangular surface
            Tr_n = normal_mesh(Tr)              # with normals info  (compute normals with normals(Tr_n)) 

            NT_local = NamedTuple{(label,)}((Tr_n,))
        else
            NT_local = NamedTuple{(label,)}(((X,Y,Z),))
        end

    else
        println("Cannot create a surface from $(label) as not all curves have the same length")
    end
    
    return NT_local
end


# helper function that converts a matrix of Points to a triangular mesh
function convert_to_triangles(Pts::Matrix{Point3{T}}) where T

    # Number
    Number = zeros(Int64,size(Pts))
    k = 1;
    for i in eachindex(Number)
        Number[i] = k
        k += 1
    end

    # get triangle numbering
    tr = [];
    for i=1:size(Number,1)-1
        for j=1:size(Number,2)-1
            tr1 = TriangleFace(Number[i  ,j  ], Number[i+1,j  ], Number[i  ,j+1])
            tr2 = TriangleFace(Number[i+1,j  ], Number[i+1,j+1], Number[i  ,j+1])
            
            if i==1 & j==1
                tr = [tr1];
            else
                tr = push!(tr,tr1)
            end
            tr = push!(tr,tr2)
        end
    end

    msh = Mesh(Pts[:], tr)

    return  msh   # create triangular mesh
end


add_dim(x::Array) = reshape(x, (size(x)...,1))


"""
    Write_Paraview(Surfaces::NamedTuple; verbose=true)

Writes paraview files from the surfaces
"""
function Write_Paraview(Surfaces::NamedTuple; verbose=true)
    
    labels = keys(Surfaces)

    for (i,surf) in enumerate(Surfaces)

        x,y,z = Surfaces[i][1],Surfaces[i][2],Surfaces[i][3]
        vtk_grid(String(labels[i]), add_dim(x),add_dim(y),add_dim(z) ) do vtk
            vtk["z"]=add_dim(z) 
        end
        if verbose
            println("Wrote file $(labels[i]).vts")
        end

    end
    
    return nothing
end


"""
    Write_STL(Surfaces::NamedTuple; verbose=true)

Writes *.stl files to disk, which can directly be opened in Paraview 
"""
function Write_STL(Surfaces; verbose=true)
    
    labels = keys(Surfaces)
    for (i,surf) in enumerate(Surfaces)
        save(File{format"STL_ASCII"}("$(labels[i]).stl"), Surfaces[i])
        if verbose
            println("Wrote file $(labels[i]).stl")
        end
    end
    
    return nothing
end



# One of the most challenging tasks is to compute the distance of points in the regular grid to the triangulated surface
#
# Below a playground of functions


#=
"""

    signed_distance, isinside, projection = project_point_onto_triangle(point, T::TriangleP)

Projects a `point` on the plane of a triangle `T`. `isinside` indicates whether the projected point is within the triangle or not, and `signed_distance` is the signed distance

# Example usage
```julia
julia> point = [1.0, 2.0, 3.0]
julia> v1 = Point3(0.0, 0.0, 0.0)
julia> v2 = Point3(1.0, 0.0, 0.0)
julia> v3 = Point3(0.0, 1.0, 0.0)
julia> triangle = TriangleP(v1,v2,v3)

julia> signed_distance, isinside, projectione = project_point_onto_triangle(point, triangle)
```

"""
function project_point_onto_triangle(point, T::TriangleP)
    
    normal = normal_triangle(T)

    v1      = T.points[1];

    # Compute the projection point
    projection = point - dot(point - v1, normal) / dot(normal, normal) * normal
    
    
    #isinside = in(projection, T)
    #isinside = is_inside_triangle(projection, T)
    isinside = is_inside_triangle(projection, T)
    
    # Compute the signed distance to the plane
    signed_distance = dot(point - v1, normal) / norm(normal)
    
    if !isinside

         # Compute the shortest distance to the triangle edges
         edge_distances = [point_edge_distance(point, v1, v2),
                           point_edge_distance(point, v2, v3),
                           point_edge_distance(point, v3, v1)]

        shortest_distance = minimum(edge_distances)
        #return shortest_distance, isinside, point

    end
    return signed_distance, isinside, projection
end



function is_inside_triangle(point, T::TriangleP)
    #v1, v2, v3 = T.points

    # Compute the barycentric coordinates of the projection point
    u, v, w = barycentric_coordinates(point, T)

    # Check if the barycentric coordinates are within the triangle's range
    return (u >= 0.0) && (v >= 0.0) && (w >= 0.0) && (u <= 1.0) && (v <= 1.0) && (w <= 1.0)
end

function barycentric_coordinates(point, T::TriangleP)
    v1, v2, v3 = T.points

    # Compute the vectors of the triangle edges
    e1 = v2 - v1
    e2 = v3 - v1
    e3 = point - v1

    # Compute the dot products
    dot11 = dot(e1, e1)
    dot12 = dot(e1, e2)
    dot22 = dot(e2, e2)
    dot13 = dot(e1, e3)
    dot23 = dot(e2, e3)

    # Compute the barycentric coordinates
    inv_denominator = 1.0 / (dot11 * dot22 - dot12 * dot12)
    u = (dot22 * dot13 - dot12 * dot23) * inv_denominator
    v = (dot11 * dot23 - dot12 * dot13) * inv_denominator
    w = 1.0 - u - v

    return u, v, w
end

function point_edge_distance(point, edge_start, edge_end)
    edge = edge_end - edge_start
    point_to_edge = point - edge_start
    edge_length = norm(edge)
    edge_normalized = edge / edge_length
    projection_length = dot(point_to_edge, edge_normalized)
    if projection_length < 0.0
        # Closest point is edge_start
        return norm(point - edge_start)
    elseif projection_length > edge_length
        # Closest point is edge_end
        return norm(point - edge_end)
    else
        # Closest point is on the edge
        projection_point = edge_start + projection_length * edge_normalized
        return norm(point - projection_point)
    end
end


"""
    x,y,z = triangle_extrema(T)

returns the extrema (min/max values) of a triangle `T`
"""
function  triangle_extrema(T)

    points = T.points
    x = extrema(v[1] for v in points)
    y = extrema(v[2] for v in points)
    z = extrema(v[3] for v in points)
    return x, y, z
end

"""
    id = get_index_range(xe::NTuple, x::StepRangeLen)

Returns the indexes when x has a constant spacing. `xe` are the minimum/maximum coordinates of the triangle 
"""
function get_index_range(xe, x::StepRangeLen)
    Δ   = x.step.hi
    val = (xe .- x[1])./Δ; # normalized
    id  = max(floor(Int64, val[1])-1,1):max(min(ceil(Int64, val[2]), x.len)+1,1)

    return id
end


function mark_neighborcells!(Dist, surf::GeometryBasics.Mesh,x,y,z, N=nothing)

    compute_normal = false
    if !isnothing(N)
        compute_normal = true
    end

    for T in surf   
        # find min/max of triangle
        xe,ye,ze = triangle_extrema(T)

        if compute_normal
            normal = normal_triangle(T)
        end

        # bounding box around triangle
        ix = get_index_range(xe, x)
        iy = get_index_range(ye, y)
        iz = get_index_range(ze, z)

        # get minimum distance for every point in BB
        CI   = CartesianIndices((ix,iy,iz))
        for id in CI
      #      Dist[id] = 3333
        end
        for id in CI
            signed_distance, isinside, _ = project_point_onto_triangle([x[id[1]], y[id[2]], z[id[3]] ], T)
            #signed_distance, isinside   = closest_distance_to_triangle([x[id[1]], y[id[2]], z[id[3]] ], T)

            if Dist[id]>signed_distance && isinside
                Dist[id] = signed_distance
                if compute_normal
                    N[id] = normal      # store normal
                end
            end
            if isinside
            #    @show id, signed_distance, Dist[id]
            end
            
        end

        #Phases[CI] .= 1
    end

    return nothing
end

function point_edge_distance(point, edge_start, edge_end)
    edge = edge_end - edge_start
    point_to_edge = point - edge_start
    edge_length = norm(edge)
    edge_normalized = edge / edge_length
    projection_length = dot(point_to_edge, edge_normalized)
    if projection_length < 0.0
        # Closest point is edge_start
        return norm(point - edge_start)
    elseif projection_length > edge_length
        # Closest point is edge_end
        return norm(point - edge_end)
    else
        # Closest point is on the edge
        projection_point = edge_start + projection_length * edge_normalized
        return norm(point - projection_point)
    end
end



using LinearAlgebra

function closest_distance_to_triangular_surface(point, triangular_surface)
    # Initialize variables to store the minimum distance and closest point
    min_distance = Inf
    closest_point = []

    # Iterate over each triangle in the triangular surface
    for triangle in triangular_surface
        # Compute the signed distance to the plane defined by the triangle
        normal = cross(triangle[2] - triangle[1], triangle[3] - triangle[1])
        signed_distance = dot(point - triangle[1], normal) / norm(normal)

        # Compute the closest point
        closest = ifelse(signed_distance > 0, point - signed_distance * normal, triangle[argmin([norm(v - point) for v in triangle])])

        # Compute the distance between the closest point and the point
        distance = norm(closest - point)

        # Update the minimum distance and closest point if necessary
        if distance < min_distance
            min_distance = distance
            closest_point = closest
        end
    end

    return min_distance, closest_point
end

=#






#=


fname="test/data/Alps.HZ.svg";
Curves = parse_SVG(fname, verbose=false);
Surfaces = create_surfaces(Curves);



# create a 3D regular grid
nx,ny,nz = 100,100,200
x = range(-100,4000, length=nx)
y = range(-100,4000, length=ny)
z = range(-600,80 ,  length=nz)


Dist = fill(NaN, nx,ny,nz);
compute_signed_distance_nearest_surface!(Dist,x,y,z, Surfaces[13])
    
using WriteVTK
vtk_grid("Test", Vector(x), Vector(y), Vector(z)) do vtk
    vtk["Dist"] = Dist
end

=#
# This creates triangular surfaces from 2 polygons using Meshes


#using Meshes, GeophysicalModelGenerator, JLD2
#using LinearAlgebra




#curves_App = load_object("ExportCurves_Appenines.jld2")[1];

#i = 1


"""
    poly = create_polygon(lon::Vector,lat::Vector,depth::Vector)

Creates a 3D line with points (for uses within Meshes)
"""
function create_polygon(lon::Vector,lat::Vector,depth::Vector)
    c = Vector{Point3}(undef, 0);
    for j=1:length(lon)
        p = Point(Float64(lon[j]), Float64(lat[j]), Float64(depth[j]))
        push!(c, p)
    end
    
    return c
end

"""
    poly = create_polygon(curve::GeoDataPicker.Curve)
Creates a polygon from a GeoDataPicker Curve object (to be used to create surface triangulations)
"""
create_polygon(curve::GeoDataPicker.Curve) = create_polygon(curve.lon, curve.lat, curve.depth)

"""
    p3 = merge_polygons(p1, p2)
Merge 2 polygons
"""
function merge_polygons(p1, p2)
    p3 = deepcopy(p1)
    for p in p2
        push!(p3,p)
    end

    return p3
end 

"""
    poly_new = reinterpolate_polygon(poly; n=100)

Reinterpolates the polygon in regular points
"""
function reinterpolate_polygon(poly; n=100, normalize=true)

    # we need to normalize it given that the x,y,z values are quite distinct
    Δx = diff([extrema(extract_vec(poly, 1))...])[1]
    Δy = diff([extrema(extract_vec(poly, 2))...])[1]
    Δz = diff([extrema(extract_vec(poly, 3))...])[1]
    Δx = max(Δx,1.0)
    Δy = max(Δy,1.0)
    Δz = max(Δz,1.0)
    
    # distance along curve
    dist = zeros(Float64,length(poly))
    for i=2:length(poly)
        Δ = poly[i]-poly[i-1]
        if normalize
            Δ = Δ./(Δx, Δy, Δz)
        end
        dist[i] = sum(sqrt.(Δ.^2))
    end
    cudist = cumsum(dist)

    # linear interpolation
    x_interp = linear_interpolation(cudist, extract_vec(poly, 1))
    y_interp = linear_interpolation(cudist, extract_vec(poly, 2))
    z_interp = linear_interpolation(cudist, extract_vec(poly, 3))

    # result    
    dist_reg = range(0,cudist[end], length=n)
    x = x_interp.(dist_reg)
    y = y_interp.(dist_reg)
    z = z_interp.(dist_reg)

    return create_polygon(x,y,z)
end

"""
    mesh = triangulate_polygons(p1::Vector{Point3},p2::Vector{Point3}, n=100)

This creates a triangulated surfaces by connecting two polygons. They are first interpolated to the same number of points after which they are connected

"""
function triangulate_polygons(p1::Vector{Point3},p2::Vector{Point3}; n=100)
    p1  = reinterpolate_polygon(p1; n=n)
    p2  = reinterpolate_polygon(p2; n=n)
    p3  = merge_polygons(p1,p2)

    C   = Vector{Connectivity{Triangle, 3}}(undef,2*n)
    num = 0;
    for i=1:n-1
        num += 1
        C[num] = connect((i,i+1,n+i))
        num += 1
        C[num] = connect((i+1,n+i+1,n+i))
    end
    num += 1
    C[num] = connect((n,n+1,1))

    num += 1
    C[num] = connect((n+1,2,1))

    return SimpleMesh(p3, C)
end

"""
Shift a closed poly by one & close it again
"""
function shift_close(poly, shift) 
    p_open  = copy(poly)[1:end-1]       # non-closed part
    p_shift = circshift(p_open, shift)  # shift
    push!(p_shift, p_shift[1])          # close

    return p_shift
end

"""
    mesh = triangulate_polygons(c1::GeoDataPicker.Curve,c2::GeoDataPicker.Curve; n=100)

Creates a triangulated surface by connecting two GeoDataPicker curves that should be more or less parallel
"""
function triangulate_polygons(c1::GeoDataPicker.Curve,c2::GeoDataPicker.Curve; n=100, allowcircshift=true)
    p1 = create_polygon(c1)
    p2 = create_polygon(c2)


    if allowcircshift
        # if we have closed surfaces, we can optionally shift the second curve 
        n2 = length(p2)
        ar = ones(n2)*1e9
        shift_vec = 1:n2

        for i=1:length(shift_vec)
            p2a     = shift_close(p2, i)    # shift and close curve
            ar[i]   = triangle_area(triangulate_polygons(p1,p2a))   # triangulate & compute areas
        end
        
        optimal_shift = argmin(ar);
        p2 = shift_close(p2, shift_vec[optimal_shift]) 

    end

    mesh  = triangulate_polygons(p1,p2, n=n)

    return mesh
end


extract_vec(poly::Vector{Point3}, dim=1) = [ p.coords[dim] for p in poly]


"""
    mesh_plotly = prepare_mesh_plotly(mesh::SimpleMesh)
"""
function prepare_mesh_plotly(mesh::SimpleMesh)
    x,y,z = [],[],[]
    for v in mesh.vertices
        x = push!(x, v.coords[1])
        y = push!(y, v.coords[2])
        z = push!(z, v.coords[3])
    end

    i,j,k = [],[],[]
    for t in mesh.topology.connec
        i = push!(i, t.indices[1] - 1)  # minus 1 as Plotly is 0-based
        j = push!(j, t.indices[2] - 1)
        k = push!(k, t.indices[3] - 1)
    end

    return (; x,y,z,i,j,k)
end


"""
    area =  triangle_area(T::Connectivity{Triangle, 3}, Pts::Vector{Point3})
returns area of triangle `T` given all points in the domain `Pts`
"""
function triangle_area(T::Connectivity{Triangle, 3}, Pts::Vector{Point3})
    v1 = Pts[T.indices[1]]
    v2 = Pts[T.indices[2]]
    v3 = Pts[T.indices[3]]
    # Calculate the lengths of the three sides of the triangle
    a = norm(v2 - v1)
    b = norm(v3 - v2)
    c = norm(v1 - v3)

    # Calculate the semiperimeter
    s = 0.5 * (a + b + c)

    # Calculate the area using Heron's formula
    area = sqrt(s * (s - a) * (s - b) * (s - c))
    return area 
end


"""
    area = triangle_area(mesh::SimpleMesh)
returns the total area of the `mesh`, consisting of triangles 
"""
function triangle_area(mesh::SimpleMesh)
    area = 0.0
    for T in mesh.topology.connec
        area += triangle_area(T, mesh.vertices)
    end

    return area
end



#=
# Main routine:
mesh = triangulate_polygons(curves_App[1],curves_App[2], allowcircshift=true)
for i = 2:length(curves_App)-1
    global mesh
    mesh1 = triangulate_polygons(curves_App[i],curves_App[i+1], allowcircshift=true)

    mesh = merge(mesh,mesh1)
end

=#


#=
using PlotlyJS




mesh_plotly = prepare_mesh_plotly(mesh)

xp = extract_vec(p2, 1)
yp = extract_vec(p2, 2)
zp = extract_vec(p2, 3)


pl = [mesh3d(
    # 8 vertices of a cube
    x=mesh_plotly.x, y=mesh_plotly.y, z=mesh_plotly.z,
    colorbar_title="z",
    # i, j and k give the vertices of triangles
    i = mesh_plotly.i, j = mesh_plotly.j, k = mesh_plotly.k,
    name="y",
    showscale=true,
)]

for c1 in curves_App
    poly1 = create_polygon(c1)
    push!(pl, scatter3d(x=extract_vec(poly1, 1),y=extract_vec(poly1, 2),z=extract_vec(poly1, 3), line = attr(color="black",)) )
end


PlotlyJS.plot(pl)

=#






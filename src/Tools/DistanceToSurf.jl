using LinearAlgebra, NearestNeighbors, Random

export compute_signed_distance_nearest_surface!


"""     
    normal = normal_triangle(T::TriangleP)

Computes the normal of a triangle `T`. 
"""
function normal_triangle(T::TriangleP)

    point1 = T.points[1];
    point2 = T.points[2];
    point3 = T.points[3];
    
    # Calculate the vectors for two sides of the triangle
    side1 = point2 - point1
    side2 = point3 - point1
    
    # Compute the cross product of the two sides
    norml = cross(side1, side2)
    
    # Normalize the normal vector
    norml   = normalize(norml)

    return norml
end

"""
    points = generate_points_on_triangle(n::Int64, T::TriangleP)

This generates a list of `n` points that are distributed over a 3D triangle `T`.
"""
function generate_points_on_triangle(n::Int64, T::TriangleP)
    
    v1,v2,v3 = T.points

    points = Vector{Point{3,Float32}}(undef, n)
    for i in 1:n
        # Generate random barycentric coordinates
        r1, r2 = rand(2)
        if r1 + r2 > 1
            r1 = 1 - r1
            r2 = 1 - r2
        end
        r3 = 1 - r1 - r2

        # Compute the point using barycentric coordinates
        point = r1*v1 + r2*v2 + r3*v3
        points[i] = Point(point)
    end

    return points
end


"""
    area = area_triangle(T::TriangleP)

Does as it says
"""
function area_triangle(T::TriangleP)
    v1,v2,v3 = T.points
    side1 = v2 - v1
    side2 = v3 - v1
    cross_product = cross(side1, side2)
    area = norm(cross_product) / 2.0
    return area
end

"""
    signed_distance(pt, points, normal);  

The signed distance between point `pt` and `point` with `normal` that is located on the triangular surface
"""
function signed_distance(pt, point, normal);  
    signed_distance = dot(pt - point, normal) / norm(normal)

    return signed_distance
end


function compute_sign(pt2, pt1, n1)
    vec = pt2 - pt1
    dot_product = dot(vec, n1)
    sgn = sign(dot_product)
    return sgn
end

"""
    compute_signed_distance_nearest_surface!(Dist,x,y,z, Surf; dist_critical=400, area_factor=10)

This computes the closest distance of the points within Dist with coordinates described by 1D vectors `x`,`y`,`z` to the triangular surface `Surf`

Algorithm:
1) Add points to the triangular surface (and propagate triangle normals)
2) Use a KDtree nearest neighbor algorithm, to find closest point on triangular surface
3) If the point is at `distance`<`dist_critical`, we compute the sign of tyhe distance (negative is below surface) 


Example
===
```julia
julia> fname="test/data/Alps.HZ.svg";
julia> Curves = parse_SVG(fname, verbose=false);
julia> Surfaces = create_surfaces(Curves);

julia> # create a 3D regular grid
julia> nx,ny,nz = 100,100,200
julia> x = range(-100,4000, length=nx)
julia> y = range(-100,4000, length=ny)
julia> z = range(-600,80 ,  length=nz)
julia> # compute distance
julia> Dist = fill(NaN, nx,ny,nz);
julia> compute_signed_distance_nearest_surface!(Dist,x,y,z, Surfaces[13])

julia> using WriteVTK
julia> vtk_grid("Test", Vector(x), Vector(y), Vector(z)) do vtk
         vtk["Dist"] = Dist
       end

```

"""
function compute_signed_distance_nearest_surface!(Dist,x,y,z, Surf; dist_critical=400, area_factor=2)
    
    # Compute typical gridsize
    Δx = minimum(diff(x));
    Δy = minimum(diff(y));
    Δz = minimum(diff(z));
    Δ2 = minimum([Δx,Δy,Δz])^2*area_factor

    # Add points to the triangles
    points = Surf.position
    normal = normals(Surf)
    for T in Surf
        areaT = area_triangle(T)
        N     = normal_triangle(T)
        num   = round(Int64,areaT/Δ2)
        ptsT  = generate_points_on_triangle(num, T)
        points = vcat(points,ptsT)
        normal = vcat(normal,fill(N,num))
    end
    
    # create a tree 
    tree = KDTree(points);

    # Loop over points in 3D grid and compute closest distance
    for I in CartesianIndices(Dist)
        pt = [x[I[1]],y[I[2]],z[I[3]]]
        ind, dist = nn(tree,pt)
        if dist<dist_critical
            sgn = compute_sign(pt,points[ind], normal[ind])
            Dist[I] = sgn*dist
        end
    end
    

    return nothing
end



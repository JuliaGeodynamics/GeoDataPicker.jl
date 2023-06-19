# This implements Eikonal solver to compute the shortest distance to a set of points in 2D or 3D with known distance

"""
    eikonal_solver_2d!(solution, start_nodes, distance_map, dx, dy)

```julia
julia> nx, ny = 10,10
julia> distance_map = zeros(nx,ny);
julia> distance_map[4, 5] = 2.0;
julia> distance_map[7, 8] = -1.0;
julia> dx,dy = 1.0/nx, 1.0 / ny;

# Initialize the solution grid with initial values
julia> solution = fill(Inf, (nx, ny));
julia> start_nodes = [(i, j) for i in 1:nx, j in 1:ny if abs(distance_map[i, j]) > 0];
julia> eikonal_solver_2d!(solution, start_nodes, distance_map, dx,dy)
10×10 Matrix{Float64}:
  2.04015   2.03015   2.0211    2.01205   2.003     2.01205   2.0211    2.03015  -0.96685  -0.9759
  2.0401    2.0301    2.0201    2.01105   2.002     2.01105   2.0201   -0.9769   -0.98595  -0.9769
  2.04005   2.03005   2.02005   2.01005   2.001     2.01005  -0.98695  -0.996    -0.98695  -0.9779
  2.04      2.03      2.02      2.01      2.0      -0.9789   -0.98795  -0.997    -0.98795  -0.9789
  2.04005   2.03005   2.02005   2.01005  -0.9699   -0.9799   -0.98895  -0.998    -0.98895  -0.9799
  2.0401    2.0301    2.0201   -0.95995  -0.96995  -0.97995  -0.98995  -0.999    -0.98995  -0.97995
  2.04015   2.03015  -0.9499   -0.96     -0.97     -0.98     -0.99     -1.0      -0.99     -0.98
  2.0402   -0.93985  -0.94995  -0.95995  -0.96995  -0.97995  -0.98995  -0.999    -0.98995  -0.97995
 -0.9298   -0.9399   -0.9499   -0.9599   -0.9699   -0.9799   -0.98895  -0.998    -0.98895  -0.9799
 -0.92985  -0.93985  -0.94985  -0.95985  -0.96985  -0.9789   -0.98795  -0.997    -0.98795  -0.9789
```
"""
function eikonal_solver_2d!(solution, start_nodes, distance_map, dx, dy)

    # Initialize the starting nodes
    queue = deepcopy(start_nodes)
    
    nx,ny = size(solution)
    visited = falses((nx, ny))

    # Initialize the starting nodes with known distances
    for (i, j) in start_nodes
        solution[i, j] = distance_map[i, j]
    end

    while !isempty(queue)
        # Get the first node from the queue
        node = popfirst!(queue)
        i, j = node

        # Skip already visited nodes
        if visited[i, j]
            continue
        end

        visited[i, j] = true

        # Update the neighbors of the current node
        for ni in max(1, i-1):min(nx, i+1), nj in max(1, j-1):min(ny, j+1)
            if ni != i || nj != j
                g = solution[ni, nj]
                new_dist = sqrt((ni - i)^2* dx^2 + (nj - j)^2) * dy^2 + solution[i, j]
                if new_dist < g
                    solution[ni, nj] = new_dist
                    push!(queue, (ni, nj))
                end
            end
        end
    end

    return solution
end


"""
    eikonal_solver_3d!(solution, start_nodes, distance_map, dx, dy)

```julia
julia> nx, ny,nz = 10,10,5
julia> distance_map = zeros(nx,ny,nz);
julia> distance_map[4, 5, 1] = 2.0;
julia> distance_map[7, 8, 2] = -1.0;
julia> dx,dy,dz = 1.0/nx, 1.0 / ny, 1.0/nz;

# Initialize the solution grid with initial values
julia> solution = fill(Inf, (nx, ny, nz));
julia> start_nodes = [(i, j, k) for i in 1:nx, j in 1:ny, k in 1:nz if abs(distance_map[i, j, k]) > 0];
julia> eikonal_solver_3d!(solution, start_nodes, distance_map, dx, dy, dz)
10×10 Matrix{Float64}:
  2.04015   2.03015   2.0211    2.01205   2.003     2.01205   2.0211    2.03015  -0.96685  -0.9759
  2.0401    2.0301    2.0201    2.01105   2.002     2.01105   2.0201   -0.9769   -0.98595  -0.9769
  2.04005   2.03005   2.02005   2.01005   2.001     2.01005  -0.98695  -0.996    -0.98695  -0.9779
  2.04      2.03      2.02      2.01      2.0      -0.9789   -0.98795  -0.997    -0.98795  -0.9789
  2.04005   2.03005   2.02005   2.01005  -0.9699   -0.9799   -0.98895  -0.998    -0.98895  -0.9799
  2.0401    2.0301    2.0201   -0.95995  -0.96995  -0.97995  -0.98995  -0.999    -0.98995  -0.97995
  2.04015   2.03015  -0.9499   -0.96     -0.97     -0.98     -0.99     -1.0      -0.99     -0.98
  2.0402   -0.93985  -0.94995  -0.95995  -0.96995  -0.97995  -0.98995  -0.999    -0.98995  -0.97995
 -0.9298   -0.9399   -0.9499   -0.9599   -0.9699   -0.9799   -0.98895  -0.998    -0.98895  -0.9799
 -0.92985  -0.93985  -0.94985  -0.95985  -0.96985  -0.9789   -0.98795  -0.997    -0.98795  -0.9789
```
"""
function eikonal_solver_3d!(solution, start_nodes, distance_map, dx, dy, dz)
    nx, ny, nz = size(distance_map)

    # Create a priority queue to store the nodes
    queue = deepcopy(start_nodes)

    visited = falses((nx, ny, nz))

    # Initialize the starting nodes with known distances
    for (i, j, k) in start_nodes
        solution[i, j, k] = distance_map[i, j, k]
    end
    
    # Process the queue until it's empty
    while !isempty(queue)
        # Get the first node from the queue
        node = popfirst!(queue)
        i, j, k = node

        # Skip already visited nodes
        if visited[i, j, k]
            continue
        end

        visited[i, j, k] = true

        # Update the neighbors of the current node
        for ni in max(1, i-1):min(nx, i+1), nj in max(1, j-1):min(ny, j+1), nk in max(1, k-1):min(nz, k+1)
            if ni != i || nj != j || nk != k
                g = solution[ni, nj, nk]
             
                dx2 = dx^2
                dy2 = dy^2
                dz2 = dz^2
                di = ni - i
                dj = nj - j
                dk = nk - k
                new_dist = sqrt(di^2 * dx2 + dj^2 * dy2 + dk^2 * dz2) + solution[i, j, k]


                if new_dist < g
                    solution[ni, nj, nk] = new_dist
                    push!(queue, (ni, nj, nk))
                end
            end
        end
    end

    return solution
end


#=
# Example usage
nx, ny = 10,10
distance_map = zeros(nx,ny);
distance_map[4, 5] = 2.0;
distance_map[7, 8] = -1.0;
h = 1.0 / max(nx, ny);
dx = dy = h

# Initialize the solution grid with initial values
solution = fill(Inf, (nx, ny));

start_nodes = [(i, j) for i in 1:nx, j in 1:ny if abs(distance_map[i, j]) > 0];
eikonal_solver_2d!(solution, start_nodes, distance_map, dx,dy)


#solution = eikonal_solver_2d(distance_map)
println("Shortest distance solution:")
println(solution)

=#



nx, ny,nz = 10,10,5
distance_map = zeros(nx,ny,nz);
distance_map[4, 5, 1] = 2.0;
distance_map[7, 8, 2] = -1.0;
dx,dy,dz = 1.0/nx, 1.0 / ny, 1.0/nz;

# Initialize the solution grid with initial values
solution = fill(Inf, (nx, ny, nz));
start_nodes = [(i, j, k) for i in 1:nx, j in 1:ny, k in 1:nz if abs(distance_map[i, j, k]) > 0];
eikonal_solver_3d!(solution, start_nodes, distance_map, dx, dy, dz)

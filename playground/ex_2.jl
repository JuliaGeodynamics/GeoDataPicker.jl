# ex_2.jl
# First example with Bezier curves, where we define a structure for a Bezier polygon and functions that create 

using GLMakie, StaticArrays
#Makie.inline!(true)

"""

Bezier polygon with multiple control points
"""
mutable struct BezierPoly{N,M}
    Name::String                            # Name of polygon
    Number::Int64                           # Number 
    Closed::Bool                            # Closed polygon?
    visible::Bool
    line_props::Any                         # color of polygon 
    fill_props::Any                         # properties of filled polygon (color etc,)
    x::SizedMatrix{N,2,Point2, M, Matrix{Point2}}         # coords of Bezier ctrl points
    t::SizedMatrix{N,2, Vec2, M, Matrix{Vec2}}         # x-direction of tangential vector @ ctrl points
    continuous::SizedMatrix{N,2}            # continuous derivative @ ctrl pts?
    x_poly::Vector{Point2}
end

"""
    BezierPoly(x0::Vector,x1::Vector,t0::Vector,t1::Vector; Name="", Number=1, Closed=false, continuous=missing)

Constructs a simple Bezier polygon from 2 points 
"""
function BezierPoly(x_in::NTuple{N,Point2},t_in::NTuple{N,Vec2}; Name="", Number=1, Closed=false, continuous=missing, line_props=(color=:black,), fill_props=missing) where {N}

    Nseg = N-1;
    x = zeros(Point2,Nseg,2)
    t = zeros(Vec2,Nseg,2)
    for i=1:Nseg
        x[i,1], x[i,2] = x_in[i], x_in[i+1]
        t[i,1], t[i,2] = t_in[i], t_in[i+1]
    end

    if ismissing(continuous)
        continuous = zeros(Bool, size(x))
    end
    
    # Create Bezier Polygon points
    X = SizedMatrix{Nseg,2}(x)
    T = SizedMatrix{Nseg,2}(t)

    Npts    = 100
    x_poly  = zeros(Point2,Npts*Nseg)

    # Compute the coords of the Bezier polygon (for plotting)
    compute_curve!(X, T, x_poly)

    return BezierPoly(Name, Number, Closed, true, line_props, fill_props,  X, T, SizedMatrix{Nseg,2}{Bool}(continuous),x_poly)
end

"""
This returns x,y coordinates of a BezierPoly
"""
function compute_curve!(Xpts::SizedMatrix{Nseg,2,Point2,M, Matrix{Point2}} , Tpts::SizedMatrix{Nseg,2,Vec2,M, Matrix{Vec2}} , x_poly::Vector{Point2}; N=100) where {Nseg,M}
    t = range(0, 1 ; length=N)
    
    for i=1:Nseg

        X = bezier_coefs(Xpts[i,1][1], Xpts[i,2][1], Tpts[i,1][1], Tpts[i,2][1])
        Y = bezier_coefs(Xpts[i,1][2], Xpts[i,2][2], Tpts[i,1][2], Tpts[i,2][2])

        for j=1:N
            id = (i-1)*N + j
            x_poly[ id] = Point2(curve(X,Y,t[j]))
        end

    end

    return nothing
end


function compute_curve(poly::BezierPoly{Nseg}; N=100) where {Nseg}
    N = 100
    x_poly = zeros(Point2,N*Nseg)

    compute_curve!(poly.x, poly.t, x_poly)

    return x_poly
end

# This computes a pount on the bezier curve
function curve(Xcoef::NTuple{4,_T},Ycoef::NTuple{4,_T},t::_T) where {_T}
    x = zero(_T)
    y = zero(_T)
    
    for i = 1:4
        x += Xcoef[i] * t^(4-i)
        y += Ycoef[i] * t^(4-i)
    end
    
    return x,y
end

# Give coefficients of one Bezier curve component
function bezier_coefs(x0::T, x1::T, t0::T, t1::T) where {T}
    a = 2(x0-x1) + t1 + t0
    b = 3(x1-x0) - t1 - 2t0
    c = t0
    d = x0
    return (a,b,c,d)
end

"""
Plots a Bezier polygon with control points
"""
function plot_poly(poly::Observable{BezierPoly{Nseg}}, ax) where {Nseg}

    pts = compute_curve(poly_o[])
    l_bezier = lines!(ax,pts[1], pts[2])
    p_bezier = scatter!(ax, Vector(poly[].x[:]), Vector(poly[].y[:]))
    
    return l_bezier, p_bezier
end


# example
x0 = Point2(0.0, 0.0) # start point
x1 = Point2(2.0, 0.0) # end point
x2 = Point2(3.0, 0.2) # end point

t0 = Vec2(0.1, 0.1) # starting tangent vector
t1 = Vec2(0.0, 0.1) # end tangent vector
t2 = Vec2(0.1, 0.1) # end tangent vector


function plot_data(x,t; res=(1920,1080))
    fig = Figure(resolution = res);
    ax = fig[1,1] = Axis(fig);

     # define the data & the index of the point currently modified to be an observable
   #  data_1 = Point2.(data[:,1],data[:,2])
   #  positions = Observable(data_1)
   #  pos_selected = Observable(data_1[1])
   #  i_loc   = Observable(1);
   #  i_merge = Observable(0);



end

# Create bezier polygon
#poly = plot_data( (x0, x1, x2), (t0, t1, t2) )
poly = Node(BezierPoly((x0, x1, x2), (t0, t1, t2) ))

x_pts = @lift(:poly.x)

# Update a point:
poly[].x[1,1]=Point(2.0,1.2)




fig = Figure();
ax = fig[1,1] = Axis(fig);



function  update_x_poly(poly) 
    # this is executed every time poly changes
    pts = compute_curve(poly)

    return pts
end
x1_poly = lift(update_x_poly, poly)


#lines!(ax, x1_poly[])
scatter!(ax, Vector(poly.x[:]))


#l_bezier, p_bezier = plot_poly(poly_o,ax)







#=
for i=1:size(poly.x,1)
    for j=1:2
        if j==1
            f = 1
        else
            f = -1;
        end
        xv = [poly.x[i,j], poly.x[i,j] + f*poly.tx[i,j]]
        yv = [poly.y[i,j], poly.y[i,j] + f*poly.ty[i,j]]
        
        lines!(fig[1,1],xv, yv, color=:red)
        scatter!(fig[1,1],xv, yv, color=:red)
    end
end
=#




function plot_bezier_tangent(poly::BezierPoly, ax)


end



#function plot
#scatter!(x0[1])

display(fig)
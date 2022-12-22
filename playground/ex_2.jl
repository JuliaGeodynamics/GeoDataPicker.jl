# ex_2.jl
# First example with Bezier curves, where we define a structure for a Bezier polygon and functions that create 

using GLMakie, StaticArrays
#Makie.inline!(true)

# This is a polygon that can consist of one or several bezier points & corresponding slopes
# Note: we always define Bezier segments, consistong of 2 points & corresponding tangents
mutable struct BezierPoly{N, Nt}
    Name::String                        # Name of polygon
    Number::Int64                       # Number 
    Closed::Bool                        # Closed polygon?
    Color::Any                          # color of polygon 
    x::MMatrix{N,2,Float64,Nt}         # x-coords of Bezier ctrl points
    y::MMatrix{N,2,Float64,Nt}         # y-coords of Bezier ctrl points
    tx::MMatrix{N,2,Float64,Nt}        # x-direction of tangential vector @ ctrl points
    ty::MMatrix{N,2,Float64,Nt}        # y-direction of tangential vector @ ctrl points
    continuous::MMatrix{N,2,Bool,Nt}   # continuous derivative @ ctrl pts?
end

"""
    BezierPoly(x0::Vector,x1::Vector,t0::Vector,t1::Vector; Name="", Number=1, Closed=false, continuous=missing)

Constructs a simple Bezier polygon from 2 points 
"""
function BezierPoly(x::NTuple{N,Vector{T}},t::NTuple{N,Vector{T}}; Name="", Number=1, Closed=false, continuous=missing, Color=:black) where {N,T}

    Nseg = N-1;
    xv = zeros(Nseg,2)
    yv = zeros(Nseg,2)
    tx = zeros(Nseg,2)
    ty = zeros(Nseg,2)
    for i=1:Nseg
        xv[i,1], xv[i,2] = x[i][1], x[i+1][1]
        yv[i,1], yv[i,2] = x[i][2], x[i+1][2]
        tx[i,1], tx[i,2] = t[i][1], t[i+1][1]
        ty[i,1], ty[i,2] = t[i][2], t[i+1][2]
    end

    if ismissing(continuous)
        continuous = zeros(Bool, size(xv))
    end

    return BezierPoly(Name, Number, Closed, Color,  MMatrix{Nseg,2}(xv), MMatrix{Nseg,2}(yv), MMatrix{Nseg,2}(tx), MMatrix{Nseg,2}(ty), MMatrix{Nseg,2}(continuous))
end

"""
This returns x,y coordinates of a BezierPoly
"""
function compute_curve!(x_vec::Vector{_T}, y_vec::Vector{_T}, poly::BezierPoly{Nseg,Nt}) where {Nseg,Nt, _T}
    N = 100;
    nseg = size(poly.x,1)
    t = range(0, 1 ; length=N)
    
    for i=1:nseg

        X = bezier_coefs(poly.x[i,1], poly.x[i,2], poly.tx[i,1], poly.tx[i,2])
        Y = bezier_coefs(poly.y[i,1], poly.y[i,2], poly.ty[i,1], poly.ty[i,2])

        for j=1:N
            id = (i-1)*N + j
            x_vec[ id], y_vec[id] = curve(X,Y,t[j])
        end

    end

    return nothing
end


function compute_curve(poly::BezierPoly{Nseg,Nt}) where {Nseg,Nt}
    N = 100
    x_vec = zeros(N*Nseg)
    y_vec = zeros(N*Nseg)

    compute_curve!(x_vec, y_vec,poly)
    return x_vec, y_vec
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

# example
x0 = [0.0, 0.0] # start point
x1 = [2.0, 0.0] # end point
x2 = [3.0, 0.2] # end point

t0 = [0.1, 0.1] # starting tangent vector
t1 = [0.0, 0.1] # end tangent vector
t2 = [0.1, 0.1] # end tangent vector

# Create bezier polygon
poly = BezierPoly( (x0, x1, x2), (t0, t1, t2) )


pts = compute_curve(poly)



fig = Figure();


lines(fig[1,1],pts[1], pts[2])

scatter!(fig[1,1], Vector(poly.x[:]), Vector(poly.y[:]))
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



#function plot
#scatter!(x0[1])

display(fig)
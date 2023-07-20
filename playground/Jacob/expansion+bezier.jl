#combing poly and datapick


# First example of how to pick data on a plot and create a polygon.
# Keyboard shortcuts:
#   a - add new points (at the end or inbetween, depending where you click)
#   d - delete points
#   m - merge points (aka: put them on top of each other)
#   b - breakup points
#   n - create new line of points
#   s - switch betweens lines
cd("/Users/jacob/Library/Mobile Documents/com~apple~CloudDocs/DataPicker-main/playground")
using GLMakie, LinearAlgebra

include("ex_2.jl")

Makie.inline!(false)

function plot_data(data; res=(1920,1080), hide = true)
    fig = Figure(resolution = res);
    ax = fig[1,1] = Axis(fig);

    # define the data & the index of the point currently modified to be an observable
    active = 1;                     #set data to be active and movable by positions
    actives = [active];
    data_1 = Point2.(data[active][:,1],data[active][:,2])
    positions = Observable(data_1)
    pos_selected = Observable(data_1[1])
    i_loc   = Observable(1);
    i_merge = Observable(0);

    #initialize the vectors to save tangent point positions
    data_bezy = [ones(length(data_1),2)] .*0.1    
    data_bezy .= data .+ data_bezy                                  
    data_1_bezy = Point2.(data_bezy[active][:,1], data_bezy[active][:,2])
    positions_tangents = Observable(data_1_bezy)

    # update location of point
    on(events(ax.scene).mouseposition, priority = 2) do _
        if ispressed(ax.scene, Mouse.left) #& Keyboard.m in events(fig).keyboardstate

            xy = vec(mouseposition(ax))
            dist_p = compute_dist_points(positions, xy)
            dist_b = compute_dist_bezy(positions_tangents, xy)

            if minimum(dist_p) < minimum(dist_b)
                positions[][i_loc[]] = mouseposition(ax.scene)
                pos_selected[] = positions[][i_loc[]]
                notify(positions)
            else    
                positions_tangents[][i_loc[]] = mouseposition(ax.scene)
                pos_selected[] = positions_tangents[][i_loc[]]
                notify(positions_tangents)
            end
                notify(pos_selected)
            return Consume(true)    # this would block rectangle zoom
        end
        return Consume(false), positions
    end
    
    on(events(fig).mousebutton, priority = 2) do event
        if event.button == Mouse.left && event.action == Mouse.press
            if Keyboard.d in events(fig).keyboardstate
                # Delete marker
                # we push "d" on keyboard and click on plot
                
                i = pick_index(fig, ax, positions, positions_tangents)

                deleteat!(positions[], i)
                i_loc[] = i-1
                
                pos_selected[] = positions[][i_loc[]]
                notify(positions)
                notify(pos_selected)
                return Consume(true)

            elseif Keyboard.a in events(fig).keyboardstate
                # Add a new marker 
                # push "a" on the keyboard

                # 1) Check if we are close to the existing curve

                on_bound, ind_bound = compute_on_polygon(positions, mouseposition(ax)) 
                insert = ind_bound+1
                if on_bound
                    # We are 
                    push!(positions[], positions[][end])    # add end point

                    positions[][insert+1:end] =  positions[][insert:end-1] # move existing positions
                    positions[][insert] =  mouseposition(ax) # add new point
                    i_loc[] = insert-1

                    push!(positions_tangents[],positions[][end])

                    positions_tangents[][insert+1:end] =  positions_tangents[][insert:end-1] # move existing positions
                    positions_tangents[][insert] =  mouseposition(ax) # add new point
                    i_loc[] = insert-1

                else
                    # 2) Otherwise add new point @ end of list
                    push!(positions[], mouseposition(ax))
                    i_loc[] = length(positions[])

                    cat(dims=1, positions_tangents[], vec(mouseposition(ax)))
                    i_loc[] = length(positions_tangents[])                    
                end
                
                if minimum(dist_p) < minimum(dist_b)
                    pos_selected[] = positions[][i_loc[]]
                else    
                    pos_selected[] = positions_tangents[][i_loc[]]
                end

                pos_selected[] = positions[][i_loc[]]

                notify(positions)
                notify(positions_tangents)
                notify(pos_selected)

                #save added points to 'storage'
                for i in eachindex(data_1)
                    if i <= length(data[active][:,1])
                        data[active][i,1] = data_1[i][1]
                        data[active][i,2] = data_1[i][2]
                     
                    else
                        cat(dims=1, data[active], [data_1[i][1] data_1[i][2]])

                    end
                end
                return Consume(true)

            elseif Keyboard.m in events(fig).keyboardstate
                # merge markers to close a polygon.
                # push "m" and click first point; next click second point

                i = pick_index(fig, ax, positions, positions_tangents)
                i_loc[] = i
                if i_merge[] == 0
                    # we are clicking for the 1th time
                    i_merge[] = i
                else
                    # click 2nd time, so we merge now
                    positions[][i_merge[]] =  positions[][i_loc[]]
                    i_merge[] = 0

                    # NOTE: at a later stage, we probably have to add a way here to make this a true, closed, polygon
                end
                pos_selected[] = positions[][i_loc[]]

                notify(pos_selected)
                notify(positions)
                return Consume(true)

            elseif Keyboard.b in events(fig).keyboardstate
                # breakup point

                # Note this is not really broken up, as it remains connected. I suppose we have 
                # to introduce a polygon  and a curve struct that includes connectivity info to deal with this
                
                i = pick_index(fig, ax, positions, bezy_positions)
                
                push!(positions[], positions[][end])    # add end point
                positions[][i+1:end] =  positions[][i:end-1] # move existing positions
                positions[][i] =  positions[][i+1] # add new point

               
                pos_selected[] = positions[][i]
                notify(pos_selected)
                notify(positions)
                return Consume(true)
                
            elseif Keyboard.n in events(fig).keyboardstate
                # create new array of points

                #create new random array of points and add to data array
                new_points = rand(10,2)
                new_points[:,1] = 1:10;
                push!(data, new_points)

                colors = push!(colors, RGBf(rand(3)...))
                labels = push!(labels, "$active")

                # delete!(legend)

                update_plots(data, positions, pos_selected, data_1, fig, ax, active, actives, colors, labels, hide)

                legend = Legend(fig[1,2], ax, "lines", merge = true, label=labels)

                display(fig)

                return 

            elseif Keyboard.s in events(fig).keyboardstate
                # switch between point arrays

                #save changed data to 'data storage'
                for i in 1:length(data_1)                                     
                    if i <= length(data[active][:,1])
                    data[active][i,1] = data_1[i][1]
                    data[active][i,2] = data_1[i][2]
                    else 
                    data[active] = cat(dims=1, data[active], [data_1[i][1] data_1[i][2]])
                    end
                end

                active = active + 1;                                        #update active data

                if active > length(data)                                    #change to 1 if active exceeds boundaries
                    active = 1;
                end

                # delete!(legend)

                data_1 = Point2.(data[active][:,1],data[active][:,2])
                positions = Observable(data_1)
                pos_selected = Observable(data_1[1])

                notify(positions)
                notify(pos_selected)

                update_plots(data, positions, pos_selected, data_1, fig, ax, active, actives, colors, labels, hide)
                legend = Legend(fig[1,2], ax, "lines", merge = true, label=labels)
                display(fig)

                return Consume(true)

            elseif Keyboard.p in events(fig).keyboardstate
                #compute bezier curves of current points

                if length(positions.val) == length(data_1)
                    positions_tangents = update_bezier(positions, data_1, data_1_bezy, colors, labels, active, fig, ax, positions_tangents)
                end
            end
                 return Consume(true)

            else event.action == Mouse.press
                    # pushed 
                    i = pick_index(fig, ax, positions, positions_tangents)
                    i_loc[] = i 
                    
                    xy = vec(mouseposition(ax))
                    dist_p = compute_dist_points(positions, xy)
                    dist_b = compute_dist_bezy(positions_tangents, xy)

                    if minimum(dist_p) < minimum(dist_b)
                        pos_selected[] = positions[][i_loc[]]
                        notify(positions)
                    else    
                        pos_selected[] = positions_tangents[][i_loc[]]
                        notify(positions_tangents)
                    end
                    notify(pos_selected)
                    return Consume(true)
                end
                    return Consume(false)
            end

            on(events(fig).mousebutton, priority = 3) do event
                if event.action == Mouse.release
                # if length(data_1_bezy) > length(positions.val)
                    update_plots(data, positions, pos_selected, data_1, fig, ax, active, actives, colors, labels, hide)
                    positions_tangents = update_bezier(positions, data_1, data_1_bezy, colors, labels, active, fig, ax, positions_tangents)
                # end
                end
            return Consume(false)
            end


    colors = [RGBf(rand(3)...)]
    labels = ["1"]
    # plot as line & scatter with markers
    lin = lines!(ax,positions, color=colors[active], label = labels[1])
    dots = scatter!(ax,positions, color=colors[active], label = labels[1])
    marker = scatter!(ax, pos_selected, color=:red, markersize=20, marker = '□', label = labels[1])
    legend = Legend(fig[1,2], ax, "lines", merge = true, label=labels)

    display(fig)
    return data_1, positions, pos_selected, ax.scene, data, data_bezy, data_1_bezy, positions_tangents
end

# distance of point xy to the points listed in "positions"
compute_dist_points(positions, xy) = [sqrt(( xy[1] - positions[][i][1])^2 + ( xy[2] - positions[][i][2])^2) for i=1:length(positions[])]
compute_dist_bezy(positions_tangents, xy) = [sqrt((xy[1] - positions_tangents[][i][1])^2 + (xy[2] - positions_tangents[][i][2])^2) for i=1:length(positions_tangents[])]
function euclidean_distance(p1, p2)
    return sqrt((p1[1] - p2[1])^2 + (p1[2] - p2[2])^2)
end

function pick_index(fig, ax, positions, positions_tangents)
    # This picks the closest index within "positions" to the point pushed
    # Note: ideally we should also determine whether we are clicking on a plot.
    # That is what "pick" does; yet it does not work in combination with WGLMakie (required for buttons and so on)

    xy = vec(mouseposition(ax))
    dist_p = compute_dist_points(positions, xy)
    dist_b = compute_dist_bezy(positions_tangents, xy)
    min_dist_points = minimum(dist_p)
    min_dist_bezy = minimum(dist_b)

    if min_dist_points < min_dist_bezy
        ind = argmin(dist_p)
    else    
        ind = argmin(dist_b)
    end
        return ind
end


# This determines if a point is on a polygon or not
# This routine is taken from the PolygonInBounds package 
function compute_on_polygon(positions, xy, tol=1e-2) 
    veps = tol
    vepsx = vepsy = veps
    nedg = length(positions[])-1
    on_curve = false  
    bound_ind = 1;
    for epos = 1:nedg
        i = epos
        j = epos+1
        xone = positions[][i][1]
        yone = positions[][i][2]
        xtwo = positions[][j][1]
        ytwo = positions[][j][2]
        xmin0 = min(xone, xtwo)
        xmax0 = max(xone, xtwo)
        xmin = xmin0 - vepsx
        xmax = xmax0 + vepsx
        ymin = yone - vepsy
        ymax = ytwo + vepsy
        ydel = ytwo - yone
        xdel = xtwo - xone
        xysq = xdel^2 + ydel^2
        feps = sqrt(xysq) * veps

        xpos = xy[1]
        ypos = xy[2]
        if xpos >= xmin
            if xpos <= xmax
                #--------- inside extended bounding box of edge
                mul1 = ydel * (xpos - xone)
                mul2 = xdel * (ypos - yone)
                if abs(mul2 - mul1) <= feps
                    #------- distance from line through edge less veps
                    mul3 = xdel * (2xpos-xone-xtwo) + ydel * (2ypos-yone-ytwo)
                    if abs(mul3) <= xysq ||
                        hypot(xpos- xone, ypos - yone) <= veps ||
                        hypot(xpos- xtwo, ypos - ytwo) <= veps
                       
                        # yes, we are on the boundary; store index as well
                        on_curve = true  
                        bound_ind = epos;

                    end
                end
            end
        end
    end

    return on_curve, bound_ind
end

# #plotting function to retain plotting order when switching between plots and moving beziers
function update_plots(data, positions, pos_selected, data_1, fig, ax, active, actives, colors, labels, hide)

    #delete all plots and replot
    for i in 1:length(ax.scene.plots)
        ax.scene.plots[i].attributes[:visible]= false
    end
    deleteat!(ax.scene.plots, 1:length(ax.scene.plots))

    #make sure the active plot is the last one in the list
    if length(actives) < length(data)
        push!(actives, active)
    else
        push!(actives, active)
        deleteat!(actives, 1)
    end

    if hide == false
        if active > 1 && active < length(data)
            for i in 1:(active-1)
                lines!(ax, data[i], color = colors[i], label = labels[i])
                scatter!(ax, data[i], color = colors[i], label =  labels[i])
            end
            for i in (active+1):length(data)
                lines!(ax, data[i], color = colors[i], label = labels[i])
                scatter!(ax, data[i], color = colors[i], label =  labels[i])
            end
        elseif active == 1
            for i in 2:length(data)
                lines!(ax, data[i], color = colors[i], label = labels[i])
                scatter!(ax, data[i], color = colors[i], label =  labels[i])
            end
        elseif active == length(data)
            for i in 1:(length(data)-1)
                lines!(ax, data[i], color = colors[i], label = labels[i])
                scatter!(ax, data[i], color = colors[i], label =  labels[i])  
            end
        end
    end

    #delete last legend
    # plot active data as line & scatter with markers
    lin = lines!(ax,positions, color=colors[active], label = labels[active])
    dots = scatter!(ax,positions, color=colors[active], label = labels[active])
    marker = scatter!(ax, pos_selected, color=:red, markersize=20, marker = '□', label = labels[active])
    legend = Legend(fig[1,2], ax, "lines", merge = true, label=labels)
 
    return 
end

function update_bezier(positions, data_1, data_1_bezy, colors, labels, active, fig,  ax, positions_tangents)

    data_1_bezy = positions_tangents[]

    bezy_points = ntuple(j -> [0.0, 0.0], length(data_1))::NTuple{length(data_1), Vector{Float64}}
    bezy_tangents = ntuple(j -> [0.0, 0.0], length(data_1))::NTuple{length(data_1), Vector{Float64}}

    for i in 1:length(data_1)
        bezy_points[i] .= [data_1[i][1], data_1[i][2]]
        bezy_tangents[i] .= [data_1_bezy[i][1] - data_1[i][1], data_1_bezy[i][2] - data_1[i][2]]        #create tangents from the position of tangent points
    end
    
    # deleteat!(ax.scene.plots, 1:length(ax.scene.plots))
    
    bezy = BezierPoly(bezy_points, bezy_tangents)
    pts = compute_curve(bezy)
    lines!(ax, pts[1], pts[2], color=colors[active])
    
    data_1_bezy = Point2.(zeros(length(data_1)-1,2))

    for i=1:size(bezy.x,1)
        for j=1:2
            if j==1
                f = 1
            else
                f = -1;
            end
        
            xv = [bezy.x[i,j], bezy.x[i,j] + f*bezy.tx[i,j]]
            yv = [bezy.y[i,j], bezy.y[i,j] + f*bezy.ty[i,j]]   

            if f == 1
                data_1_bezy[i] = Point2.(xv[2], yv[2])
            end

            lines!(ax, xv, yv, color=:red)
            scatter!(ax, xv, yv, color=:red)
            display(fig)
        end 
    end

    
    positions_tangents = Observable(data_1_bezy)
    scatter!(ax, data_1_bezy[:], color=:red)

            return positions_tangents
end

# Plot data points 
data = [rand(10,2)];
data[1][:,1] = 1:10

a,b,c,d,e,g,h,i = plot_data(data; hide=true) # plot

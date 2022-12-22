# First example of how to pick data on a plot and create a polygon.
# Keyboard shortcuts:
#   a - add new points (at the end or inbetween, depending where you click)
#   d - delete points
#   m - merge points (aka: put them on top of each other)
#   b - breakup points

using WGLMakie

Makie.inline!(true)

function plot_data(data; res=(1920,1080))
    fig = Figure(resolution = res);
    ax = fig[1,1] = Axis(fig);


    # define the data & the index of the point currently modified to be an observable
    data_1 = Point2.(data[:,1],data[:,2])
    positions = Observable(data_1)
    pos_selected = Observable(data_1[1])
    i_loc   = Observable(1);
    i_merge = Observable(0);

    # update location of point
    on(events(ax.scene).mouseposition, priority = 2) do _
        if ispressed(ax.scene, Mouse.left) #& Keyboard.m in events(fig).keyboardstate
          
            positions[][i_loc[]] = mouseposition(ax.scene)
            
            pos_selected[] = positions[][i_loc[]]
            notify(pos_selected)
            notify(positions)
            return Consume(true)    # this would block rectangle zoom
        end
        return Consume(false)
    end

    
    on(events(fig).mousebutton, priority = 2) do event
        if event.button == Mouse.left && event.action == Mouse.press
            if Keyboard.d in events(fig).keyboardstate
                # Delete marker
                # we push "d" on keyboard and click on plot
                
                i = pick_index(fig, ax, positions)

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
                else
                    # 2) Otherwise add new point @ end of list
                    push!(positions[], mouseposition(ax))
                    i_loc[] = length(positions[])
                end
                
                pos_selected[] = positions[][i_loc[]]

                notify(positions)
                notify(pos_selected)
                return Consume(true)

            elseif Keyboard.m in events(fig).keyboardstate
                # merge markers to close a polygon.
                # push "m" and click first point; next click second point

                i = pick_index(fig, ax, positions)
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
                
                i = pick_index(fig, ax, positions)
                
                push!(positions[], positions[][end])    # add end point
                positions[][i+1:end] =  positions[][i:end-1] # move existing positions
                positions[][i] =  positions[][i+1] # add new point

               
                pos_selected[] = positions[][i]
                notify(pos_selected)
                notify(positions)
                return Consume(true)

            else 
                # pushed 
                i = pick_index(fig, ax, positions)
                i_loc[] = i 
                
                pos_selected[] = positions[][i_loc[]]
                notify(pos_selected)
                notify(positions)
                return Consume(true)
                #end
            end
        end
        return Consume(false)
    end
    
    # plot as line & with markers
    l = lines!(ax,positions)
    p = scatter!(ax,positions)
    pt = scatter!(ax, pos_selected, color=:red, markersize=20, marker = '□')

    display(fig);
end


# distance of point xy to the points listed in "positions"
compute_dist_points(positions, xy) = [sqrt(sum(positions[][i] .- xy).^2) for i=1:length(positions[])]

function pick_index(fig, ax, positions)
    # This picks the closest index within "positions" to the point pushed

    # Note: ideally we should also determine whether we are clicking on a plot.
    # That is what "pick" does; yet it does not work in combination with WGLMakie (required for buttons and so on)

    xy = mouseposition(ax)
    dist = compute_dist_points(positions, xy)
    min_dist_points = minimum(dist)
    ind = argmin(dist)

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

# Plot data points 
data = rand(10,2);
data[:,1] = 1:10
plot_data(data) # plot

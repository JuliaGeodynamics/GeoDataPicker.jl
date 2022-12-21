# First example of how to pick data on a plot 
using WGLMakie

Makie.inline!(true)

function plot_data(data)
    fig = Figure(resolution = (1920,1080));
    ax = fig[1,1] = Axis(fig);


    # define the data & the index of the point currently modified to be an observable
    data_1 = Point2.(data[:,1],data[:,2])
    positions = Observable(data_1)
    i_loc = Observable(1);

    # update location of point
    on(events(ax.scene).mouseposition, priority = 2) do _
        if ispressed(ax.scene, Mouse.left) #& Keyboard.m in events(fig).keyboardstate
            # In case we push "m" the keyboard 
            positions[][i_loc[]] = mouseposition(ax.scene)
            notify(positions)
            return Consume(true)    # this would block rectangle zoom
        end
        return Consume(false)
    end

    
    on(events(fig).mousebutton, priority = 2) do event
        if event.button == Mouse.left && event.action == Mouse.press
            if Keyboard.d in events(fig).keyboardstate
                # we push "d" on keyboard and click on plot
                
                # Delete marker
                i = pick_index(fig, ax, positions)

                deleteat!(positions[], i)
                notify(positions)
                return Consume(true)
            elseif Keyboard.a in events(fig).keyboardstate
                # 1) Check if we are close to the existing curve

                on_bound, ind_bound = compute_on_polygon(positions, mouseposition(ax)) 
                insert = ind_bound+1
                if on_bound
                    # We are 
                    push!(positions[], positions[][end])    # add end point

                    positions[][insert+1:end] =  positions[][insert:end-1] # move existing positions
                    positions[][insert] =  mouseposition(ax) # add new point

                else
                    # 2) Otherwise add new point @ end of list
                    push!(positions[], mouseposition(ax))
                    i_loc[] = length(positions[])
                end

                notify(positions)
                return Consume(true)

            else #if Keyboard.m in events(fig).keyboardstate
                # pushed 
                i = pick_index(fig, ax, positions)
                i_loc[] = i 

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

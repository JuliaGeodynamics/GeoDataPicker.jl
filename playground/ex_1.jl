# First example of how to pick data on a plot 
using GLMakie


function plot_data(data)
    fig = Figure(resolution = (1920,1080));
    ax = fig[1,1] = Axis(fig);


    # define the data & the index of the point currently modified to be an observable
    data_1 = Point2.(data[:,1],data[:,2])
    positions = Observable(data_1)
    i_loc = Observable(1);

    # update location of point
    on(events(ax.scene).mouseposition, priority = 2) do _
        if ispressed(ax.scene, Mouse.left)
            positions[][i_loc[]] = mouseposition(ax.scene)
            notify(positions)
            return Consume(true)    # this would block rectangle zoom
        end
        return Consume(false)
    end

    
    on(events(fig).mousebutton, priority = 2) do event
        if event.button == Mouse.left && event.action == Mouse.press
            if Keyboard.d in events(fig).keyboardstate
                # Delete marker
                plt, i = pick(fig)
                if plt == p
                    deleteat!(positions[], i)
                    notify(positions)
                    return Consume(true)
                end
            elseif Keyboard.a in events(fig).keyboardstate
                # Add new point @ end of list
                push!(positions[], mouseposition(ax))
                i_loc[] = length(positions[])
                notify(positions)
                return Consume(true)
            else 
                # pushed 
                plt, i = pick(fig)
                if plt == p
                    i_loc[] = i 
                   # positions[][i_loc[]] = mouseposition(ax)
                    notify(positions)
                    return Consume(true)
                end
            end
        end
        return Consume(false)
    end
    
    # plot as line & with markers
    l = lines!(ax,positions)
    p = scatter!(ax,positions)

    display(fig);
end


data = rand(10,2);
data[:,1] = 1:10
plot_data(data)

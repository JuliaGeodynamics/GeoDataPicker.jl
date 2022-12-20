# First example of how to pick data on a plot 
using GLMakie


function plot_data(data)
    fig = Figure(resolution = (1920,1080));
    ax = fig[1,1] = Axis(fig);

    data = Point2f.(data[:,1],data[:,2])
    positions = Observable(data)

    on(events(fig).mousebutton, priority = 2) do event
        if event.button == Mouse.left && event.action == Mouse.press
            if Keyboard.d in events(fig).keyboardstate
                # Delete marker
                plt, i = pick(fig)
                #@show p  p[1]  plt
                if plt == p
                    deleteat!(positions[], i)
                    notify(positions)
                    return Consume(true)
                end
            elseif Keyboard.a in events(fig).keyboardstate
                # Add marker
                push!(positions[], mouseposition(ax))
                notify(positions)
                return Consume(true)
            elseif Keyboard.m in events(fig).keyboardstate
                # Move marker
                # NOT YET WORKING
                plt, i = pick(fig)
                #@show i positions
                if plt == p
                    positions[i] = Point2f(mouseposition(ax))

                    #push!(positions[], mouseposition(ax))
                    notify(positions)
                    return Consume(true)
                end
            end
        end
        return Consume(false)
    end

    l = lines!(ax,positions)
    p = scatter!(ax,positions)
   
    display(fig);
end


data = rand(10,2);
data[:,1] = 1:10
plot_data(data)

#=
t = text!(ax, " ", position = first(p[1][]), visible = false, halign = :left)

on(events(fig.scene).mouseposition) do mp
    plt, idx = mouse_selection(fig.scene)
    if plt == p && idx != nothing
        t.position = p[1][][idx]
        t[1] = string(p[1][][idx])
        t.visible = true
    else
        t.visible = false
    end
end
=#

#fig


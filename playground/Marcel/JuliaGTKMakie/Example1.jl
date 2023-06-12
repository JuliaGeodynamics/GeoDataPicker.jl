using GLMakie

# initialize figure
fig = Figure(resolution=(1500,1000),font = "Helvetica Bold",fontsize = 24)

# basic layout: data and pick management on the left slider
data_grid       = fig[1, 1] = GridLayout(tellheight=true,tellwidth=true,valign=:top)
pick_grid       = fig[2, 1] = GridLayout(tellheight=true,tellwidth=true,valign=:top)
limits_grid     = fig[3, 1] = GridLayout(tellheight=true,tellwidth=true)


plot_grid       = fig[1:3,2:4] = GridLayout(tellheight=true,tellwidth=true)
volume1_grid    = fig[4,1] = GridLayout(tellheight=true,tellwidth=true,valign=:top)
volume2_grid    = fig[4,2] = GridLayout(tellheight=true,tellwidth=true,valign=:top)
surface_grid    = fig[4,3] = GridLayout(tellheight=true,tellwidth=true,valign=:top)
point_grid      = fig[4,4] = GridLayout(tellheight=true,tellwidth=true,valign=:top)

# for a nicer look: boxes around the different panels ? 
#Box(fig[1,1])
datatitle = Label(data_grid[1, 1], "Data", font="Helvetiva Bold",textsize = 30, halign=:left)

# buttons for data management
buttonlabels_data = ["load";"clear";"save settings";"snapshot"]
#buttongrid_data = data_grid[1:2, 1] = GridLayout(tellwidth = true,tellheight=true)
buttons_data = data_grid[2:3, 1:2] = [Button(fig, label = l,width=150) for l in buttonlabels_data]
rowgap!(data_grid, 5)


# buttons for pick management
picktitle = Label(pick_grid[1, 1],"Picking" ,font="Helvetiva Bold",textsize = 30, halign=:left)
buttonlabels_pick = ["start";"stop";"continue";"correct";"save";"load";"compare";"clear"]
#buttongrid_pick = pick_grid[2:4, 1] = GridLayout()
buttons_pick = pick_grid[2:5, 1:2] = [Button(fig, label = l,width=150,cornerradius=10) for l in buttonlabels_pick]
rowgap!(pick_grid, 5)

# plotting window
ax1 = Axis(plot_grid[1, 1], aspect=DataAspect())
ax2 = Axis(plot_grid[1, 1], aspect=DataAspect(), backgroundcolor = :transparent)
ax3 = Axis(plot_grid[1, 1], aspect=DataAspect(), backgroundcolor = :transparent)

# remove ticks and axes from ax2 and ax3
hidespines!(ax2)
hidexdecorations!(ax2)
hidespines!(ax3)
hidexdecorations!(ax3)

# link all axes so that they have the same limits
linkyaxes!(ax1, ax2, ax3)
linkxaxes!(ax1, ax2, ax3)

# test:set limits for ax1
limits!(ax1,0,20,30,40)

heatmap!(ax1,rand(51,51))
heatmap!(ax2,rand(51,51), colormap=(:balance,0.5))

# volume/tomography plotting - base image
#-------------------------------------------
vol1title = Label(volume1_grid[1, 1], "Tomographies", font="Helvetiva Bold",textsize = 30, halign=:left)
tog_vol1 = Toggle(volume1_grid[1,3],active = true, framecolor_inactive = RGBf(0.94, 0.94, 0.94))
menu = Menu(volume1_grid[2,1:3],options = ["A", "B", "C"], halign=:left)

# add limit textboxes and a button to set these
Textbox(volume1_grid[4, 1], placeholder = "lonmin",width=100)
Textbox(volume1_grid[3, 2], placeholder = "latmax",width=100)
Textbox(volume1_grid[4, 3], placeholder = "lonmax",width=100)
Textbox(volume1_grid[5, 2], placeholder = "latmin",width=100)
Button(volume1_grid[4,2],label="Set Limits",width=100)

# add clim textboxes
Textbox(volume1_grid[6, 1], placeholder = "cmin",width=100)
Textbox(volume1_grid[6, 2], placeholder = "cmax",width=100)
Button(volume1_grid[6,3],label="clim",width=100)

# add colormap menu
Label(volume1_grid[7,1],"colormap")
Menu(volume1_grid[7,2:3], options = ["viridis", "heat", "blues"], default = "blues")

rowgap!(volume1_grid, 5)
colgap!(volume1_grid, 5)

# volume/tomography plotting - overlay image
#-----------------------------------------------
vol2title = Label(volume2_grid[1, 1], "Tomographies 2", font="Helvetiva Bold",textsize = 30, halign=:left)
tog_vol2= Toggle(volume2_grid[1,3],active = true, framecolor_inactive = RGBf(0.94, 0.94, 0.94))
menu = Menu(volume2_grid[2,1:3],options = ["A", "B", "C"], halign=:left)

# add limit textboxes and a button to set these
Textbox(volume2_grid[4, 1], placeholder = "lonmin",width=100)
Textbox(volume2_grid[3, 2], placeholder = "latmax",width=100)
Textbox(volume2_grid[4, 3], placeholder = "lonmax",width=100)
Textbox(volume2_grid[5, 2], placeholder = "latmin",width=100)
Button(volume2_grid[4,2],label="Set Limits",width=100)

# add clim textboxes
Textbox(volume2_grid[6, 1], placeholder = "cmin",width=100)
Textbox(volume2_grid[6, 2], placeholder = "cmax",width=100)
Button(volume2_grid[6,3],label="clim",width=100)

# add colormap menu
Label(volume2_grid[7,1],"colormap")
Menu(volume2_grid[7,2:3], options = ["viridis", "heat", "blues"], default = "blues")

rowgap!(volume2_grid, 5)
colgap!(volume2_grid, 5)





# moho/surface data
surftitle = Label(surface_grid[1, 1:3], "Interfaces", font="Helvetiva Bold",textsize = 30, halign=:left)

# 
surfdata = ["Data1";"Data2";"Data3"]

surftoggles = [Toggle(surface_grid[i+1,1], active = true) for i in 1:length(surfdata)]
surflabels  = [Label(surface_grid[i+1,2:3], surfdata[i]) for i in 1:length(surfdata)]

rowgap!(surface_grid, 5)
colgap!(surface_grid, 5)

# point data
pointtitle = Label(point_grid[1, 1:3], "Point Data", font="Helvetiva Bold",textsize = 30, halign=:left)

tog_vsurf1 = Toggle(point_grid[2,1],active = true, framecolor_inactive = RGBf(0.94, 0.94, 0.94))
Label(point_grid[2,2:3],"PointData1")



# initialize interval slider for color Axis
#clim_ax1 = IntervalSlider(range = LinRange(0, 1, 1000),
#    startvalues = (0.2, 0.8))


# initialize dropdown menu for overlay plotting
#menu2 = Menu(fig,options = ["A", "B", "C"])
# initialize toggle for overlay plotting

#Textbox(f[1, 1], placeholder = "Enter a string...")


# tb = Textbox(f[2, 1], placeholder = "Enter a frequency",
#    validator = Float64, tellwidth = false)

# frequency = Observable(1.0)

#on(tb.stored_string) do s
#    frequency[] = parse(Float64, s)
#end



# colormap=(“viridis”,0.5)





# put dropdown menus in their own box
#Box(fig[3,1],title="tomographies")

#fig[3, 1:3] = hgrid!(
#    Label(fig, "Dataset", width = nothing),
#    menu,
#    Label(fig, "Function", width = nothing),
#    menu2;
#    tellheight = true
#    )




#menu.is_open = false
#menu2.is_open = false


fig
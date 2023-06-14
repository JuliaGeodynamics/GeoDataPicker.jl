using GLMakie, JLD2,GeophysicalModelGenerator, ColorSchemes, Unitful

# include funcitons for profile processing
include("../playground/Marcel/JuliaGTKMakie/ProfileProcessing.jl")

# define global variables, otherwise we don't have them handy when needed
global pdata, vol1_field, vol2_field, vol1_colmap


# initialize figure
fig = Figure(resolution=(2500,1500),font = "Helvetica Bold",fontsize = 28)

#---------------------------------------------------
# LAYOUT
#---------------------------------------------------

# basic layout: data and pick management on the left slider
data_grid       = fig[1, 1] = GridLayout(tellheight=true,tellwidth=true,valign=:top)
pick_grid       = fig[2, 1] = GridLayout(tellheight=true,tellwidth=true,valign=:top)
reserve_grid    = fig[3, 1] = GridLayout(tellheight=true,tellwidth=true)


plot_grid       = fig[1:3,2:4] = GridLayout(tellheight=true,tellwidth=true)
volume1_grid    = fig[4,1] = GridLayout(tellheight=true,tellwidth=true,valign=:top)
volume2_grid    = fig[4,2] = GridLayout(tellheight=true,tellwidth=true,valign=:top)
surface_grid    = fig[4,3] = GridLayout(tellheight=true,tellwidth=true,valign=:top)
point_grid      = fig[4,4] = GridLayout(tellheight=true,tellwidth=true,valign=:top)

# for a nicer look: boxes around the different panels ? 
#Box(fig[1,1])

# data management
#---------------------------------------------------
datatitle = Label(data_grid[1, 1], "Data", font="Helvetiva Bold",fontsize = 30, halign=:left)

# data management
tBox_loaddata   = Textbox(data_grid[2, 1:2], placeholder = "loadfile",width=250)
button_loaddata = Button(data_grid[2,3] ,label = "load data",width=150)

Textbox(data_grid[3, 1:2], placeholder = "savefile",width=250)
Button(data_grid[3,3] ,label = "save settings",width=150)
Textbox(data_grid[4, 1:2], placeholder = "savefile",width=250)
Button(data_grid[4,3] ,label = "snapshot",width=150)
Button(data_grid[5,3] ,label = "clear",width=150)

rowgap!(data_grid, 5)
colgap!(data_grid, 5)

# pick management
#---------------------------------------------------
picktitle = Label(pick_grid[1, 1],"Picking" ,font="Helvetiva Bold",fontsize = 30, halign=:left)
buttonlabels_pick = ["start";"stop";"continue";"correct";"save";"load";"compare";"clear"]
#buttongrid_pick = pick_grid[2:4, 1] = GridLayout()
buttons_pick = pick_grid[2:5, 1:2] = [Button(fig, label = l,width=150,cornerradius=10) for l in buttonlabels_pick]
rowgap!(pick_grid, 5)

# plotting window
#---------------------------------------------------
ax1 = Axis(plot_grid[1:2, 1], aspect=DataAspect(), backgroundcolor = :transparent)
ax2 = Axis(plot_grid[1:2, 1], aspect=DataAspect(), backgroundcolor = :transparent)
ax3 = Axis(plot_grid[1:2, 1], aspect=DataAspect(), backgroundcolor = :transparent)

# remove ticks and axes from ax2 and ax3
hidespines!(ax2)
hidexdecorations!(ax2)
hidespines!(ax3)
hidexdecorations!(ax3)

# link all axes so that they have the same limits
linkyaxes!(ax1, ax2, ax3)
linkxaxes!(ax1, ax2, ax3)

rowgap!(plot_grid, 50)
colgap!(plot_grid, 10)

# volume/tomography plotting - base image
#-------------------------------------------
vol1title = Label(volume1_grid[1, 1], "Tomographies", font="Helvetiva Bold",fontsize = 30, halign=:left)
tog_vol1 = Toggle(volume1_grid[1,3],active = true, framecolor_inactive = RGBf(0.94, 0.94, 0.94))
menu_vol1 = Menu(volume1_grid[2,1:3],options = ["A", "B", "C"], halign=:left)

# add limit textboxes and a button to set these
vol1_xmin = Textbox(volume1_grid[4, 1], placeholder = "xmin",width=100)
vol1_zmax = Textbox(volume1_grid[3, 2], placeholder = "zmax",width=100)
vol1_xmax = Textbox(volume1_grid[4, 3], placeholder = "xmax",width=100)
vol1_zmin = Textbox(volume1_grid[5, 2], placeholder = "zmin",width=100)
vol1_setlim = Button(volume1_grid[4,2],label="Set",width=100)

# add clim textboxes and button
vol1_cmin = Textbox(volume1_grid[6, 1], placeholder = "cmin",width=100)
vol1_cmax = Textbox(volume1_grid[6, 2], placeholder = "cmax",width=100)
vol1_clim = Button(volume1_grid[6,3],label="clim",width=100)

# add colormap menu
Label(volume1_grid[7,1],"colormap")
vol1_colmenu = Menu(volume1_grid[7,2:3], options = ["lapaz";"cork";"grayC";"roma";"vik";"bwr";"coolwarm";"plasma";"inferno";"viridis";"balance";"seismic"], default = "vik")

# add toggle for flipped colormap
#Label(volume1_grid[8,1:2],"flip colormap")
#tog_flipvol1 = Toggle(volume1_grid[8,3],active = false, framecolor_inactive = RGBf(0.94, 0.94, 0.94))
vol1_colflip = Observable(false)
tog_flipvol1 = Button(volume1_grid[8,2:3], label = @lift($vol1_colflip ? "flipped" : "not flipped"))

rowgap!(volume1_grid, 5)
colgap!(volume1_grid, 5)

# volume/tomography plotting - overlay image
#-----------------------------------------------
vol2title = Label(volume2_grid[1, 1], "Tomographies 2", font="Helvetiva Bold",fontsize = 30, halign=:left)
tog_vol2= Toggle(volume2_grid[1,3],active = false, framecolor_inactive = RGBf(0.94, 0.94, 0.94))
menu_vol2 = Menu(volume2_grid[2,1:3],options = ["A", "B", "C"], halign=:left)

# add limit textboxes and a button to set these
vol2_xmin = Textbox(volume2_grid[4, 1], placeholder = "xmin",width=100)
vol2_zmax = Textbox(volume2_grid[3, 2], placeholder = "zmax",width=100)
vol2_xmax = Textbox(volume2_grid[4, 3], placeholder = "xmax",width=100)
vol2_zmin = Textbox(volume2_grid[5, 2], placeholder = "zmin",width=100)
vol2_setlim = Button(volume2_grid[4,2],label="Set",width=100)

# add clim textboxes and button
vol2_cmin = Textbox(volume2_grid[6, 1], placeholder = "cmin",width=100)
vol2_cmax = Textbox(volume2_grid[6, 2], placeholder = "cmax",width=100)
vol2_clim = Button(volume2_grid[6,3],label="clim",width=100)

# add colormap menu
Label(volume2_grid[7,1],"colormap")
vol2_colmenu = Menu(volume2_grid[7,2:3], options = ["lapaz";"cork";"grayC";"roma";"vik";"bwr";"coolwarm";"plasma";"inferno";"viridis";"balance";"seismic"], default = "vik")

# button to flip the colormap
vol2_colflip = Observable(false)
tog_flipvol2 = Button(volume2_grid[8,2:3], label = @lift($vol2_colflip ? "flipped" : "not flipped"))

# add opacity slider
Label(volume2_grid[9,1],"opacity")
#vol2_slopac = Slider(volume2_grid[9, 2:3], range = 0.01:0.01:1, startvalue = 1)

rowgap!(volume2_grid, 5)
colgap!(volume2_grid, 5)

# moho/surface data
#---------------------------------------------------
surftitle = Label(surface_grid[1, 1:3], "Interfaces", font="Helvetiva Bold",fontsize = 30, halign=:left)

rowgap!(surface_grid, 5)
colgap!(surface_grid, 5)

# point data
#---------------------------------------------------
pointtitle = Label(point_grid[1, 1:3], "Point Data", font="Helvetiva Bold",fontsize = 30, halign=:left)

rowgap!(point_grid, 5)
colgap!(point_grid, 5)



#---------------------------------------------------
# FUNCTIONALITY
#---------------------------------------------------

# load button clicked - lots of stuff going on, populate menus and plot the data
#--------------------------------------------------------
on(button_loaddata.clicks) do n
    # load the data stored in the respective tBox
    global pdata = load(tBox_loaddata.displayed_string.val,"ExtractedData")

    dataset_string = collect(String.(keys(pdata.VolData.fields)));

    # plot the first field in ax1 and ax2 as heatmap
    tmp = keys(pdata.VolData.fields);

    data1 = Observable(pdata.VolData.fields[1]);
    data2 = Observable(pdata.VolData.fields[2]);

    global vol1_field = @lift(dropdims($data1,dims=3));
    global vol2_field = @lift(dropdims($data2,dims=3));

    #vol1_field = dropdims(pdata.VolData.fields[1],dims=3);
    #vol2_field = dropdims(pdata.VolData.fields[2],dims=3);

    vol1_plot = heatmap!(ax1,pdata.VolData.fields.x_profile[:,1],pdata.VolData.depth.val[1,:],vol1_field,colormap=Reverse(:vik));
    vol2_plot = heatmap!(ax2,pdata.VolData.fields.x_profile[:,1],pdata.VolData.depth.val[1,:],vol2_field,colormap=Reverse(:vik));

    # add colorbars
    global vol1_cbar = Colorbar(plot_grid[1, 2], vol1_plot, label = dataset_string[1],width=50)
    global vol2_cbar = Colorbar(plot_grid[2, 2], vol2_plot, label = dataset_string[1],width=50)

    # link the heatmap visibility to the toggles
    connect!(ax1.scene.plots[1].visible, tog_vol1.active)
    connect!(ax2.scene.plots[1].visible, tog_vol2.active)

    # populate the dropdown menus for volume data
    volkeys = keys(pdata.VolData.fields);
    menu_vol1.selection = dataset_string[1];
    menu_vol1.options = dataset_string;
    
    menu_vol2.selection = dataset_string[2];
    menu_vol2.options = dataset_string;

    # the surface/point data in ax3
    #-----------------------------------------------

    # loop through the data and plot only the ones that do not only contain NaNs
    surfdata_txt = [];

    iplotsurf = 1;
    for isurf = 1:length(pdata.SurfData)
        if any(.!(isnan.(pdata.SurfData[isurf].depth.val))) # returns true if there is at least element in the depth vector that does not equal NaN
            lines!(ax3,pdata.SurfData[isurf].fields.x_profile, pdata.SurfData[isurf].depth.val, linewidth=4,color = :white)
            lines!(ax3,pdata.SurfData[isurf].fields.x_profile, pdata.SurfData[isurf].depth.val, linewidth=2,color = :black)
            surfdata_txt = [surfdata_txt;pdata.SurfData[isurf].atts["dataset"]]
            iplotsurf = iplotsurf + 1;
        end
    end

    # take care of the surface data toggles
    surftoggles = [Toggle(surface_grid[i+1,1], active = true) for i in 1:length(surfdata_txt)];
    surflabels  = [Label(surface_grid[i+1,2:3], surfdata_txt[i],halign=:left) for i in 1:length(surfdata_txt)];

    for iplot = 1:length(surfdata_txt)
        connect!(ax3.scene.plots[iplot*2-1].visible, surftoggles[iplot].active)
        connect!(ax3.scene.plots[iplot*2].visible, surftoggles[iplot].active)
    end

    # point data
    pointdata_txt = [];

    xlim = round.(ax3.xaxis.attributes.limits.val);
    ylim = round.(ax3.yaxis.attributes.limits.val);

    iplot = 1;
    for ipoint = 1:length(pdata.PointData)
        if any(.!(isnan.(pdata.PointData[ipoint].depth.val))) # returns true if there is at least element in the depth vector that does not equal NaN
            scatter!(ax3, pdata.PointData[ipoint].fields.x_profile, pdata.PointData[ipoint].depth.val, marker = :circle, markersize = 10, color = :red)
            pointdata_txt = [pointdata_txt;pdata.PointData[ipoint].atts["dataset"]]
            iplot = iplot + 1;
        end
    end

    ax3.limits = (xlim[1],xlim[2],ylim[1],ylim[2]) # reset the axis limits to before point plotting happened

    vol1_xmin.displayed_string = string(ax3.limits.val[1]);
    vol1_xmax.displayed_string = string(ax3.limits.val[2]);
    vol1_zmin.displayed_string = string(ax3.limits.val[3]);
    vol1_zmax.displayed_string = string(ax3.limits.val[4]);

    vol2_xmin.displayed_string = string(ax3.limits.val[1]);
    vol2_xmax.displayed_string = string(ax3.limits.val[2]);
    vol2_zmin.displayed_string = string(ax3.limits.val[3]);
    vol2_zmax.displayed_string = string(ax3.limits.val[4]);

    # take care of the point data toggles
    pointtoggles = [Toggle(point_grid[i+1,1], active = true) for i in 1:length(pointdata_txt)];
    pointlabels  = [Label(point_grid[i+1,2:3], pointdata_txt[i],halign=:left) for i in 1:length(pointdata_txt)];
    
    for iplot = 1:length(pointdata_txt)
        connect!(ax3.scene.plots[2*(iplotsurf-1)+iplot].visible, pointtoggles[iplot].active) # I counted the number of lines that were drawn before, so the added plots are the point plots
    end

end



# changed dataset in volume data 1
on(menu_vol1.selection) do s
    if !isnothing(s)
        if typeof(pdata.VolData.fields[Symbol(s)])==Array{Unitful.Quantity{Float64}, 3}
            tmp = ustrip.(pdata.VolData.fields[Symbol(s)])
            vol1_field[] = dropdims(tmp,dims=3);
        elseif typeof(pdata.VolData.fields[Symbol(s)])==Array{Float64, 3}
            vol1_field[] = dropdims(pdata.VolData.fields[Symbol(s)],dims=3);
        end
        vol1_cbar.label = s;
    else

    end
end

# changed dataset in volume data 2
on(menu_vol2.selection) do s
    if !isnothing(s)
        if typeof(pdata.VolData.fields[Symbol(s)])==Array{Unitful.Quantity{Float64}, 3}
            tmp = ustrip.(pdata.VolData.fields[Symbol(s)])
            vol2_field[] = dropdims(tmp,dims=3);
        elseif typeof(pdata.VolData.fields[Symbol(s)])==Array{Float64, 3}
            vol2_field[] = dropdims(pdata.VolData.fields[Symbol(s)],dims=3);
        end
        vol2_cbar.label = s;
    else

    end
end

# change limits for volume data 1 --> will change all other axis limits as well
on(vol1_setlim.clicks) do n
    ax1.limits = ( parse(Float64,vol1_xmin.displayed_string.val),parse(Float64,vol1_xmax.displayed_string.val), parse(Float64,vol1_zmin.displayed_string.val), parse(Float64,vol1_zmax.displayed_string.val)) # reset the axis limits to before point plotting happened
    vol2_xmin.displayed_string = string(ax1.limits.val[1]);
    vol2_xmax.displayed_string = string(ax1.limits.val[2]); 
    vol2_zmin.displayed_string = string(ax1.limits.val[3]);
    vol2_zmax.displayed_string = string(ax1.limits.val[4]);
end

# change colorbar limits for volume 1 dataset --> test with textboxes
on(vol1_clim.clicks) do n
    ax1.scene.plots[1].colorrange = [parse(Float64,vol1_cmin.displayed_string.val),parse(Float64,vol1_cmax.displayed_string.val)];
end

on(vol2_clim.clicks) do n
    ax2.scene.plots[1].colorrange = [parse(Float64,vol2_cmin.displayed_string.val),parse(Float64,vol2_cmax.displayed_string.val)];
end

# changed colormap for volume data
#----------------------------------
on(vol1_colmenu.selection) do s
    ax1.scene.plots[1].colormap = s
    if(vol1_colflip[])
        ax1.scene.plots[1].colormap = Reverse(colorschemes[Symbol(vol1_colmenu.selection.val)]);
    else
        ax1.scene.plots[1].colormap = (colorschemes[Symbol(vol1_colmenu.selection.val)]);
    end
end

on(vol2_colmenu.selection) do s
    ax2.scene.plots[1].colormap = s
    if(vol2_colflip[])
        ax2.scene.plots[1].colormap = (Reverse(colorschemes[Symbol(vol2_colmenu.selection.val)]));#,vol2_slopac.value.val);
    else
        ax2.scene.plots[1].colormap = ((colorschemes[Symbol(vol2_colmenu.selection.val)]));#,vol2_slopac.value.val);
    end
end

# toggle flipped colormap for volume data
#--------------------------------------------
function colormapvol1_flip()
    vol1_colflip[] = !vol1_colflip[] # switch from flipped to nonflipped and vice versa
    if(vol1_colflip[])
        ax1.scene.plots[1].colormap = (Reverse(Symbol(vol1_colmenu.selection.val)));
    else
        ax1.scene.plots[1].colormap = (Symbol(vol1_colmenu.selection.val));
    end
end

function colormapvol2_flip()
    vol2_colflip[] = !vol2_colflip[] # switch from flipped to nonflipped and vice versa
    if(vol2_colflip[])
        ax2.scene.plots[1].colormap = (Reverse(Symbol(vol2_colmenu.selection.val)));#,vol2_slopac.value.val);
    else
        ax2.scene.plots[1].colormap = (Symbol(vol2_colmenu.selection.val));#,vol2_slopac.value.val);
    end
end

on(tog_flipvol1.clicks) do _
    colormapvol1_flip()
end

on(tog_flipvol2.clicks) do _
    colormapvol2_flip()
end

# volume 2 colormap opacity
#lift(vol2_slopac.value) do x
#    if !isempty(ax2.scene.plots)
#        if(vol2_colflip[])
#            ax2.scene.plots[1].colormap = (Reverse(Symbol(vol2_colmenu.selection.val)),vol2_slopac.value.val);
#        else
#            ax2.scene.plots[1].colormap = (Symbol(vol2_colmenu.selection.val),vol2_slopac.value.val);
#        end
#    end
#end

# volume 2 limit setting via NaN assignment


#on(tog_flipvol1.active) do n
#    ax1.scene.plots[1].colormap = Reverse(colorschemes[Symbol(vol1_colmenu.selection.val)]);
#end

# Reverse(colorschemes[Symbol(vol1_colmenu.selection.val)])

# test:set limits for ax1
#limits!(ax1,0,20,30,40)

#heatmap!(ax1,rand(51,51))
#heatmap!(ax2,rand(51,51), colormap=(:balance,0.5))

#Colorbar(fig[2, 1], limits = (0, 10), colormap = :viridis,
#    vertical = false)
#Colorbar(fig[3, 1], limits = (0, 5), size = 25,
#    colormap = cgrad(:Spectral, 5, categorical = true), vertical = false)
#Colorbar(fig[4, 1], limits = (-1, 1), colormap = :heat,
#    label = "Temperature", vertical = false, flipaxis = false,
#    highclip = :cyan, lowclip = :red)

#ax1.scene.plots[1].colormap.val = (:plasma, 0.5);
#notify(ax1.scene.plots[1].colormap)

fig
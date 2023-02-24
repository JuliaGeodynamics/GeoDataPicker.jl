using GLMakie, ColorSchemes, JLD2, GeophysicalModelGenerator, Interpolations, LinearAlgebra, GeoMakie


# this GUI displays 3D data in LonLat format
# vertical and horizontal crosssections can be displayed
# a toggle selectes either vertical or horizontal crossection
# the postion of the vertical crossection can be selected in the Topograpgy plot in the upper right corner 
# --> press "v" and then left mouseclick to select the startpoint of the cross section and "b" + left mouseclick for the End point (first press the key, then to the mouseclick while the key is still pressed!)
# the depth of the horizontal crosssection is changed by pressing "h" and "up arrow" key or "down arrow" key,respectively


# this functions ouptuts all the information needed to plot a crosssection (LonLat values of Crossection, interpolated data, Topography)
function PrepCrossSection(lonvec, latvec, depths,liftlons,liftlone,liftlats,liftlate,data,lonT,latT,dataTopo)

    lons     = lonvec[1]
    lone     = lonvec[end]
    lats     = latvec[1]
    late     = latvec[end]
    zs       = depths[1]
    ze       = depths[end]

    # create crosssection
    n      = 100
    X,Y,Z  = XYZGrid(LinRange(lons, lone, n), LinRange(lats, late, n), LinRange(ze, zs, n));
    cross  = GeoData(X, Y, Z, (ran = zeros(size(Z)),));

    STup   = @lift ($liftlons,$liftlats)
    ETup   = @lift ($liftlone,$liftlate)

    surf   = @lift CrossSection(cross, Start = $STup, End = $ETup,Interpolate=true)
    t1     = @lift NumValue($surf.lon);   t1 = @lift $t1[:,:,1];
    t2     = @lift NumValue($surf.lat);   t2 = @lift $t2[:,:,1];
    t3     = @lift NumValue($surf.depth); t3 = @lift $t3[:,:,1];

    # add interpolation
    # create interpolation object
    interpol    = @lift LinearInterpolation((lonvec,latvec,depths),$data ,extrapolation_bc = Flat());
    dataSurf    = @lift $interpol.($t1,$t2,$t3)
    dataSurf    = @lift $dataSurf[:,:,1]

    ## get topography
    interpolTopo    = LinearInterpolation((lonT,latT),dataTopo,extrapolation_bc = Flat());
    dataTopo        = @lift interpolTopo.($t1,$t2)
    multi           = 40
    SeaLevel            = 200       # "SeaLevel"
    TopoLine        = @lift $dataTopo[:,1,1] .* multi .+ SeaLevel

    ind             = @lift findall($TopoLine .<= SeaLevel)
    SeaLine         = @lift copy($TopoLine)
    @lift $SeaLine[$ind] .= SeaLevel

    dataSurf = @lift reverse($dataSurf,dims=2)

    return surf,dataSurf,TopoLine,SeaLine,SeaLevel
end

# computes Distance between two LonLat points in km
function DistLonLat(lon1,lat1,lon2,lat2)

    r = 6371
    p = pi/180
    a = 0.5 - cosd((lat2-lat1)*p)/2 + cosd(lat1*p) *cosd(lat2*p) * (1-cosd((lon2-lon1)*p))/2
    d = 2*r * asind(sqrt(a))
    return d
end

## first load GeoData
#Underworld    = load("playground/Data/Dataset_Underworld_Spherical.jld2","Dataset_Underworld") # (data from https://www.atlas-of-the-underworld.org/ processes with GeophysicalModelGenerator)
#Lon,Lat,Depth = coordinate_grids(Underworld);
#lonD          = unique(Lon);
#latD          = unique(Lat);
#depthD        = unique(Depth);
#dVp           = Underworld.fields.dVp;

############################################################
# !!!!make sure that all the data is in increasing order!!!!
############################################################
Dataset        = load("playground/Data/Paffrath_Pwave.jld2","Data_set_Paffrath2021_Vp") # (data from https://www.atlas-of-the-underworld.org/ processes with GeophysicalModelGenerator)
Lon,Lat,Depth  = coordinate_grids(Dataset)
lonD           = unique(Lon)
latD           = unique(Lat)
depthD         = reverse(unique(Depth))
dVp_Percentage = reverse(Dataset.fields.dVp_Percentage)
Vp             = reverse(Dataset.fields.Vp)
Resolution     = reverse(Dataset.fields.Resolution)
Dataset        = GeoData(Lon, Lat, Depth, (dVp_Percentage=dVp_Percentage,Vp=Vp,Resolution=Resolution,))


## load Topo
#Topo          = load("playground/Data/EUCrust07.jld2","data_Topo");
Topo          = load("playground/Data/Paffrath_Topo.jld2","Topo");
Lon,Lat,Depth = coordinate_grids(Topo);
lonT          = unique(Lon);
latT          = unique(Lat);
depthT        = Depth[:,:,1];


#### plotting ####
function make_plot()

    fig       = Figure(resolution = (1600, 1600), fontsize = 30);

    # layout
    gcross = fig[1:6,1:4]
    gtopo  = fig[1,6:7]

    #### topography plot ####
    lonsTopo  = lonT; latsTopo = latT
    lonm      = (lonT[1]+lonT[end])/2

    # find projections: https://proj.org/operations/projections/index.html
    src        = "+proj=longlat +datum=WGS84"
    desti      = "+proj=eqdc +lat_1=25 +lat_2=30 +lon_0=$lonm"
    #trans     = Proj.Transformation(desti,src,always_xy=true)

    ga1       = GeoAxis(gtopo; source = "+proj=longlat +datum=WGS84", dest = "+proj=eqdc +lat_1=25 +lat_2=30 +lon_0=$lonm", lonlims = (lonT[1], lonT[end]), latlims = (latT[1], latT[end]))
    surface!(ga1, lonsTopo, latsTopo, depthT; colormap = :oleron, shading = false,colorrange=(-4.0,4.0))
    ga1.xticklabelsvisible = false; ga1.yticklabelsvisible = false; ga1.xlabelvisible =false; ga1.ylabelvisible =false;
    hidespines!(ga1)
    hidedecorations!(ga1)

    #### colorbar menu and Range slider ####

    # colorbar menu
    colors  = [:vik, :roma, :seismic, :buda, :hawaii, :lajolla, :vikO]
    ColMenu = Menu(fig[6, 2], options = colors)
    cmap    = Observable(colors[1])

    on(ColMenu.selection) do s
        cmap[] = s
    end

    # menu for Geodata fields
    data_names      = keys(Dataset.fields)
    data_selected   = Observable(Symbol(data_names[1]))      
    FieldsMenu      = Menu(fig[3, 6], options = [String.(data_names)...], default=String(data_selected[]))
    data_string     = @lift String($data_selected)
    get_vol(f_name) = Dataset.fields[f_name]
    vol             = lift(get_vol, data_selected)   

    on(FieldsMenu.selection) do s
        data_selected[] = Symbol(s)
    end


    # text boxes for colorrange
    txtMin = Textbox(fig[6, 2], placeholder = "...",
    validator = Float64, tellwidth = false,width= 200)
    txtMax = Textbox(fig[6, 2], placeholder = "...",
    validator = Float64, tellwidth = false, width=200)
    ColMin = Observable(-1.0)
    ColMax = Observable(1.0)
    r      = @lift ($ColMin,$ColMax)

    on(txtMin.stored_string) do s
        ColMin[] = parse(Float64, s)
    end
    on(txtMax.stored_string) do s
        ColMax[] = parse(Float64, s)
    end

    # depth slider
    depthr     = @lift 1:1:length($vol[1,1,:])
    Indr       = Observable(1)
    liftd      = @lift($depthr[$Indr])
    dataH      = @lift $vol[:,:,$liftd]
    vald       = @lift depthD[$liftd]
    depthval   = @lift "Depth = $($vald[]) km"
    length_sli = @lift length($depthr)

    #################################
    #### horizontal crosssection ####
    #################################

    # toggle
    toggle1   = Toggle(fig, active = false)
    lab1      = Label(fig, lift(xtog -> xtog ? "Horizontal Crosssection visible" : "Vertical Crosssection invisible", toggle1.active))

    # update location of point
    Hup   = (Keyboard.h, Keyboard.up)
    Hdown = (Keyboard.h, Keyboard.down)

    on(events(fig.scene).keyboardbutton) do event
        if ispressed(fig, Hup)

            if (Indr[] >= length_sli[])
                Indr[] = length_sli
            else
                Indr[] += 1
            end

        elseif ispressed(fig, Hdown)

            if Indr[] <= 1
                Indr[] = 1
            else
                Indr[] -= 1
            end

        notify(Indr)
            return Consume(true)
        end
        return Consume(false)
    end

    fieldlons = lonD; fieldlats = latD
    lonm      = (lonD[1]+lonD[end])/2
    ga2       = GeoAxis(gcross; source = src, dest = "+proj=eqdc +lat_1=25 +lat_2=30 +lon_0=$lonm",coastlines = false, lonlims = (lonD[1], lonD[end]), latlims = (latD[1], latD[end]),title=depthval,titlesize=40)
    HCross    = surface!(ga2, fieldlons, fieldlats, dataH; colormap = cmap, shading = false,colorrange=r)
    ga2.xgridvisible = false;

    connect!(HCross.visible, toggle1.active);
    connect!(ga2.yticklabelsvisible, toggle1.active);connect!(ga2.xticklabelsvisible, toggle1.active);
    connect!(ga2.ygridvisible, toggle1.active);connect!(ga2.xgridvisible, toggle1.active);connect!(ga2.titlevisible, toggle1.active);
    connect!(ga2.topspinevisible, toggle1.active);connect!(ga2.bottomspinevisible, toggle1.active);connect!(ga2.leftspinevisible, toggle1.active);connect!(ga2.rightspinevisible, toggle1.active);
    connect!(ga2.topspinevisible, toggle1.active)
  
    
    ##############################
    #### vertical crossection ####
    ##############################
    VerticalCross = Observable(false)
    @lift if $(toggle1.active)
              VerticalCross[] = false
          else
             VerticalCross[] = true
          end

    lon1 = Observable(lonT[1])
    lat1 = Observable(40.0)
    lon2 = Observable(lonT[end])
    lat2 = Observable(40.0)

    on(events(ga1).mousebutton, priority = 2) do event
        if event.button == Mouse.left && event.action == Mouse.press
            
            if Keyboard.v in events(ga1).keyboardstate

                lon1[] = mouseposition(ga1)[1]
                lat1[] = mouseposition(ga1)[2]
                notify(lon1)
                notify(lat1)
                return Consume(true)
            end

            if Keyboard.b in events(ga1).keyboardstate
                lon2[] = mouseposition(ga1)[1]
                lat2[] = mouseposition(ga1)[2]
                notify(lon2)
                notify(lat2)
                return Consume(true)
            end
        end
        return Consume(false)
    end

    surfCross, dataCross, TopoLine, SeaLine, SeaLevel = PrepCrossSection(lonD, latD, depthD, lon1,lon2,lat1,lat2,vol,lonT,latT,depthT)

    # draw line in plot
    lonCrossT = @lift $NumValue($surfCross.lon)
    lonCross  = @lift $lonCrossT[:,1,1]
    latCrossT = @lift $NumValue($surfCross.lat)
    latCross  = @lift $latCrossT[:,1,1]
    lines!(ga1,lonCross,latCross,linewidth=8,color=:red,overdraw=true) 


    distC = @lift DistLonLat($lon1,$lat1,$lon2,$lat2)
    dz    = abs(depthD[1]-depthD[end])
    as        = @lift $distC/(dz+SeaLevel)
    ga3       = Axis(gcross,aspect=as,yticks = depthD[1]:abs(depthD[1]-depthD[end]):depthD[end])
    ga3.xticklabelsvisible = false; ga3.xgridvisible = false;ga3.topspinevisible = false;ga3.bottomspinevisible = false;ga3.leftspinevisible = false;ga3.rightspinevisible = false;
    ga3.yticklabelsvisible = false; ga3.ylabelvisible =false; ga3.xticksvisible =false;
    xc  = @lift LinRange(0.0,$distC,100)
    lxc = @lift length($xc)
    f   = @lift fill(0, $lxc)
    zc = LinRange(depthD[end],depthD[1],100)
    VCross    = surface!(ga3, xc, zc, dataCross; colormap = cmap, shading = false,colorrange=r)
    Seaband   = band!(ga3, xc, f, SeaLine; color = (:blue, 1.0), label = "Label")
    Contband  = band!(ga3, xc, f, TopoLine; color = (:sienna, 1.0), label = "Label",overdraw=true)
    Colorbar(fig[3, 1:4], VCross, label = data_string, vertical = false)

    @lift xlims!(ga3,[0.0 $distC])
    VCross.visible               = VerticalCross
    @lift Seaband.visible        = $VerticalCross
    @lift Contband.visible       = $VerticalCross
    @lift ga3.yticklabelsvisible = $VerticalCross; 
    @lift ga3.yticksvisible      = $VerticalCross; 
    @lift ga3.ygridvisible       = $VerticalCross; 

    #### arrange interactive buttons ####
    fig[2, 6:7] = hgrid!(Label(fig,"           \n         ",fontsize=46),halign = :left,tellheight=true)
    fig[3, 6:7] = hgrid!(
            Label(fig, "Colormap", width = 250),ColMenu,
            Label(fig, "Select Field", width = 350),FieldsMenu,
            tellheight = true, tellwidth=false)
    fig[4, 6:7] = hgrid!(
            Label(fig, "Data min", width = 250),txtMin,
            Label(fig, "Data max", width = 250),txtMax,
            tellheight = true, tellwidth=false)

    fig[5, 6:7] = hgrid!(Label(fig,"           \n         ",fontsize=46),halign = :left,tellheight=true)
    fig[6, 6:7] = hgrid!(
                        lab1,toggle1,
                        halign = :left,tellheight = true, tellwidth=false)
        
    fig

end

#make_plot()
fig = with_theme(make_plot,theme_light())
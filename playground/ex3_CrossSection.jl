using GLMakie, ColorSchemes, JLD2, GeophysicalModelGenerator, Interpolations, LinearAlgebra, Proj

using GeoMakie



function PrepCrossSection(lonvec, latvec, depths,liftlons,liftlone,liftlats,liftlate,data,dataTopo)

    lons     = lonvec[1]
    lone     = lonvec[end]
    lats     = latvec[1]
    late     = latvec[end]
    zs       = depths[1]
    ze       = depths[end]

    # create crosssection
    n      = 100
    X,Y,Z  = XYZGrid(LinRange(lons, lone, n), LinRange(lats, late, n), LinRange(ze, zs, n));
    cross  = GeoData(X, Y, Z, (dVp = zeros(size(Z)),));

    STup   = @lift ($liftlons,$liftlats)
    ETup   = @lift ($liftlone,$liftlate)

    surf   = @lift CrossSection(cross, Start = $STup, End = $ETup,Interpolate=true)
    t1     = @lift NumValue($surf.lon);   t1 = @lift $t1[:,:,1];
    t2     = @lift NumValue($surf.lat);   t2 = @lift $t2[:,:,1];
    t3     = @lift NumValue($surf.depth); t3 = @lift $t3[:,:,1];

    # add interpolation
    # create interpolation object
    interpol    = LinearInterpolation((lonvec,latvec,depths),data ,extrapolation_bc = Flat());
    dataSurf    = @lift interpol.($t1,$t2,$t3)
    dataSurf    = @lift $dataSurf[:,:,1]

    # get topography
    interpolTopo    = LinearInterpolation((lonvec,latvec,depths),dataTopo ,extrapolation_bc = Flat());
    dataTopo        = @lift interpol.($t1,$t2,$t3)
    dataTopo        = @lift $dataSurf[:,:,1]




    return surf,dataSurf,dataTopo

end

function DistLonLat(lon1,lat1,lon2,lat2)

    r = 6371

    p = pi/180
    a = 0.5 - cosd((lat2-lat1)*p)/2 + cosd(lat1*p) *cosd(lat2*p) * (1-cosd((lon2-lon1)*p))/2
    d = 2*r * asind(sqrt(a))

    return d

end



# load seismic data (data from https://www.atlas-of-the-underworld.org/ processes with GeophysicalModelGenerator)
Underworld = load("playground/Data/Dataset_Underworld_Spherical.jld2","Dataset_Underworld") 


Lon,Lat,Zu = coordinate_grids(Underworld)
LonU         = Lon[:,:,1]
LatU         = Lat[:,:,1]
HgtU         = Hgt[:,:,1]
lonU         = unique(Lon)
latU         = unique(Lat)
hgtU         = unique(Zu)
dVp          = Underworld.fields.dVp



Topo        = load("playground/Data/EUCrust07.jld2","data_Topo")
Lon,Lat,Hgt = coordinate_grids(Topo)
LonT         = Lon[:,:,1]
LatT         = Lat[:,:,1]
HgtT         = Hgt[:,:,1]

lon         = unique(Lon)
lat         = unique(Lat)
hgt        = unique(HgtT)




#### plotting ####
function make_plot()

    fig       = Figure(resolution = (1600, 1600), fontsize = 30);

    # layout
    gcross = fig[1:6,1:4]
    gtopo  = fig[1,6:7]


    #### topography plot ####
    lonsTopo  = lon; latsTopo = lat
    field     = Hgt[:,:,1]
    lonm      = (lon[1]+lon[end])/2

    # find projections: https://proj.org/operations/projections/index.html
    src        = "+proj=longlat +datum=WGS84"
    desti      = "+proj=eqdc +lat_1=25 +lat_2=30 +lon_0=$lonm"
    #trans     = Proj.Transformation(desti,src,always_xy=true)

    ga1       = GeoAxis(gtopo; source = "+proj=longlat +datum=WGS84", dest = "+proj=eqdc +lat_1=25 +lat_2=30 +lon_0=$lonm", lonlims = (lon[1], lon[end]), latlims = (lat[1], lat[end]))
    Topo      = surface!(ga1, lonsTopo, latsTopo, field; colormap = :oleron, shading = false,colorrange=(-4.0,4.0))
    ga1.xticklabelsvisible = false; ga1.yticklabelsvisible = false; ga1.xlabelvisible =false; ga1.ylabelvisible =false;

    #hidespines!(ga1)
    #hidedecorations!(ga1)

    #### colorbar menu and Range slider ####
    # colormap Menu
    colors  = [:vik, :roma, :seismic, :buda, :hawaii, :lajolla, :vikO]
    ColMenu = Menu(fig[6, 2], options = colors)
    cmap    = Observable(colors[1])

    on(ColMenu.selection) do s
        cmap[] = s
    end

    # text boxes
    txtMin = Textbox(fig[6, 2], placeholder = "...",
    validator = Float64, tellwidth = false,width= 200)
    txtMax = Textbox(fig[6, 2], placeholder = "...",
    validator = Float64, tellwidth = false, width=200)
    ColMin = Observable(-1)
    ColMax = Observable(1)
    r      = @lift ($ColMin,$ColMax)

    on(txtMin.stored_string) do s
        ColMin[] = parse(Float64, s)
    end
    on(txtMax.stored_string) do s
        ColMax[] = parse(Float64, s)
    end

    # depth slider
    depthr    = 1:1:length(dVp[1,1,:])
    Indr      = Observable(1)
    liftd     = @lift(depthr[$Indr])
    dataH     = @lift dVp[:,:,$liftd]
    vald      = @lift hgtU[$liftd]
    depthval  = @lift "Depth = $($vald[]) km"

    #### horizontal crosssection ####
    # toggle
    toggle1   = Toggle(fig, active = false)
    lab1      = Label(fig, lift(xtog -> xtog ? "Horizontal Crosssection visible" : "Vertical Crosssection invisible", toggle1.active))

    # update location of point
    Hup   = (Keyboard.h, Keyboard.up)
    Hdown = (Keyboard.h, Keyboard.down)

    on(events(fig.scene).keyboardbutton) do event
        if ispressed(fig, Hup)

            if Indr[] >= length(depthr)
                Indr[] = length(depthr)
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
            return Consume(true)    # this would block rectangle zoom
        end

        return Consume(false)
    end

    fieldlons = lonU; fieldlats = latU
    lonm      = (lonU[1]+lonU[end])/2
    ga2       = GeoAxis(gcross; source = src, dest = "+proj=eqdc +lat_1=25 +lat_2=30 +lon_0=$lonm",coastlines = false, lonlims = (lonU[1], lonU[end]), latlims = (latU[1], latU[end]),title=depthval,titlesize=40)
    HCross    = surface!(ga2, fieldlons, fieldlats, dataH; colormap = cmap, shading = false,colorrange=r)
    ga2.xgridvisible = false;

    connect!(HCross.visible, toggle1.active);
    connect!(ga2.yticklabelsvisible, toggle1.active);connect!(ga2.xticklabelsvisible, toggle1.active);
    connect!(ga2.ygridvisible, toggle1.active);connect!(ga2.xgridvisible, toggle1.active);connect!(ga2.titlevisible, toggle1.active);
    connect!(ga2.topspinevisible, toggle1.active);connect!(ga2.bottomspinevisible, toggle1.active);connect!(ga2.leftspinevisible, toggle1.active);connect!(ga2.rightspinevisible, toggle1.active);
    connect!(ga2.topspinevisible, toggle1.active)

    # 
    VerticalCross = Observable(false)
    @lift if $(toggle1.active)
              VerticalCross[] = false
          else
             VerticalCross[] = true
          end


    #### vertical crossection ####
    lon1 = Observable(lon[1])
    lat1 = Observable(40.0)
    lon2 = Observable(lon[end])
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

    # interactive vertical crosssection







    #surfCross, dataCross = PrepCrossSection(lonU, latU, hgtU, lon1,lon2,lat1,lat2,dVp)


    lons     = lonU[1]
    lone     = lonU[end]
    lats     = latU[1]
    late     = latU[end]
    zs       = hgtU[1]
    ze       = hgtU[end]

    # create crosssection
    n      = 100
    X,Y,Z  = XYZGrid(LinRange(lons, lone, n), LinRange(lats, late, n), LinRange(ze, zs, n));
    cross  = GeoData(X, Y, Z, (dVp = zeros(size(Z)),));

    STup   = @lift ($lon1,$lat1)
    ETup   = @lift ($lon2,$lat2)

    surf   = @lift CrossSection(cross, Start = $STup, End = $ETup,Interpolate=true)
    t1     = @lift NumValue($surf.lon);   t1 = @lift $t1[:,:,1];
    t2     = @lift NumValue($surf.lat);   t2 = @lift $t2[:,:,1];
    t3     = @lift NumValue($surf.depth); t3 = @lift $t3[:,:,1];

    # add interpolation
    # create interpolation object
    interpol    = LinearInterpolation((lonU,latU,hgtU),dVp ,extrapolation_bc = Flat());
    dataSurf    = @lift interpol.($t1,$t2,$t3)
    dataSurf    = @lift $dataSurf[:,:,1]


    ## get topography
    interpolTopo    = LinearInterpolation((lon,lat),HgtT,extrapolation_bc = Flat());
    dataTopo        = @lift interpolTopo.($t1,$t2)
    multi           = 60
    addi            = 400
    TopoLine        = @lift $dataTopo[:,1,1] .* 60 .+ 400
    TopoLine        = @lift $TopoLine .- multi
    ver             = (addi - multi-80.0,addi - multi+80.0)



    surfCross = surf
    dataCross = dataSurf













    # draw line in plot
    lonCrossT = @lift $NumValue($surfCross.lon)
    lonCross  = @lift $lonCrossT[:,1,1]
    latCrossT = @lift $NumValue($surfCross.lat)
    latCross  = @lift $latCrossT[:,1,1]
    lines!(ga1,lonCross,latCross,linewidth=8,color=:red,overdraw=true) 


    distC = @lift DistLonLat($lon1,$lat1,$lon2,$lat2)
    dz    = abs(hgtU[1]-hgtU[end])
    as        = @lift $distC/dz
    ga3       = Axis(gcross,aspect=as,yticks = hgtU[1]:abs(hgtU[1]-hgtU[end]):hgtU[end])
    ga3.xticklabelsvisible = false; ga3.xgridvisible = false;ga3.topspinevisible = false;ga3.bottomspinevisible = false;ga3.leftspinevisible = false;ga3.rightspinevisible = false;
    ga3.yticklabelsvisible = false; ga3.ylabelvisible =false; ga3.xticksvisible =false;
    xc = @lift LinRange(0.0,$distC,100)
    zc = LinRange(hgtU[end],hgtU[1],100)
    VCross    = surface!(ga3, xc, zc, dataCross; colormap = cmap, shading = false,colorrange=r)
    lines!(ga3,xc,TopoLine,color=TopoLine,colormap=:oleron,linewidth=12,colorrange=ver,overdraw=true)
    @lift xlims!(ga3,[0.0 $distC])
    #ylims!(ga3,[hgtU[1] hgtU[end]])
    #ylims!(ga3,[hgtU[1] 200])

    VCross.visible               = VerticalCross
    @lift ga3.yticklabelsvisible = $VerticalCross; 
    @lift ga3.yticksvisible      = $VerticalCross; 
    @lift ga3.ygridvisible       = $VerticalCross; 


    #### arrange interactive buttons ####
    fig[2, 6:7] = hgrid!(Label(fig,"           \n         ",fontsize=46),halign = :left,tellheight=true)
    fig[3, 6:7] = hgrid!(
            Label(fig, "Colormap", width = 250),ColMenu,
            Label(fig, "Data min", width = 250),txtMin,
            Label(fig, "Data max", width = 250),txtMax,
            tellheight = true, tellwidth=false)

    fig[4, 6:7] = hgrid!(Label(fig,"           \n         ",fontsize=46),halign = :left,tellheight=true)
    fig[5, 6:7] = hgrid!(
                        lab1,toggle1,
                        halign = :left,tellheight = true, tellwidth=false)
        
    fig

end


make_plot()
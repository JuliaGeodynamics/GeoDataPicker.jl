# This reads an Inkscape (or Affinity Design) file and returns the curves 
using LightXML


export parse_SVG


"""
    label, coord = parse_path(path::XMLElement; use_label=true)

This parses a path in a *.SVG file and returns the name of the curve and its coordinates (in the reference frame of the SVG file).
`use_label` can be set to false (in case we don't use inkscape to generate the *.SVG file)

"""
function parse_path(path::XMLElement; use_label=true)
    if use_label
        label =  attribute(path,"label");
    else
        label =  attribute(path,"id");
    end

    # extract data
    d  =  split(attribute(path,"d"));   # the data as vector
    n  = size(d,1)
    coord = zeros(n,2)
    k = 1;
    for i=1:n
        row = d[i]
        if contains(row,",")
            values = parse.(Float64,split(row,","))
            coord[k,1] = values[1]
            coord[k,2] = values[2]
            k += 1;
        end
    end

    return label, coord[1:k-1,:]
end


"""
    Reference structure, used to go from pixels to real coordinates
"""
struct Reference{T}
    xrefPaper :: NTuple{2,T} # lower left coordinate in pixels
    yrefPaper :: NTuple{2,T} # spacing in x/y 
    xref      :: NTuple{2,T} # lower left coordinate in real units
    yref      :: NTuple{2,T} 
end


"""
    Ref = get_reference(xmlroot::XMLElement; is_inkscape=true)

Retrieves the reference of the current *.SVG file, which is a struct that contains the lower left coordinates and spacing in pixels and real units
"""
function get_reference(xmlroot::XMLElement, height::Int64; is_inkscape=true)
    Ref = []
    for c in LightXML.child_nodes(xmlroot) 
        if is_elementnode(c)
            layer = XMLElement(c)  # this makes an XMLElement instance

            label = attribute(layer, "label");
            id    = attribute(layer, "id");

            if is_inkscape
                layerLabel = label
            else
                layerLabel = id
            end

            if !isnothing(layerLabel)
                
                if contains(layerLabel,"Reference")   
                    for p in LightXML.child_nodes(layer) 
                        if is_elementnode(p)
                            path = XMLElement(p)  #     
                            label, coord = parse_path(path)
                          
                            CoordRef_values = parse.(Float64,split(LightXML.attribute(path,"CoordRef"),","))

                            # create the reference structure that is used to transfer pixels -> real coordinates
                            xrefPaper = (coord[1,1], coord[2,1])
                            yrefPaper = (height - coord[1,2], height - coord[2,2])
                            xref      = (CoordRef_values[1],CoordRef_values[3])
                            yref      = (CoordRef_values[2],CoordRef_values[4])
                         
                            Ref     = Reference(xrefPaper, yrefPaper, xref, yref)   # assign struct
                        end
                    end
                end
            end

        end
    end

    return Ref
end


"""
    coord_real = pixel2real(coord::Matrix{T}, Ref::Reference)

Transfers a curve from pixel coordinates (SVG file) to real coordinates, using the image reference
"""
function  pixel2real(coord::Matrix{T}, CoordRef::Reference) where T
    pixel_ll = (CoordRef.xrefPaper[1], CoordRef.yrefPaper[1])
    pixel_Δ  = (CoordRef.xrefPaper[2]-CoordRef.xrefPaper[1], CoordRef.yrefPaper[2]-CoordRef.yrefPaper[1])
    
    coord_ll = (CoordRef.xref[1], CoordRef.yref[1])
    coord_Δ  = (CoordRef.xref[2]-CoordRef.xref[1], CoordRef.yref[2]-CoordRef.yref[1])
    coord_shifted = copy(coord);
    for i=1:size(coord,1)
        coord_shifted[i,:] =  (coord_shifted[i,:] .- pixel_ll)./pixel_Δ  
        coord_shifted[i,:] =  coord_shifted[i,:].*coord_Δ .+ coord_ll
    end

    return coord_shifted
end


"""
    coord3D = create_coord3D(coord2D, layerLabel)

Creates a 3D curve out of the 2D coordinates, while taking the label of the layer into account
"""
function create_coord3D(coord2D::Matrix{T}, layerLabel::String) where T
    n = size(coord2D,1)
    labels = split(layerLabel,"_")
    if size(labels,1)==2
        labels[2] = replace(labels[2],"m"=>"-")
        labels[2] = replace(labels[2],"p"=>"+")
        coord3D = ones(n,3)* parse(Float64, labels[2])
        if  labels[1]=="HZ"
            coord3D[:,1:2] = coord2D
        elseif labels[1]=="EW"
            coord3D[:,1] = coord2D[:,1]
            coord3D[:,3] = coord2D[:,2]
        elseif labels[1]=="NS"
            coord3D[:,2:3] = coord2D[:,1:2]
        else
            error("unknown direction")
        end
    else
        coord3D = coord2D
    end

    return coord3D
end


"""
    Curves = parse_SVG(fname::String; is_inkscape=true, verbose=true)

This parses an SVG file; reads all thr curves on the file and transforms them to real coordinates and finally puts the results (with 3D curves) into a NamedTuple
"""
function parse_SVG(fname::String; is_inkscape=true, verbose=true)

    # Read raw data
    raw_file_contents = read(fname, String);

    # Read SVG file
    xml_file = parse_string(raw_file_contents);
    xmlroot = LightXML.root(xml_file);
    @assert LightXML.name(xmlroot) == "svg";            # ensure it is an svg file

    viewBox = attribute(xmlroot, "viewBox");

    if isnothing(viewBox)
        error("no viewBox indicated in file $fname")
    else
        viewBox = parse.(Int64,split(viewBox));

        width = viewBox[3];
        height = viewBox[4];
    end

    # get the reference frame of the image (needs to be a layer called "Reference")
    CoordRef = get_reference(xmlroot, height);      

    # go through all the layers in the file & extract curves
    Curves = NamedTuple()
    for c in LightXML.child_nodes(xmlroot) 
        if is_elementnode(c)
            layer = XMLElement(c)  # this makes an XMLElement instance

            label = attribute(layer, "label");
            id    = attribute(layer, "id");

            if is_inkscape
                layerLabel = label
            else
                layerLabel = id
            end

            if !isnothing(layerLabel) 
                if layerLabel[1]!='#' && !contains(layerLabel,"Reference") # if label starts with #, do not interpret
                    for p in LightXML.child_nodes(layer) 
                        if is_elementnode(p) 
                            path = XMLElement(p)  #     
                            label, coord = parse_path(path)
                            coord_real = pixel2real(coord, CoordRef);  # transfer to real coordinates
                            
                            coord3D = create_coord3D(coord_real, layerLabel) 

                            # if a curve with the same name already exist, add it to a tuple
                            # if not, create a tuple
                            if haskey(Curves,Symbol(label))
                                coord_data = (Curves[Symbol(label)]..., coord3D)
                            else
                                coord_data = (coord3D,)
                            end
                            NT_local = NamedTuple{(Symbol(label),)}((coord_data,))

                            Curves = merge(Curves,NT_local)
                        end
                    end

                end
            end
        end
    end

    if verbose
        println("Parsed file $fname and read following curves:")

        names = propertynames(Curves)
        for n in names
            println(" $n")
        end
    end

    return Curves
end


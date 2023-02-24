# 
# this is ProfileProcessing.jl
# It contains functions and type definitions to gather selected data for given profiles

export ProfileData, ExtractProfileData

# load packages
using GeophysicalModelGenerator
using DelimitedFiles
using JLD2
using MATLAB
using Geodesy

"""
    struct ProfileData
        lon_start::Float64
        lat_start::Float64
        lon_end::Float64
        lon_end::Float64
        VolData::GeoData
        SurfData::Vector{GeoData}
        PointData::Vector{GeoData}
    end

    Structure to store cross section data
"""
mutable struct ProfileData
    start_point::Tuple{Float64,Float64}
    end_point::Tuple{Float64,Float64}
    VolData::GeoData
    SurfData::Vector{GeoData}
    PointData::Vector{GeoData}

    function ProfileData(;kwargs...) # this constructor allows to define only certain fields and leave the others blank
        K = new()
        for (key, value) in kwargs
            # make sure that start and end point are given as tuples of Float64
            if key==Symbol("start_point")
                setfield!(K, key, convert(Tuple{Float64,Float64},value))
            elseif key==Symbol("end_point")
                setfield!(K, key, convert(Tuple{Float64,Float64},value))
            else
                setfield!(K, key, value)
            end
        end
        return K
    end
end

### function to process volume data
function CreateProfileVolume!(Profile,DataSetName,DataSetFile,DimsVolCross)
    num_datasets = length(DataSetName)
    fields_vol = NamedTuple()
    local lon_vol
    local lat_vol
    local depth_vol

    for idata = 1:num_datasets
        # load data set --> each data set should have been saved in a single GeoData structure, so we'll only have to get the respective key to load the correct type
        tmp_load = load(DataSetFile[idata])  # this gives us a dict with a key that is the name if the data set and the values as the GeoData structure
        tmp_load = collect(values(tmp_load))      # this gives us a vector with a single GeoData entry
        data_tmp = tmp_load[1]               # and now we extract that entry...
        cross_tmp = CrossSection(data_tmp,dims=DimsVolCross,Start=Profile.start_point,End=Profile.end_point)        # create the cross section

        # store profile coordinates and field data on first go
        if idata==1
            # get lon,lat and depth
            # as these are in GeoUnits and our GeoData structure does not take them as input, we need to only take the value
            lon_vol = cross_tmp.lon.val
            lat_vol = cross_tmp.lat.val
            depth_vol = cross_tmp.depth.val # this will be in km
            
            # convert to UTM and compute the distance from the starting point for later plotting
            # right now, this is done via a brute force approach which loops over all points
            lla_start = LLA(Profile.start_point[2],Profile.start_point[1],0.0) # start point 

            distp = zeros(size(lon_vol));
            for ipt = 1:length(lon_vol)
                distp[ipt] = euclidean_distance(LLA(lat_vol[ipt],lon_vol[ipt],0.0),lla_start)
            end

            fields_vol = NamedTuple{(:prof_dist,)}((distp,))

            # extract fields
            tmp_fields  = cross_tmp.fields;
            tmp_key     = keys(cross_tmp.fields) # get the key of all the fields
            for ifield = 1:length(tmp_fields) 
                fieldname   = DataSetName[1]*"_"*String(tmp_key[1])
                fielddata   = cross_tmp.fields[ifield]
                new_field   = NamedTuple{(Symbol(fieldname),)}((fielddata,))
                fields_vol = merge(fields_vol,new_field) # add to the existing NamedTuple
            end
        else # only store fields
            tmp_fields  = cross_tmp.fields;
            tmp_key     = keys(cross_tmp.fields) # get the key of all the fields
            for ifield = 1:length(tmp_fields) 
                fieldname   = DataSetName[idata]*"_"*String(tmp_key[1])
                fielddata   = cross_tmp.fields[ifield]
                new_field   = NamedTuple{(Symbol(fieldname),)}((fielddata,))
                fields_vol = merge(fields_vol,new_field) # add to the existing NamedTuple
            end
        end

    end

    tmp = GeoData(lon_vol,lat_vol,depth_vol,fields_vol)
    #tmp.atts.["datasets"] = DataSetName
    Profile.VolData = tmp # assign to Profile data structure
    return
end

### function to process surface data - contrary to the volume data, we here have to save lon/lat/depth pairs for every surface data set, so we create a vector of GeoData data sets
function CreateProfileSurface!(Profile,DataSetName,DataSetFile,DimsSurfCross)
    num_datasets = length(DataSetName)
    tmp = Vector{GeoData}(undef,num_datasets)

    for idata = 1:num_datasets
        # load data set --> each data set should have been saved in a single GeoData structure, so we'll only have to get the respective key to load the correct type
        tmp_load = load(DataSetFile[idata])  # this gives us a dict with a key that is the name if the data set and the values as the GeoData structure
        tmp_load = collect(values(tmp_load))      # this gives us a vector with a single GeoData entry
        data_tmp = tmp_load[1]               # and now we extract that entry...
        tmp2 = CrossSection(data_tmp, dims=DimsSurfCross,Start=Profile.start_point,End=Profile.end_point)        # create the cross section
        # add a field that provides the distance along the profile 
        lla_start = LLA(Profile.start_point[2],Profile.start_point[1],0.0) # start point 

        distp = zeros(size(tmp2.lon.val));
        for ipt = 1:size(tmp2.lon.val,1)
            distp[ipt] = euclidean_distance(LLA(tmp2.lat.val[ipt],tmp2.lon.val[ipt],0.0),lla_start)
        end

        dist_field  = NamedTuple{(:prof_dist,)}((distp,))
        tmp2        = GeoData(tmp2.lon.val,tmp2.lat.val,tmp2.depth.val,merge(tmp2.fields,dist_field),tmp2.atts)
        tmp[idata]  = tmp2;
        # add the data set name as an attribute (not required if there is proper metadata, but odds are that there is not)
        tmp[idata].atts["dataset"] = DataSetName[idata]
        
    end

    Profile.SurfData = tmp # assign to profile data structure
    return 
end

### function to process point data - contrary to the volume data, we here have to save lon/lat/depth pairs for every point data set
function CreateProfilePoint!(Profile,DataSetName,DataSetFile,WidthPointProfile)
    num_datasets = length(DataSetName)
    tmp = Vector{GeoData}(undef,num_datasets)

    for idata = 1:num_datasets
        # load data set --> each data set should have been saved in a single GeoData structure, so we'll only have to get the respective key to load the correct type
        tmp_load = load(DataSetFile[idata])  # this gives us a dict with a key that is the name if the data set and the values as the GeoData structure
        tmp_load = collect(values(tmp_load))      # this gives us a vector with a single GeoData entry
        data_tmp = tmp_load[1]               # and now we extract that entry...
        tmp[idata] = CrossSection(data_tmp,Start=Profile.start_point,End=Profile.end_point,section_width = WidthPointProfile)        # create the cross section
        # add the data set name as an attribute (not required if there is proper metadata, but odds are that there is not)
        tmp[idata].atts["dataset"] = DataSetName[idata]
    end

    Profile.PointData = tmp # assign to profile data structure

    return 
end

### wrapper function to process everything
function ExtractProfileData(ProfileCoordFile,ProfileNumber,DataSetName,DataSetFile,DataSetType,DimsVolCross,DimsSurfCross,WidthPointProfile)

    # start and end points are saved in a text file
    profile_coords = readdlm(ProfileCoordFile,skipstart=1)
    profile_coords = split(profile_coords[ProfileNumber],",")

    NUM = parse(Int,string(profile_coords[1]))
    LON_START = parse(Float64,string(profile_coords[2]))
    LAT_START = parse(Float64,string(profile_coords[3]))
    LON_END   = parse(Float64,string(profile_coords[4]))
    LAT_END   = parse(Float64,string(profile_coords[5]))

    # create the cross section data set with the given lat and lon data (rest will be added later)
    Profile = ProfileData(start_point=(LON_START,LAT_START),end_point=(LON_END,LAT_END))

    # Determine the number of volume, surface and point data sets
    ind_vol    = findall( x -> x .== "Vol", DataSetType)
    ind_surf   = findall( x -> x .== "Surf", DataSetType)
    ind_point  = findall( x -> x .== "Point", DataSetType)

    # extract volume data
    CreateProfileVolume!(Profile,DataSetName[ind_vol],DataSetFile[ind_vol],DimsVolCross)

    # extract surface data
    CreateProfileSurface!(Profile,DataSetName[ind_surf],DataSetFile[ind_surf],DimsSurfCross)

    # extract point data
    CreateProfilePoint!(Profile,DataSetName[ind_point],DataSetFile[ind_point],WidthPointProfile)

    return Profile
end


### add 

### save everything --> also as mat file for potential processing with MATLAB
function SaveProfileData(Profile,ProfileNumber)

    # save as jld2
    save("Profile"*string(ProfileNumber),Profile)
    # save for paraview
    # TODO

    # save as matlab --> convert to array of structures --> is done automatically by MATLAB.jl
    # in the saving process, the information about the data set names is lost for surface data and point data
    # this is why we added that to the attributes
    # for volume data, it is not possible like that, but the field names are conserved
    # it's ugly though
    write_matfile(fn*".mat"; ProfileData=ExtractedData,)


    return
end

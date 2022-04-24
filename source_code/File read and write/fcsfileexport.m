function fcsfileexport(app, Data, timestamp, filename)


    %% create header information

    % add software information to fcs hdr
    fcs_hdr.RPSPASS_Version = app.Version;
    fcs_hdr.RPSPASS_Date = timestamp;

    % add nCS1 file info to fcs header
    InfoVars = genvarname(Data.Info(:,1));
    for i = 1:numel(InfoVars)
        fcs_hdr.(InfoVars{i}) = Data.Info{i,2};
    end

    %% create parameter information

    % variable names to write to file
    VarWriteName = {'time','Time';...
        'AcqID', 'Acquisition ID';...
        'non_norm_d','Diameter (raw)';...
        'cumvol', 'Cumulative Volume';...
        'ttime','Transit time';...
        'signal2noise','Signal to Noise';...
        'symmetry','Symmetry';...
        'diam','Diameter (RPSPASS)'};

    % copy fields that need to be written to fcs file
    for i = 1:size(VarWriteName,1)
        data2write.(VarWriteName{i,1}) = Data.(VarWriteName{i,1});
    end

    % convert structure array to table
    data2write = struct2table(data2write);

    % convert table to array for writing to file
    array = table2array(data2write);

    % rename table variables for fcs parameters
    names = VarWriteName(:,2);

    % write fcs file
    writeSpectradyneFCS(filename, array, fcs_hdr, names, names)



end
function writeSpectradyneCVS(Data, timestamp, filename)

%% create header information

% add software information to fcs hdr
fcs_hdr.RPSPASS_Version = getprefRPSPASS('RPSPASS','version');
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

% convert table to cell array for writing to file
array = cell(size(data2write,1)+1, size(data2write,2));
array(1,:) = VarWriteName(:,2)';
array(2:end,:) = table2cell(data2write);

% export report to excel spreadsheet
if ismac()
    writecell(array,filename,'Sheet','Raw Data','UseExcel',false,'FileType','spreadsheet')
elseif ispc()
    writecell(array,filename,'Sheet','Raw Data','UseExcel',true,'FileType','spreadsheet')
end

% create metadata array from fcs header
metadata(:,1) = fields(fcs_hdr);
metadata(:,2) = struct2cell(fcs_hdr);

% remove nested cells
for i = 1:size(metadata,1)
    if iscell(metadata{i,2})
        metadata(i,2) = {metadata{i,2}{1}};
    end
end

% write metadata to csv file
if ismac()
    writecell(metadata,filename,'Sheet','Metadata','UseExcel',false,'FileType','spreadsheet')
elseif ispc()
    writecell(metadata,filename,'Sheet','Metadata','UseExcel',true,'FileType','spreadsheet')
end

% convert structure array to table
indexdata2write = struct2table(Data.Indices);

% field names for indices
indexFieldnames = fieldnames(Data.Indices);
indexHeadersRm = {'NotNoise','NotOutliers','Unprocessed'};

% create indices output
indexdata = cell(size(indexdata2write,1)+1, size(indexdata2write,2));
indexdata(2:end,:) = table2cell(indexdata2write);
indexdata(:,contains(indexFieldnames,indexHeadersRm)) = [];
indexdata(1,:) = indexFieldnames(~contains(indexFieldnames,indexHeadersRm));

% export report to excel spreadsheet
if ismac()
    writecell(indexdata,filename,'Sheet','Index Data','UseExcel',false,'FileType','spreadsheet')
elseif ispc()
    writecell(indexdata,filename,'Sheet','Index Data','UseExcel',true,'FileType','spreadsheet')
end

end
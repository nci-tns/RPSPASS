function [] = writeReport(TableHeaders, Report, outputPath)

% header names to be included in written table
Headers.Metadata = {'Filename','Sample Information','Sample Source','Sample Isolation','Sample Diluent','Spike-in information','Cartridge ID','Instrument Sheath Fluid'};
Headers.RPSPASS_Summary = {'Filename', 'Diameter Calibration', 'Outlier Removal', 'Noise Removal', 'Spike-in Removal', 'FCS Creation','CSV Creation','MAT Creation',};
Headers.IndGate = {'Filename','Unprocessed Total Events','Unprocessed Total Volume (pL)','Unprocessed Total Conc (mL^-1)', 'IndGate Non-spike-in Events','IndGate Spike-in Events','IndGate Total Volume (pL)','IndGate Sample Conc (mL^-1)','IndGate Spike-In Conc (mL^1)','IndGate Diameter Gate (nm)','IndGate Transit Time Gate (µs)'};
Headers.CohGate = {'Filename','Unprocessed Total Events','Unprocessed Total Volume (pL)','Unprocessed Total Conc (mL^-1)','CoGate Non-spike-in Events','CoGate Spike-in Events','CoGate Total Volume (pL)','CoGate Sample Conc (mL^-1)','CoGate Spike-In Conc (mL^1)','CoGate Diameter Gate (nm)','CoGate Transit Time Gate (µs)'};

% get unique field names for indexing export loop
GroupNames = fields(Headers);

% sheet name for each respective table export
SheetName = {'Analysis Metadata','RPSPASS Summary','Stats - Sample Gated','Stats - Cohort Gated'};

for i = 1:numel(GroupNames)

    % get table index for output information
    Ind.(GroupNames{i}) = ismember(TableHeaders,Headers.(GroupNames{i}));

    % create a new table for output information
    Export.(GroupNames{i}) = Report(:,Ind.(GroupNames{i}));

    % convert table to cell array for writing
    Write.(GroupNames{i}) = [replace(TableHeaders(Ind.(GroupNames{i})),{'IndGate ','CoGate '},''); table2cell(Export.(GroupNames{i}))];

    % export report to excel spreadsheet
    writecell(Write.(GroupNames{i}),outputPath,'Sheet',SheetName{i},'UseExcel',true,'FileType','spreadsheet')
end

end

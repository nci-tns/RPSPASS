function [] = writeReport(TableHeaders, Report, outputPath,Data)

%% export RPSPASS software settings
RPSPASS_Settings = {'Version',getprefRPSPASS('RPSPASS','version');...
    'Spike-in Used',Data.RPSPASS.SpikeInUsed;...
    'Spike-in Diameter (nm)',Data.RPSPASS.SpikeInDiam;...
    'Spike-in Concentration (mL-1)',Data.RPSPASS.SpikeInConc;...
    'Outlier Removal',getprefRPSPASS('RPSPASS','outlierremovalSelected');...
    'Spike-in CV Range (%)',getprefRPSPASS('RPSPASS','Threshold_SpikeIn_CV');...
    'Spike-in SI Range',getprefRPSPASS('RPSPASS','Threshold_SpikeIn_SI');...
    'Spike-in Transit Time Range (µs)',getprefRPSPASS('RPSPASS','Threshold_SpikeIn_TT');...
    'Spike-in Signal2Noise/Transit Time Range',getprefRPSPASS('RPSPASS','Threshold_SpikeIn_TTSN');...
    'Diameter Calibration Method',getprefRPSPASS('RPSPASS','diamcalitypeSelected');...
    'Spike-in Fit Method',getprefRPSPASS('RPSPASS','CalibrationMethod');...
    'Dynamic Calibration Event Threshold',getprefRPSPASS('RPSPASS','DynamicCalSpikeInThresh');...
    'Static Calibration Event Threshold',getprefRPSPASS('RPSPASS','StaticCalSpikeInThresh');...
    '.mat File Export',getprefRPSPASS('RPSPASS','matfile');...
    '.fcs File Export',getprefRPSPASS('RPSPASS','fcsfile');...
    '.csv File Export',getprefRPSPASS('RPSPASS','xlsxfile');...
    '.h5 File Locator',getprefRPSPASS('RPSPASS','filelocatorSelected');...
    'Cohort Analysis',getprefRPSPASS('RPSPASS','cohortAnalysisSelected');...
    'Debug Outputs',getprefRPSPASS('RPSPASS','debugSelected')};

% export report to excel spreadsheet
if ismac()
    writecell(RPSPASS_Settings,outputPath,'Sheet','RPSPASS Settings','UseExcel',false,'FileType','spreadsheet')
elseif ispc()
    writecell(RPSPASS_Settings,outputPath,'Sheet','RPSPASS Settings','UseExcel',true,'FileType','spreadsheet')
end

% header names to be included in written table
Headers.RPSPASS_Summary = {'Filename', 'Diameter Calibration', 'Outlier Removal', 'Noise Removal', 'FCS Creation','CSV Creation','MAT Creation',};
Headers.Metadata = {'Filename','Sample Information','Sample Source','Sample Isolation','Sample Diluent','Spike-in information','Cartridge ID','Instrument Sheath Fluid'};
Headers.IndGate = {'Filename','Unprocessed Total Events','Unprocessed Total Volume (pL)','Unprocessed Total Conc Mean (mL^-1)','Unprocessed Total Conc SD (mL^-1)', 'IndGate Non-spike-in Events','IndGate Spike-in Events','IndGate Total Volume (pL)','IndGate Sample Conc Mean (mL^-1)','IndGate Sample Conc SD (mL^-1)','IndGate Spike-In Conc Mean (mL^-1)','IndGate Spike-In Conc SD (mL^-1)'};
switch getprefRPSPASS('RPSPASS','cohortAnalysisSelected')
    case 'on'
        Headers.CohGate = {'Filename','Unprocessed Total Events','Unprocessed Total Volume (pL)','Unprocessed Total Conc Mean (mL^-1)','Unprocessed Total Conc SD (mL^-1)','CoGate Non-spike-in Events','CoGate Spike-in Events','CoGate Total Volume (pL)','CoGate Sample Conc Mean (mL^-1)','CoGate Sample Conc SD (mL^-1)','CoGate Spike-In Conc Mean (mL^-1)','CoGate Spike-In Conc SD (mL^-1)'};
end

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
    if ismac()
        writecell(Write.(GroupNames{i}),outputPath,'Sheet',SheetName{i},'UseExcel',false,'FileType','spreadsheet')
    elseif ispc()
        writecell(Write.(GroupNames{i}),outputPath,'Sheet',SheetName{i},'UseExcel',true,'FileType','spreadsheet')
    end

end



end

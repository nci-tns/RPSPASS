
function PrefVersionUpdate(Version, prefpath)
%% additional preferences in release if preferences already exist

% General
setprefRPSPASS('RPSPASS','version', Version);


Prefs = {...
    'prefpath',  prefpath;...       % filepath to preferences
    'dev_path',  '';...       % filepath to test files for development
    'dev_file_download','https://jones-lab-nanopass.s3.amazonaws.com/RPSPASS/Dev+Files/RPSPASS+Dev+Testing+Files.zip';... % public spectradyne testing files
    'acquisition_dir','';... % live acquisition directory
    'last_dir','';... % last working directory

    'OutlierRemoval_Pressure',1; ...       % perform outlier removal based on P1 pressure [0=off, 1=on]
    'OutlierRemoval_TransitTime',1; ...    % perform outlier removal based on transit time [0=off, 1=on]
    'OutlierRemoval_CV',1; ...             % perform outlier removal based on CV [0=off, 1=on]
    'OutlierRemoval_SI',1; ...             % perform outlier removal based on SI [0=off, 1=on]
    'OutlierRemoval_TTSN',1; ...           % perform outlier removal based on S2N over Transit time [0=off, 1=on]

    'Threshold_Sets', 2;...    % range allowed from minimum CV (%)
    'Threshold_SpikeIn_CV', 2;...    % range allowed from minimum CV (%)
    'Threshold_SpikeIn_SI', 0.2;... % range of SI to keep
    'Threshold_SpikeIn_TT', 5;...   % range of transit time gate range in µs
    'Threshold_SpikeIn_TTSN',1.5;... % range of signal2noise/transit time threshold
    
    'CalibrationMethod', 'Kernel';...   % spike in bead fitting method
    'DynamicCalSpikeInThresh',10;...    % min spike-in events to perform dynamic calibration
    'StaticCalSpikeInThresh',50;...     % min spike-in events to perform static calibration

    'matfile',1; ...                % write a .mat file [0=off, 1=on]
    'fcsfile',1; ...                % write a .fcs file [0=off, 1=on]
    'xlsxfile',1; ...                % write a .csv file [0=off, 1=on]
    'jsonfile',1; ...                % write a .csv file [0=off, 1=on]

    'filelocatorOptions',{'_cc','_ss00'};...    % method used to identify experiment files
    'filelocatorSelection', [false; true];...   % logic gate for file operator selection in pref panel
    'filelocatorNum',[];...                     % num of options for file operator selection in pref panel
    'filelocatorSelected','';...                % selected file operator selection in pref panel

    'outlierremovalOptions',{'on','off'};...       % outlier removal
    'outlierremovalSelection', [true; false];...   % logic gate for outlier selection in pref panel
    'outlierremovalNum',[];...                     % num of options for outlier selection in pref panel
    'outlierremovalSelected','';...                % selected outlier removal selection in pref panel

    'diamcalitypeOptions',{'dynamic','static'};...
    'diamcalitypeSelection', [true; false];...   % logic gate for outlier selection in pref panel
    'diamcalitypeNum',[];...                     % num of options for outlier selection in pref panel
    'diamcalitypeSelected','';...                % num of options for outlier selection in pref panel

    'cohortAnalysisOptions',{'on','off'};...       % debug mode
    'cohortAnalysisSelection', [true; false];...   % logic gate for debug selection in pref panel
    'cohortAnalysisNum',[];...                     % num of options for debug selection in pref panel
    'cohortAnalysisSelected','';...                % selecteddebug selection in pref panel

    'debugOptions',{'on','off'};...       % debug mode
    'debugSelection', [true; false];...   % logic gate for debug selection in pref panel
    'debugNum',[];...                     % num of options for debug selection in pref panel
    'debugSelected','';...                % selecteddebug selection in pref panel

    'Response',''};                 % response to button pressing for communication between HTML & MATLAB

for i = 1:size(Prefs,1)

    % if preference doesnt exist, create it
    if ~isprefRPSPASS('RPSPASS',Prefs{i,1})
        setprefRPSPASS('RPSPASS',Prefs{i,1}, Prefs{i,2})
    end

    % these preferences are listed in a specific order 
    % below the preferences they use for calculation
    if strcmp(Prefs{i,1},'filelocatorNum')
        N = numel(getprefRPSPASS('RPSPASS','filelocatorOptions'));
        setprefRPSPASS('RPSPASS','filelocatorNum', N)

    elseif strcmp(Prefs{i,1},'outlierremovalNum')
        N = numel(getprefRPSPASS('RPSPASS','outlierremovalOptions'));
        setprefRPSPASS('RPSPASS','outlierremovalNum', N)

    elseif strcmp(Prefs{i,1},'cohortAnalysisNum')
        N = numel(getprefRPSPASS('RPSPASS','cohortAnalysisOptions'));
        setprefRPSPASS('RPSPASS','cohortAnalysisNum', N)

    elseif strcmp(Prefs{i,1},'debugNum')
        N = numel(getprefRPSPASS('RPSPASS','debugOptions'));
        setprefRPSPASS('RPSPASS','debugNum', N)

    elseif strcmp(Prefs{i,1},'diamcalitypeNum')
        N = numel(getprefRPSPASS('RPSPASS','diamcalitypeOptions'));
        setprefRPSPASS('RPSPASS','diamcalitypeNum', N)

    %% selections, must be followed by the num
    elseif strcmp(Prefs{i,1},'filelocatorSelected')
        Options = getprefRPSPASS('RPSPASS','filelocatorOptions');
        Selection = getprefRPSPASS('RPSPASS','filelocatorSelection');
        setprefRPSPASS('RPSPASS','filelocatorSelected', Options{Selection})

    elseif strcmp(Prefs{i,1},'outlierremovalSelected')
        Options = getprefRPSPASS('RPSPASS','outlierremovalOptions');
        Selection = getprefRPSPASS('RPSPASS','outlierremovalSelection');
        setprefRPSPASS('RPSPASS','outlierremovalSelected', Options{Selection})

    elseif strcmp(Prefs{i,1},'noiseremovalSelected')
        Options = getprefRPSPASS('RPSPASS','noiseremovalOptions');
        Selection = getprefRPSPASS('RPSPASS','noiseremovalSelection');
        setprefRPSPASS('RPSPASS','noiseremovalSelected', Options{Selection})

    elseif strcmp(Prefs{i,1},'diamcalitypeSelected')
        Options = getprefRPSPASS('RPSPASS','diamcalitypeOptions');
        Selection = getprefRPSPASS('RPSPASS','diamcalitypeSelection');
        setprefRPSPASS('RPSPASS','diamcalitypeSelected', Options{Selection})

    elseif strcmp(Prefs{i,1},'cohortAnalysisSelected')
        Options = getprefRPSPASS('RPSPASS','cohortAnalysisOptions');
        Selection = getprefRPSPASS('RPSPASS','cohortAnalysisSelection');
        setprefRPSPASS('RPSPASS','cohortAnalysisSelected', Options{Selection})

    elseif strcmp(Prefs{i,1},'debugSelected')
        Options = getprefRPSPASS('RPSPASS','debugOptions');
        Selection = getprefRPSPASS('RPSPASS','debugSelection');
        setprefRPSPASS('RPSPASS','debugSelected', Options{Selection})
    end

end

end
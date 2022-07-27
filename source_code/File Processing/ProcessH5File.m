function [app, Data, Report] = ProcessH5File(app, filepath, filenames, Report, FileID, FileGroup)

if isempty(FileGroup)
    info = h5info(fullfile(filepath, filenames));
    fnames = info.Groups(1).Groups;
else
    fnames = FileGroup{FileID};
end

vol = 0;
Data.Acqtime = 0;
Data.AcqID = [];
Data.non_norm_d = [];
Data.ttime = [];
Data.signal2noise = [];
Data.symmetry = [];
Data.acq_int = [];
Data.acqvol = [];
Data.SetPs = [];
Data.time = [];
Data.cumvol = [];

for i = 1:size(fnames,1)
    if ~isempty(FileGroup)
        CompFilename = fullfile(filepath, FileGroup{FileID}{i});
        info = h5info(CompFilename);
        % define index to find pertinent criteria for software function
        timeind = double(info.Attributes(strcmp({info.Attributes.Name}, 'acqtime')).Value);
        samprate = double(info.Attributes(strcmp({info.Attributes.Name}, 'n_samp')).Value);
        acqvol = double(info.Attributes(strcmp({info.Attributes.Name}, 'measured_volume')).Value);
        sfactInd = double(info.Attributes(strcmp({info.Attributes.Name}, 'diameterScalingFactor')).Value);
        setPs = double(info.Attributes(strcmp({info.Attributes.Name}, 'setPs')).Value);
        data = h5read(CompFilename, '/pks');
    else
        % define index to find pertinent criteria for software function
        timeind = double(info.Groups(1).Groups(i).Attributes(strcmp({info.Groups(1).Groups(i).Attributes.Name}, 'acqtime')).Value);
        samprate = double(info.Groups(1).Groups(i).Attributes(strcmp({info.Groups(1).Groups(i).Attributes.Name}, 'n_samp')).Value);
        acqvol = double(info.Groups(1).Groups(i).Attributes(strcmp({info.Groups(1).Groups(i).Attributes.Name}, 'measured_volume')).Value);
        sfactInd = double(info.Groups(1).Groups(i).Attributes(strcmp({info.Groups(1).Groups(i).Attributes.Name}, 'diameterScalingFactor')).Value);
        setPs = double(info.Groups(1).Groups(i).Attributes(strcmp({info.Groups(1).Groups(i).Attributes.Name}, 'setPs')).Value);
        readstr = [fnames(i).Name,'/',fnames(i).Datasets(2).Name];
        data = h5read(fullfile(filepath, filenames), readstr);
    end


    Data.ttime  = [Data.ttime ; data.pk_width]; % Transit time (µs)
    Data.symmetry = [Data.symmetry; data.pk_sym]; % Pulse symmetry
    Data.signal2noise  = [Data.signal2noise ; data.pk_sn]; % Signal to noise ratio
    Data.non_norm_d  = [Data.non_norm_d ; nCS1_Scaling_Factor(data, sfactInd)]; % Uncalibrated Diameter (nm)

    % time calculation
    Data.time = [Data.time; (double(data.pk_index) * (timeind/samprate)) + Data.Acqtime(i)]; % Time (secs)
    Data.Acqtime = [Data.Acqtime; Data.Acqtime(i) + timeind];

    % volume calculation
    Data.cumvol = [Data.cumvol; (((double(data.pk_index) * (acqvol/samprate)) + vol).* 1e9)]; % Cumulative Volume (pL)
    vol = vol + acqvol;

    % aggregate data across each acquisition
    Data.AcqID = [Data.AcqID; i*ones(size(data.pk_width,1),1)]; % run ID for each event
    Data.acq_int = [Data.acq_int; timeind]; % acquisition time
    Data.acqvol = [Data.acqvol; (acqvol.* 1e9)]; % total volume of each acquisition (pL)
    Data.SetPs = [Data.SetPs; setPs(:)']; % get input pressures for each acquisition P1 IN, P5 OUT, P3 IN, P2 OUT, P7 IN, and P6 OUT
end

% raw sample data
if isempty(FileGroup)
    Data.Info(:,[1 2]) = horzcat({info.Groups(1).Groups(i).Attributes.Name}', {info.Groups(1).Groups(i).Attributes.Value}'); % h5 information
else
    Data.Info(:,[1 2]) = horzcat({info.Attributes.Name}', {info.Attributes.Value}'); % h5 informationend
end

Data.AcqIDUq = unique(Data.AcqID); % get unique acquisition IDS
Data.diam = nan(size(Data.non_norm_d,1),1);
Data.TT2SN = Data.signal2noise./Data.ttime; % ratio used to define noise
Data.NoiseInd = Data.signal2noise./Data.ttime<1; % index used for initial gating of detectable events
Data.outliers = false(size(Data.time,1),1); % default matrix for outlier removal
Data.CaliFactor = ones(numel(Data.acq_int),1); % deterimed calibration factor for each acquisition
Data.SpikeInGateMax = nan(numel(Data.acq_int),1); % determined maximum diameter for spike-in gate
Data.SpikeInGateMin = nan(numel(Data.acq_int),1); % determined minimum diameter for spike-in gate
Data.UngatedTotalEvents = size(Data.AcqID,1); % total number of detected events before outlier removal
Data.EventID = 1:numel(Data.AcqID); % create a unique ID for each event for downstream indexing

% sample metadata
cartstr = Data.Info{strcmp(Data.Info(:,1),'cartridge_class'),2};
Data.maxDiam = str2double(cartstr(regexp(cartstr, '\d')));
Data.moldID = Data.Info{strcmp(Data.Info(:,1),'moldID'),2};
Data.BoxID =  Data.Info{strcmp(Data.Info(:,1),'cartridge_box_date'),2};
Data.Date =  Data.Info{strcmp(Data.Info(:,1),'stats_gen_date'),2};

% software settings
Data.RPSPASS.SpikeInUsed = app.SpikeInUsed; % was a spike in bead used?
Data.RPSPASS.SpikeInDiam = app.SpikeInDiam; % what was the spike in diameter (if used)
Data.RPSPASS.SpikeInConc = app.SpikeInConc; % what was the spike in diameter (if used)
Data.RPSPASS.CalInt = Data.acq_int; % length of interval to calibrate over (seconds)
Data.RPSPASS.MaxInt = numel(cumsum(Data.acq_int)); % number of intervals
Data.RPSPASS.AcqInt = [0; cumsum(Data.acq_int)]; % cumulative sum of acquisition intervals
Data.RPSPASS.CalMethod = getprefRPSPASS('RPSPASS','CalibrationMethod'); % calibration stat method
Data.RPSPASS.PeakThreshold = 0.3; % percentage threshold of max bin count to remove to find spike-in peak
Data.RPSPASS.DiamGateWidth = 10; % diameter window to perform peak find in nm
Data.RPSPASS.MinSpikeInStart = 0.8; % minimum diameter to start search for spike in bead (percentage of true spike in diam)
Data.RPSPASS.FailedAcq = false(1,Data.RPSPASS.MaxInt);
Data.RPSPASS.FailedCriteria = cell(1, Data.RPSPASS.MaxInt);

% create empty arrays for downstream use
Data.Individual.Not_Noise.time = Data.time(~Data.NoiseInd);
Data.Individual.Not_Noise.AcqID = Data.AcqID(~Data.NoiseInd);
Data.Individual.Not_Noise.non_norm_d = Data.non_norm_d(~Data.NoiseInd);
Data.Individual.Not_Noise.diam = Data.diam(~Data.NoiseInd);
Data.Individual.Not_Noise.ttime = Data.ttime(~Data.NoiseInd);
Data.Individual.Not_Noise.signal2noise = Data.signal2noise(~Data.NoiseInd);
Data.Individual.Not_Noise.TT2SN = Data.TT2SN(~Data.NoiseInd);

switch Data.RPSPASS.SpikeInUsed
    case 'Yes'
        Data.Individual.Not_SpikeIn.time = [];
        Data.Individual.Not_SpikeIn.AcqID = [];
        Data.Individual.Not_SpikeIn.non_norm_d = [];
        Data.Individual.Not_SpikeIn.diam = [];
        Data.Individual.Not_SpikeIn.ttime = [];
        Data.Individual.Not_SpikeIn.signal2noise = [];
        Data.Individual.Not_SpikeIn.TT2SN = [];

        Data.Individual.SpikeIn.time = [];
        Data.Individual.SpikeIn.AcqID = [];
        Data.Individual.SpikeIn.non_norm_d = [];
        Data.Individual.SpikeIn.diam = [];
        Data.Individual.SpikeIn.ttime = [];
        Data.Individual.SpikeIn.signal2noise = [];
        Data.Individual.SpikeIn.TT2SN = [];
end

Data.Cohort.Not_Noise.time = [];
Data.Cohort.Not_Noise.AcqID = [];
Data.Cohort.Not_Noise.non_norm_d = [];
Data.Cohort.Not_Noise.diam = [];
Data.Cohort.Not_Noise.ttime = [];
Data.Cohort.Not_Noise.signal2noise = [];
Data.Cohort.Not_Noise.TT2SN = [];

Data.Cohort.Not_SpikeIn.time = [];
Data.Cohort.Not_SpikeIn.AcqID = [];
Data.Cohort.Not_SpikeIn.non_norm_d = [];
Data.Cohort.Not_SpikeIn.diam = [];
Data.Cohort.Not_SpikeIn.ttime = [];
Data.Cohort.Not_SpikeIn.signal2noise = [];
Data.Cohort.Not_SpikeIn.TT2SN = [];

Data.Cohort.SpikeIn.time = [];
Data.Cohort.SpikeIn.AcqID = [];
Data.Cohort.SpikeIn.non_norm_d = [];
Data.Cohort.SpikeIn.diam = [];
Data.Cohort.SpikeIn.ttime = [];
Data.Cohort.SpikeIn.signal2noise = [];
Data.Cohort.SpikeIn.TT2SN = [];


% if contains(getprefRPSPASS('RPSPASS','CurrFile'),'5.')
%     x = 1;
% end

% try % calibrate diameter
[Data, Stat, Report] = DiamCalibration(app, Data, FileID, Report);
% catch
%     Report(FileID,'Diameter Calibration') = {'Failed'};
% end

switch getprefRPSPASS('RPSPASS','outlierremovalSelected')
    case 'on'
        % try % remove outliers
        [Data] = OutlierRemoval(Data, Stat);
        %     Report(FileID,'Outlier Removal') = {'Passed'};
        % catch
        %     Report(FileID,'Outlier Removal') = {'Failed'};
        % end
    otherwise
        Report(FileID,'Outlier Removal') = {'Off'};
end


% exclude noise from sample
[Data.Ind_gate, Data.boundary, Data.reg, Data.fail] = ExcludeNoise(Data.ttime,Data.diam);
if Data.fail == true
    Report(FileID,'Noise Removal') = {'Failed'};
else
    Report(FileID,'Noise Removal') = {'Passed'};
end

try % post gating outlier removal
    [Data] = PostGateOutlierRemoval(Data);
catch
    Report(FileID,'Outlier Removal') = {'Failed'};
end

% create normalize gate for removing spike-in bead and reporting statistics
% based on spike-in exclusion
switch Data.RPSPASS.SpikeInUsed
    case 'Yes'
        % if diam calibration passed
        if ~strcmp(Report{FileID,'Diameter Calibration'},'Failed')
            Data.SpikeInGateMaxNorm = max(Data.SpikeInGateMax(~Data.RPSPASS.FailedAcq) .* Data.CaliFactor(~Data.RPSPASS.FailedAcq));
            Data.SpikeInGateMinNorm = min(Data.SpikeInGateMin(~Data.RPSPASS.FailedAcq) .* Data.CaliFactor(~Data.RPSPASS.FailedAcq));
        else % if failed
            Data.SpikeInGateMaxNorm = [];
            Data.SpikeInGateMinNorm = [];
        end

end




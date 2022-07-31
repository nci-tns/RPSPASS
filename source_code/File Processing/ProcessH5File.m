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
Data.outliers = false(size(Data.time,1),1); % default matrix for outlier removal
Data.CaliFactor = ones(numel(Data.acq_int),1); % deterimed calibration factor for each acquisition
Data.SpikeInGateMax = nan(numel(Data.acq_int),1); % determined maximum diameter for spike-in gate
Data.SpikeInGateMin = nan(numel(Data.acq_int),1); % determined minimum diameter for spike-in gate
Data.UngatedTotalEvents = size(Data.AcqID,1); % total number of detected events before outlier removal
Data.EventID = 1:numel(Data.AcqID); % create a unique ID for each event for downstream indexing
Data.Indices.NoiseInd = Data.signal2noise./Data.ttime<1; % noise index
Data.Indices.NotNoise = not(Data.Indices.NoiseInd); % event index
Data.Indices.Unprocessed = true(size(Data.diam,1)); % event index

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
Data.RPSPASS.CohortGate = []; % create empty array for downstream use



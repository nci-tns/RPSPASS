function [app, Data, Report] = ProcessH5File(app, filepath, filenames, Report, FileID, FileGroup)

if isempty(FileGroup)
    info = h5info(fullfile(filepath, filenames));
    fnames = info.Groups(1).Groups;
else
    fnames = FileGroup{FileID};
end

t = 0;
time = [];
AcqID = [];
vol = 0;
cumvol =[];
non_norm_d = [];
trans_time = [];
sn = [];
sy = [];
acq_int = [];
int_vol = [];
raw_vol = [];
pressures = [];

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

    trans_t = data.pk_width;
    signois = data.pk_sn;
    sym = data.pk_sym;

    % diameter calculation
    [nCS1_diam] = nCS1_Scaling_Factor(data, sfactInd);
    non_norm = nCS1_diam;

    % time calculation
    timepoint = (double(data.pk_index) * (timeind/samprate)) + t;
    t = t + timeind;

    % volume calculation
    v = (double(data.pk_index) * (acqvol/samprate)) + vol;
    vol = vol + acqvol;

    % aggregate data across each acquisition
    time = [time; timepoint];
    AcqID = [AcqID; i*ones(size(non_norm,1),1)];
    non_norm_d = [non_norm_d; non_norm];
    cumvol = [cumvol; v];
    trans_time = [trans_time; trans_t];
    sn = [sn; signois];
    sy = [sy; sym];
    acq_int = [acq_int; timeind];
    int_vol = [int_vol; acqvol];
    pressures = [pressures; setPs(:)'];
end

% sample data
if isempty(FileGroup)
    Data.Info(:,[1 2]) = horzcat({info.Groups(1).Groups(i).Attributes.Name}', {info.Groups(1).Groups(i).Attributes.Value}'); % h5 information
else
    Data.Info(:,[1 2]) = horzcat({info.Attributes.Name}', {info.Attributes.Value}'); % h5 informationend
end
Data.time = time; % Time (secs)
Data.AcqID = AcqID; % Acquisition
Data.AcqIDUq = unique(AcqID); % get unique acquisition IDS
Data.non_norm_d = non_norm_d; % Uncalibrated Diameter (nm)
Data.diam = nan(size(Data.non_norm_d,1),1);
Data.acqvol = int_vol .* 1e9; % total volume of each acquisition (pL)
Data.cumvol = cumvol .* 1e9; % Cumulative Volume (pL)
Data.ttime = trans_time; % Transit time (µs)
Data.signal2noise = sn; % Signal to noise ratio
Data.TT2SN = Data.signal2noise./Data.ttime; % ratio used to define noise
Data.symmetry = sy; % Pulse symmetry
Data.outliers = false(size(Data.time,1),1); % default matrix for outlier removal
Data.acq_int = acq_int; % acquisition time
Data.CaliFactor = ones(numel(Data.acq_int),1); % deterimed calibration factor for each acquisition
Data.SpikeInGateMax = nan(numel(Data.acq_int),1); % determined maximum diameter for spike-in gate
Data.SpikeInGateMin = nan(numel(Data.acq_int),1); % determined minimum diameter for spike-in gate
Data.UngatedTotalEvents = size(Data.AcqID,1); % total number of detected events before outlier removal
Data.SetPs = pressures; % get input pressures for each acquisition P1 IN, P5 OUT, P3 IN, P2 OUT, P7 IN, and P6 OUT
Data.EventID = 1:numel(AcqID); % create a unique ID for each event for downstream indexing

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




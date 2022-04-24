function [gate, boundary, reg, fail] = ExcludeNoise(ttime,diam,options)

arguments
    ttime (1,:) double {mustBeNumeric}
    diam (1,:) double {mustBeNumeric}
    options.thresholds (1,2) double {mustBeNumeric} = [50 95]
    options.res (1,1) double {mustBeNumeric} = 256
    options.ttime_max (1,1) double {mustBeNumeric} = 200
    options.QCPlots (1,:) char {mustBeMember(options.QCPlots, {'off','on'})} = 'off'
end

% transit time increments
TTimeBins = linspace(0, options.ttime_max, options.res);
ttime_bincenter = TTimeBins(1:end-1) + (diff(TTimeBins)/2);

% create statistics for each transit time bin
pop_stats = nan(numel(TTimeBins)-1, numel(options.thresholds)); % create empty array
pop_dist = nan(numel(TTimeBins)-1, 1);  % create empty array
for i = 1:numel(TTimeBins)-1
    ind = ttime>=TTimeBins(i) & ttime < TTimeBins(i+1);
%     pop_stats(i,:) = [prctile(diam(ind), options.thresholds)];
    pop_stats(i,:) = [mean(diam(ind)), 3*std(diam(ind))];
    pop_dist(i) = std(diam(ind));
end

for i = 1:numel(options.thresholds)
    % index for removing nan values
    rmInd = or(isnan(ttime_bincenter(:)), isnan(pop_stats(:,i)));

    x = ttime_bincenter(~rmInd); % transit time
    y = pop_stats(~rmInd,i); % diameter
    z = pop_dist(~rmInd); % ttime standard dev

    % QC plots
    switch options.QCPlots
        case 'on'
            plot(x,y,'xk')
            hold on
            plot(movmean(x,5),movmean(y,5),'-r')
    end

    % find diameter threshold for regression using max ttime related diameter
    % and ttime above median ttime
    reg_ind = x>median(x);

    % perform weighted linear regression
    if sum(reg_ind) < 3
        r = [0 0];
    else
        r = robustfit(x(reg_ind), y(reg_ind),'bisquare');
    end
    noisereg.m(i) = r(2); % regression slope
    noisereg.c(i) = r(1); % regression intercept
end

% edge of noise
EdgeNoise = mean(z(reg_ind));
if isnan(EdgeNoise)
    EdgeNoise = 0;
end

% define minimum diameter bins for noise gate
NoiseMinGateLims = ((noisereg.m(2) * ttime_bincenter([1 end])) + noisereg.c(1)) + EdgeNoise/2;

% define noise polygon boundary
noiseboundary.ttime = TTimeBins([1 1 end end]);
noiseboundary.diam = [NoiseMinGateLims(1) max(diam) max(diam) NoiseMinGateLims(2)];

% create logical index for noise events within gate
[in,on] = inpolygon(ttime, diam, noiseboundary.ttime, noiseboundary.diam);

% logical gate for noise events
gate_1 = or(in, on); % remove EV events
gate_2 = ttime<median(ttime); % focus on steepest gradient of noise
noise_gate = and(~gate_1(:), gate_2(:));

% find noise regression
if sum(noise_gate) < 3
    fail = true;
elseif isnan(max(diam(noise_gate)))
    fail = true;
else
    r = robustfit(ttime(noise_gate), diam(noise_gate),'bisquare');
    reg.m = r(2); % regression slope
    reg.c = r(1)+EdgeNoise; % regression intercept

    % define minimum diameter bins for noise gate
    MinGateLims = ((reg.m * ttime_bincenter([1 end])) + reg.c);

    % define noise polygon boundary
    boundary.ttime = TTimeBins([1 1 end end]);
    boundary.diam = [MinGateLims(1) max(diam) max(diam) MinGateLims(2)];

    % create logical index for noise events within gate
    [in,on] = inpolygon(ttime, diam, boundary.ttime, boundary.diam);

    gate(:,1) = or(in,on);

    fail = false;
end

% default output if noise gate is not determinable
if fail == true
    gate = false(size(diam,1),1);
    boundary.ttime = [nan nan nan nan];
    boundary.diam = [nan nan nan nan];
    reg.m = [nan];
    reg.c = [nan];
end
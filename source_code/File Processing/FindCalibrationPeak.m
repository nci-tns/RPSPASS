function [peakData, CalFailure, Data] = FindCalibrationPeak(Data, Diam_TimeGated, acq_int)

if ~isempty(Diam_TimeGated)

    % position to start incremental binning
    Start = round(Data.RPSPASS.SpikeInDiam*Data.RPSPASS.MinSpikeInStart,0);
    End = Data.maxDiam;
    Increments = Start:1:End;

    % incrementally bin data
    N = nan(1, numel(Increments));
    for i = 1:numel(Increments)
        bincent(i) = Start + ((i+Data.RPSPASS.DiamGateWidth) - (i)/2);
        ind = Diam_TimeGated > Start+i & Diam_TimeGated < Start+i+Data.RPSPASS.DiamGateWidth;
        N(i) = sum(ind);
    end

    % remove data below defined percentage of maximum bin to reduce noise
    % in peak finding
    M = N;
    N(N<max(N*Data.RPSPASS.PeakThreshold )) = 0;

    % find peak and location of binned data
    CountThreshold = max(N)*Data.RPSPASS.PeakThreshold;
    [pk,lk] = findpeaks(N,"MinPeakHeight",CountThreshold);

    % obtain location of the largest bin and select the largest location if
    % there are multiple with same bin size
    pkPos = max(lk(pk == max(pk)));
    Data.SpikeInNum(acq_int,1) = max(pk);

    % if debug mode is on, save variable for plotting outside loop
    switch getprefRPSPASS('RPSPASS','debugSelected')
        case 'on'
            Data.Debug.PeakFind.bincent{acq_int} = bincent;
            Data.Debug.PeakFind.M{acq_int} = M;
            Data.Debug.PeakFind.lk{acq_int} = lk;
            Data.Debug.PeakFind.CountThreshold{acq_int} = CountThreshold;
    end

    if isempty(pkPos)
        CalFailure = true;
        peakData = [];
    else
        % run up from maximum bin to see where it reaches a value of 0
        % indicating top edge of peak
        GateMax = pkPos;
        Count = M(pkPos);
        while Count > 0
            GateMax = GateMax + 1;
            if GateMax == numel(GateMax)
                break
            else
                Count = M(GateMax);
            end
        end

        % run down from maximum bin to see where it reaches a value of 0
        % indicating bottom edge of peak
        GateMin = pkPos;
        Count = N(pkPos);
        while Count > 0
            GateMin = GateMin - 1;
            if GateMin == 0
                break
            else
                Count = N(GateMin);
            end
        end

        % add starting increment value + 10 nm to determine max and min gate
        % for spike-in peak
        Data.SpikeInGateMax(acq_int,1) = Start + GateMax + Data.RPSPASS.DiamGateWidth;
        Data.SpikeInGateMin(acq_int,1) = Start + GateMin - Data.RPSPASS.DiamGateWidth;

        % create an index for diameter data representing the spike in bead
        peakDataInd = Diam_TimeGated > Data.SpikeInGateMin(end) & Diam_TimeGated < Data.SpikeInGateMax(end);

        % obtain data representing the spike in bead
        peakData = Diam_TimeGated(peakDataInd);
        CalFailure = false;
    end
else
    CalFailure = true;
    peakData = [];
end

end
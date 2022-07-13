function [Data]=OutlierRemoval(Data,Stat)


switch getprefRPSPASS('RPSPASS','outlierremovalSelected')

    case 'on'

        % create empty arrays to speed up for loop and avoid errors
        % downstream

        SI = nan(Data.RPSPASS.MaxInt,1);
        CVs = nan(Data.RPSPASS.MaxInt,1);
        NoiseEvents = nan(Data.RPSPASS.MaxInt,1);
        NoiseSpikeInRatio = nan(Data.RPSPASS.MaxInt,1);

        for i = 1:Data.RPSPASS.MaxInt
            % isolate data for acquisition
            timgate = Data.time >= Data.RPSPASS.AcqInt(i) & Data.time < Data.RPSPASS.AcqInt(i+1);
            DiamCalData = Data.diam(timgate);
            TransitTime = Data.ttime(timgate);
            SpikeIn = DiamCalData(DiamCalData > Data.SpikeInGateMin(i)*Data.CaliFactor(i) & DiamCalData < Data.SpikeInGateMax(i)*Data.CaliFactor(i));
            SpikeInTT(i) = median(TransitTime(DiamCalData > Data.SpikeInGateMin(i)*Data.CaliFactor(i) & DiamCalData < Data.SpikeInGateMax(i)*Data.CaliFactor(i)));
            % Noise = DiamCalData(DiamCalData < Data.SpikeInGateMin(i)*Data.CaliFactor(i));
            Noise = DiamCalData(Data.signal2noise(timgate) < 10);

            SI(i) = (prctile(SpikeIn,5) - prctile(Noise,5)) / (prctile(Noise,95));
            CVs(i) = 100*(std(SpikeIn)/mean(SpikeIn));
            NoiseEvents(i) = numel(Noise);
            NoiseSpikeInRatio(i) = numel(Noise) / numel(SpikeIn);
            
            % pass debug plotting information
            Data.Debug.OutlierRemoval.Noise(i) = median(Noise);
            Data.Debug.OutlierRemoval.SpikeIn(i) = median(SpikeIn);
        end




        % create logical index of outliers based on spike-in bead
        % percentage CV

        CV_sort = sort(CVs,'ascend');
        CV_diff = CV_sort(1:end-1)./CV_sort(2:end);
        CV_diff(CV_diff==0) = nan;
        CV_min = CV_sort(find(CV_diff<=1.1,1,'first'));
        CV_max = CV_min+getprefRPSPASS('RPSPASS','Threshold_SpikeIn_CV');
        CV_thresh = CVs>= CV_min & CVs<=CV_max;

        % create logical index of outliers basedd on spike-in separation
        % index from noise
  
        SI_mean = movmean(SI,5);
        SI_diff = SI-SI_mean;
        SI_thresh = SI_diff > -getprefRPSPASS('RPSPASS','Threshold_SpikeIn_SI') & SI_diff < getprefRPSPASS('RPSPASS','Threshold_SpikeIn_SI');

        % combine logical outlier arrays
        OutlierInd = and(SI_thresh(:), CV_thresh(:));
        AcqIDind = unique(find(OutlierInd));

        timgate = false(size(Data.AcqID));
        for i = 1:numel(AcqIDind)
            timgate = or(timgate, (Data.AcqID(:)==AcqIDind(i)));
        end

        % create outlier index
        Data.outliers = ~timgate;
        Data.RPSPASS.FailedAcq = ~OutlierInd;

        % pass debug plotting information
        Data.Debug.OutlierRemoval.SI = SI;
        Data.Debug.OutlierRemoval.SI_thresh = SI_thresh;
        Data.Debug.OutlierRemoval.CV = CVs;
        Data.Debug.OutlierRemoval.CV_min = CV_min;
        Data.Debug.OutlierRemoval.CV_max = CV_max;
        Data.Debug.OutlierRemoval.CV_thresh = CV_thresh;
        Data.Debug.OutlierRemoval.NoiseEvents = NoiseEvents;
        Data.Debug.OutlierRemoval.NoiseSpikeInRatio = NoiseSpikeInRatio;
        Data.Debug.OutlierRemoval.SpikeInTT = SpikeInTT;

        Debug_Plots(Data, 'OutlierRemoval')

    case 'off'


end


end
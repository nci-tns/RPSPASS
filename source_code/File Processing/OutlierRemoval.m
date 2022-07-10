function [Data]=OutlierRemoval(Data,Stat)


switch getprefRPSPASS('RPSPASS','outlierremovalSelected')

    case 'on'
    
        SI = nan(Data.RPSPASS.MaxInt,1);
        CVs = nan(Data.RPSPASS.MaxInt,1);

        for i = 1:Data.RPSPASS.MaxInt
            % isolate data for acquisition
            timgate = Data.time >= Data.RPSPASS.AcqInt(i) & Data.time < Data.RPSPASS.AcqInt(i+1);
            DiamCalData = Data.diam(timgate);

            SpikeIn = DiamCalData(DiamCalData > Data.SpikeInGateMin(i)*Data.CaliFactor(i) & DiamCalData < Data.SpikeInGateMax(i)*Data.CaliFactor(i));
            Noise = DiamCalData(DiamCalData < Data.SpikeInGateMin(i)*Data.CaliFactor(i));

            SI(i) = (prctile(SpikeIn,5) - prctile(Noise,5)) / (prctile(Noise,95));
            CVs(i) = 100*(std(SpikeIn)/mean(SpikeIn));

            Data.Debug.OutlierRemoval.Noise(i) = median(Noise);
            Data.Debug.OutlierRemoval.SpikeIn(i) = median(SpikeIn);
        end



        threshSIind = SI>=(max(SI)*getprefRPSPASS('RPSPASS','Threshold_SpikeIn_SI'));
        threshCVind = CVs<=(min(CVs)+getprefRPSPASS('RPSPASS','Threshold_SpikeIn_CV'));

        OutlierInd = and(threshSIind(:), threshCVind(:));
        AcqIDind = unique(find(OutlierInd));

        timgate = false(size(Data.AcqID));
        for i = 1:numel(AcqIDind)
            timgate = or(timgate, (Data.AcqID(:)==AcqIDind(i)));
        end

        Data.outliers = ~timgate;
        Data.RPSPASS.FailedAcq = ~OutlierInd;

        Data.Debug.OutlierRemoval.SI = SI;
        Data.Debug.OutlierRemoval.SI_thresh = threshSIind;
        Data.Debug.OutlierRemoval.CV = CVs;
        Data.Debug.OutlierRemoval.CV_thresh = threshCVind;

        Debug_Plots(Data, 'OutlierRemoval')

    case 'off'


end


end
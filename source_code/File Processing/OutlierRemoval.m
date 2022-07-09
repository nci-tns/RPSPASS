function [Data]=OutlierRemoval(Data,Stat)


switch getprefRPSPASS('RPSPASS','outlierremovalSelected')

    case 'on'

        for i = 1:Data.RPSPASS.MaxInt
            % isolate data for acquisition
            TimeGate = Data.time >= Data.RPSPASS.AcqInt(i) & Data.time < Data.RPSPASS.AcqInt(i+1);
            DiamCalData = Data.diam(TimeGate);

            SpikeIn = DiamCalData(DiamCalData > Data.SpikeInGateMin(i)*Data.CaliFactor(i) & DiamCalData < Data.SpikeInGateMax(i)*Data.CaliFactor(i));
            Noise = DiamCalData(DiamCalData < Data.SpikeInGateMin(i)*Data.CaliFactor(i));

            SI(i) = (prctile(SpikeIn,5) - prctile(Noise,5)) / (prctile(Noise,95));
          
            Data.Debug.OutlierRemoval.Noise(i) = median(Noise);
            Data.Debug.OutlierRemoval.SpikeIn(i) = median(SpikeIn);
        end

        Data.Debug.OutlierRemoval.SI = SI;
        Debug_Plots(Data, 'OutlierRemoval')

        threshInd = SI>=(max(SI)*0.8);

        Data.outliers = false(Data.RPSPASS.MaxInt,1);
        Data.outliers(~threshInd(:)) = true;

        Data.RPSPASS.FailedAcq = false(Data.RPSPASS.MaxInt,1);
        Data.RPSPASS.FailedAcq(~threshInd(:)) = true;



    case 'off'


end


end
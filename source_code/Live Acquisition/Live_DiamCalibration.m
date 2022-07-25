function [Data] = Live_DiamCalibration(app, Data)

switch getprefRPSPASS('RPSPASS','diamcalitypeSelected')

    case 'auto'

        SpikeIn_data = cell(1,Data.RPSPASS.MaxInt);
        % cycle through each acquisition to perform dynamic calibration
        for i = 1:numel(Data.RPSPASS.AcqInt)-1

            % isolate data for acquisition
            TimeGate = Data.time >= Data.RPSPASS.AcqInt(i) & Data.time < Data.RPSPASS.AcqInt(i+1);
            DiamCalData = Data.non_norm_d(TimeGate);

            switch Data.RPSPASS.SpikeInUsed
                case 'On'

                    if isempty(DiamCalData)
                        CalFailure = true;
                        CalFactor = 1;
                        diam_norm = nan;
                    else
                        [SpikeIn_data{i}, CalFailure, Data] = FindCalibrationPeak(Data, DiamCalData, i);


                        if numel(SpikeIn_data{i}) >= getprefRPSPASS('RPSPASS','DynamicCalSpikeInThresh') & CalFailure == false

                            [CalFactor] = Live_getCaliFactor(app, Data, SpikeIn_data{i});
                        else
                            CalFactor = 1;
                            diam_norm = nan;
                            CalFailure = true;
                        end
                    end

                case 'Off'
                    CalFactor = 1;
                    CalFailure = false;
                    diam_norm = DiamCalData;
            end

            Data.diam(TimeGate) = DiamCalData * CalFactor;
            Data.CaliFactor(i) = CalFactor;
        end

        % get the spike-in count for each acquisition
        SpikeIn_Count = cellfun(@numel, SpikeIn_data);

        % if spike-in events per acquisition are insufficient to reliably perform
        % dynamic calibration revert to static calibration
        if sum(SpikeIn_Count>10) <= Data.RPSPASS.MaxInt*0.5
            if sum(SpikeIn_Count) >= getprefRPSPASS('RPSPASS','StaticCalSpikeInThresh')
                [SpikeIn_data, ~, Data] = FindCalibrationPeak(Data, Data.non_norm_d, 1);

                [CalFactor, ~, ~] = getCaliFactor(app, Data, SpikeIn_data);


                Data.diam = Data.non_norm_d * CalFactor;
                Data.CaliFactor = [Data.CaliFactor; CalFactor];
            end
        end

    case 'static'



end

end
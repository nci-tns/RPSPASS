function [Data, Stat, Report] = DiamCalibration(app,Data, FileID, Report)

switch getprefRPSPASS('RPSPASS','diamcalitypeSelected')

    case 'auto'

        SpikeIn_data = cell(1,Data.RPSPASS.MaxInt);
        % cycle through each acquisition to perform dynamic calibration
        for i = 1:Data.RPSPASS.MaxInt

            % isolate data for acquisition
            TimeGate = Data.time >= Data.RPSPASS.AcqInt(i) & Data.time < Data.RPSPASS.AcqInt(i+1);
            DiamCalData = Data.non_norm_d(TimeGate);

            switch Data.RPSPASS.SpikeInUsed
                case 'Yes'

                    if isempty(DiamCalData)
                        CalFailure = true;
                        CalFactor = 1;
                        diam_norm = nan;
                    else
                        [SpikeIn_data{i}, CalFailure, Data] = FindCalibrationPeak(Data, DiamCalData, i);

 
                        if numel(SpikeIn_data{i}) >= getprefRPSPASS('RPSPASS','DynamicCalSpikeInThresh') & CalFailure == false

                            [CalFactor, CalFailure, diam_norm] = getCaliFactor(app, Data, SpikeIn_data{i});
                        else
                            CalFactor = 1;
                            diam_norm = nan;
                            CalFailure = true;
                        end
                    end

                case 'No'
                    CalFactor = 1;
                    CalFailure = false;
                    diam_norm = DiamCalData;
            end

            % outlier removal stats
            Stat.CalFailure(i) = CalFailure;
            Stat.DiamCalFactor(i) = CalFactor;
            Stat.DiamMode(i) = mode(round(diam_norm,0));
            Stat.Events(i) = numel(diam_norm);
            Stat.Ttime(i) = mode(round(Data.ttime(TimeGate),0));

            Data.diam(TimeGate) = DiamCalData * CalFactor;
            Data.CaliFactor = [Data.CaliFactor; CalFactor];
        end

        % if debug mode is on, save variable for plotting outside loop
        switch getprefRPSPASS('RPSPASS','debugSelected')
            case 'on'
                Debug_Plots(Data, 'PeakFind',FileID)
        end

        % get the spike-in count for each acquisition
        SpikeIn_Count = cellfun(@numel, SpikeIn_data);

        % if spike-in events per acquisition are insufficient to reliably perform
        % dynamic calibration revert to static calibration
        if sum(SpikeIn_Count>10) <= Data.RPSPASS.MaxInt*0.5
            if sum(SpikeIn_Count) >= getprefRPSPASS('RPSPASS','StaticCalSpikeInThresh')
                [SpikeIn_data, ~, Data] = FindCalibrationPeak(Data, Data.non_norm_d, 1);

                [CalFactor, CalFailure, diam_norm] = getCaliFactor(app, Data, SpikeIn_data);

                % outlier removal stats
                Stat.CalFailure(1:end) = CalFailure;
                Stat.DiamCalFactor(1:end) = CalFactor;
                Stat.DiamMode(1:end) = mode(round(diam_norm,0));
                Stat.Events(1:end) = numel(diam_norm);
                Stat.Ttime(1:end) = mode(round(Data.ttime(TimeGate),0));

                Data.diam = Data.non_norm_d * CalFactor;
                Data.CaliFactor = [Data.CaliFactor; CalFactor];

                Report(FileID,'Diameter Calibration')  = {'Reverted to static calibration'};
            else
                Report(FileID,'Diameter Calibration')  = {'Failed: too few spike-in events'};
            end
        else
            Report(FileID,'Diameter Calibration')  = {'Passed'};
        end

    case 'static'



end
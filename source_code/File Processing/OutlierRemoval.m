function [Data]=OutlierRemoval(Data,Stat)


switch getprefRPSPASS('RPSPASS','outlierremovalSelected')

    case 'on'

        UserCalFactorThr = getprefRPSPASS('RPSPASS','Threshold_CalFactor')/100;
        CalFactorThr = mode(round(Stat.DiamCalFactor,2));

        UserSDiamThr = getprefRPSPASS('RPSPASS','Threshold_Diam')/100;
        MedThr = mode(round(Stat.DiamMode,2));

        UserEventThr = getprefRPSPASS('RPSPASS','Threshold_Event')/100;
        NumThr = mode(Stat.Events);

        UserTtimeThr = getprefRPSPASS('RPSPASS','Threshold_Ttime')/100;
        TtimeThr = mode(Stat.Ttime);


        for i = 1:Data.RPSPASS.MaxInt

            if Data.RPSPASS.CalInt > 0
                time_int = [(i*Data.RPSPASS.CalInt)-Data.RPSPASS.CalInt, (i*Data.RPSPASS.CalInt)];
                time_ind = Data.time>=time_int(1) & Data.time<time_int(2);
            else
                time_ind = 1:numel(Data.non_norm_d);
            end

            ind = time_ind;
            Data.RPSPASS.FailedAcq(i) = false;

            % Calibration Failures

            if Stat.CalFailure(i)
                Data.outliers(ind) = true;
                Data.RPSPASS.FailedAcq(i) = true;
                Data.RPSPASS.FailedCriteria{i} = [Data.RPSPASS.FailedCriteria{i}, 'Diam'];
            end

            % CalFactor threshold
            if UserCalFactorThr == 0
            else
                if Stat.DiamCalFactor(i) > CalFactorThr*(1+UserCalFactorThr) || Stat.DiamCalFactor(i) < CalFactorThr*(1-UserCalFactorThr) || Stat.CalFailure(i)
                    Data.outliers(ind) = true;
                    Data.RPSPASS.FailedAcq(i) = true;
                    Data.RPSPASS.FailedCriteria{i} = [Data.RPSPASS.FailedCriteria{i}, 'CalFactor Thresh'];
                end
            end

            % diameter threshold
            if UserSDiamThr == 0
            else
                if  Stat.DiamMode(i) > MedThr*(1+UserSDiamThr) ||  Stat.DiamMode(i) < MedThr*(1-UserSDiamThr)
                    Data.outliers(ind) = true;
                    Data.RPSPASS.FailedAcq(i) = true;
                    Data.RPSPASS.FailedCriteria{i} = [Data.RPSPASS.FailedCriteria{i}, 'Diameter Thresh'];
                end
            end

            % event threshold
            if UserEventThr == 0
            else
                if Stat.Events(i) > NumThr*(1+UserEventThr) || Stat.Events(i) < NumThr*(1-UserEventThr)
                    Data.outliers(ind) = true;
                    Data.RPSPASS.FailedAcq(i) = true;
                    Data.RPSPASS.FailedCriteria{i} = [Data.RPSPASS.FailedCriteria{i}, 'Event Thresh'];
                end
            end

            % transit time threshold
            if UserTtimeThr == 0
            else
                if Stat.Ttime(i) > TtimeThr*(1+UserTtimeThr) || Stat.Ttime(i) < TtimeThr*(1-UserTtimeThr)
                    Data.outliers(ind) = true;
                    Data.RPSPASS.FailedAcq(i) = true;
                    Data.RPSPASS.FailedCriteria{i} = [Data.RPSPASS.FailedCriteria{i}, 'Transit Time Thresh'];
                end
            end

        end

    case 'off'


end


end
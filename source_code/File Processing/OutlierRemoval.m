function [Data, Report]=OutlierRemoval(Data, Report, FileID)

switch getprefRPSPASS('RPSPASS','outlierremovalSelected')
    case 'on'
        % create empty arrays to speed up for loop and avoid errors
        % downstream

        SI = nan(Data.RPSPASS.MaxInt,1);
        CVs = nan(Data.RPSPASS.MaxInt,1);
        NoiseEvents = nan(Data.RPSPASS.MaxInt,1);
        NoiseSpikeInRatio = nan(Data.RPSPASS.MaxInt,1);
        SpikeInTT = nan(Data.RPSPASS.MaxInt,1);
        SpikeInTT2SN = nan(Data.RPSPASS.MaxInt,1);

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


        for i = 1:Data.RPSPASS.MaxInt
            % isolate data for acquisition
            timgate = Data.time >= Data.RPSPASS.AcqInt(i) & Data.time < Data.RPSPASS.AcqInt(i+1);
            DiamCalData = Data.diam(timgate);
            TransitTime = Data.ttime(timgate);
            TT2SN = Data.TT2SN(timgate);

            SpikeInIndex = DiamCalData >= Data.SpikeInGateMinNorm & DiamCalData <= Data.SpikeInGateMaxNorm;
            SpikeIn = DiamCalData(SpikeInIndex);
            SpikeInTT(i) = median(TransitTime(SpikeInIndex));
            SpikeInTT2SN(i) = median(TT2SN(SpikeInIndex));

            Noise = DiamCalData(Data.Indices.NoiseInd(timgate));
            Events = DiamCalData(~Data.Indices.NoiseInd(timgate));

            SI(i) = (prctile(SpikeIn,50) - prctile(Noise,50)) / (prctile(Noise,95));
            CVs(i) = 100*(std(SpikeIn)/mean(SpikeIn));
            NoiseEvents(i) = numel(Noise);
            NoiseSpikeInRatio(i) = (numel(Events)-numel(SpikeIn)) / numel(SpikeIn);

            % pass debug plotting information
            Data.Debug.OutlierRemoval.Noise(i) = median(Noise);
            Data.Debug.OutlierRemoval.SpikeIn(i) = median(SpikeIn);
        end

        % get running pressures
        P1_Pressure(:) = Data.SetPs(:,1);
        P1_Pressure_Uq(:) = unique(P1_Pressure);

        % set default outlier gating
        Best.index(:) = false(numel(Data.AcqIDUq),1);
        Best.num = sum(Best.index);
        Best.Ps = [];
        Best.TT = [];
        Best.CV = [];
        Best.SI = [];

        index.pressure = [];
        index.TT = [];
        index.CV = [];
        index.SI = [];

        % cycle through each acquisition P1 pressure
        for i = 1:numel(P1_Pressure_Uq)
            index.pressure(:,i) = P1_Pressure==P1_Pressure_Uq(i);
        end

        % cycle through each transit time gate
        iteration.TT = floor(min(SpikeInTT)) : 0.2 : ceil(max(SpikeInTT));
        for i = 1:numel(iteration.TT )
            index.TT(:,i) = SpikeInTT >= iteration.TT(i) & SpikeInTT <= iteration.TT(i)+getprefRPSPASS('RPSPASS','Threshold_SpikeIn_TT');
        end

        iteration.CV = min(CVs):0.1:ceil(max(CVs));
        for i = 1:numel(iteration.CV)
            index.CV(:,i) = CVs >= iteration.CV(i) & CVs <= iteration.CV(i)+getprefRPSPASS('RPSPASS','Threshold_SpikeIn_CV');
        end

        iteration.SI = min(SI) : 0.1 : ceil(max(SI));
        for i = 1:numel(iteration.SI)
            index.SI(:,i) = SI >= iteration.SI(i) & SI <= iteration.SI(i)+getprefRPSPASS('RPSPASS','Threshold_SpikeIn_SI');
        end

        iteration.TTSN = min(SpikeInTT2SN) : 0.1 : ceil(max(SpikeInTT2SN));
        for i = 1:numel(iteration.TTSN)
            index.TTSN(:,i) = SpikeInTT2SN >= iteration.TTSN(i) & SpikeInTT2SN <= iteration.TTSN(i)+getprefRPSPASS('RPSPASS','Threshold_SpikeIn_TTSN');
        end

        Best.NoCombs = numel(P1_Pressure_Uq)*numel(iteration.TT)*numel(iteration.CV)*numel(iteration.SI)*numel(iteration.TTSN);

        for i = 1:numel(P1_Pressure_Uq)
            thresh.pressure = sum([index.pressure(:,i)],2)==1;
            if sum( thresh.pressure ) > 1
                for ii = 1:numel(iteration.TT)
                    thresh.TT = sum([index.pressure(:,i) index.TT(:,ii)],2)==2;
                    if sum( thresh.TT ) > 1
                        for iii = 1:numel(iteration.CV)
                            thresh.CV = sum([index.pressure(:,i) index.TT(:,ii) index.CV(:,iii)],2)==3;
                            if sum( thresh.CV ) > 1
                                for iv = 1:numel(iteration.SI)
                                    thresh.SI = sum([index.pressure(:,i) index.TT(:,ii) index.CV(:,iii) index.SI(:,iv)],2)==4;
                                    if sum( thresh.SI ) > 1
                                        for v = 1:numel(iteration.TTSN)
                                            comp_index = sum([index.pressure(:,i) index.TT(:,ii) index.CV(:,iii) index.SI(:,iv) index.TTSN(:,v)],2)==5;
                                            tot_events = sum(comp_index);
                                            if tot_events > Best.num
                                                Best.index = comp_index;
                                                Best.num = sum(Best.index);
                                                Best.Ps = P1_Pressure_Uq(i);
                                                Best.TT =  [iteration.TT(ii)  (iteration.TT(ii)   + getprefRPSPASS('RPSPASS','Threshold_SpikeIn_TT'))];
                                                Best.CV =  [iteration.CV(iii) (iteration.CV(iii)  + getprefRPSPASS('RPSPASS','Threshold_SpikeIn_CV'))];
                                                Best.SI =  [iteration.SI(iv)  (iteration.SI(iv)   + getprefRPSPASS('RPSPASS','Threshold_SpikeIn_SI'))];
                                                Best.TTSN =  [iteration.TTSN(v)  (iteration.TTSN(v)   + getprefRPSPASS('RPSPASS','Threshold_SpikeIn_TTSN'))];
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        [~,NoiseSpikeInRatio_Outliers] = rmoutliers(NoiseSpikeInRatio(Best.index),'median');
        indexInt = find(Best.index);
        Best.index(indexInt(NoiseSpikeInRatio_Outliers)) = false;

        timegate = false(size(Data.AcqID));
        AcqIDind = unique(find(~Best.index));

        for i = 1:numel(AcqIDind)
            timegate = or(timegate, (Data.AcqID(:)==AcqIDind(i)));
        end

        Data.outliers = timegate;
        Data.RPSPASS.FailedAcq = ~Best.index;


        % pass debug plotting information
        Data.Debug.OutlierRemoval.SI = SI;
        Data.Debug.OutlierRemoval.CV = CVs;
        Data.Debug.OutlierRemoval.NoiseEvents = NoiseEvents;
        Data.Debug.OutlierRemoval.NoiseSpikeInRatio = NoiseSpikeInRatio;
        Data.Debug.OutlierRemoval.NoiseSpikeInRatio_Outliers = NoiseSpikeInRatio_Outliers;
        Data.Debug.OutlierRemoval.SpikeInTT = SpikeInTT;
        Data.Debug.OutlierRemoval.SpikeInTT2SN = SpikeInTT2SN;
        Data.Debug.OutlierRemoval.Best = Best;


    otherwise
        Report(FileID,'Outlier Removal') = {'Off'};
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

Data.SpikeInInd = Data.diam >= Data.SpikeInGateMinNorm & Data.diam <= Data.SpikeInGateMaxNorm;
% create raw indexing variables of processed data for downstream use and export
Data.Indices.Events_SpikeInRemoved = sum([~Data.SpikeInInd(:), ~Data.Indices.NoiseInd(:)],2) == 2;

switch Data.RPSPASS.SpikeInUsed
    case 'Yes'
        Data.Indices.Events_OutlierRemoved = sum([~Data.outliers, ~Data.Indices.NoiseInd(:)],2) == 2;
        Data.Indices.Events_OutlierSpikeinRemoved = sum([~Data.SpikeInInd, ~Data.outliers, ~Data.Indices.NoiseInd(:)],2) == 3;
        Data.Indices.SpikeIn_OutlierRemoved = sum([Data.SpikeInInd, ~Data.outliers, ~Data.Indices.NoiseInd(:)],2) == 3;
end



end
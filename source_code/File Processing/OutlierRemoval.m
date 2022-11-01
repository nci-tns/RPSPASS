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

        % check if P1 pressure outlier removal is turned on
        if getprefRPSPASS('RPSPASS','OutlierRemoval_Pressure') == 1
            iteration.pressure(:) = unique(P1_Pressure);
            for i = 1:numel(iteration.pressure) % cycle through each acquisition P1 pressure
                index.pressure(:,i) = P1_Pressure==iteration.pressure(i);
            end
        end

        % check if TT outlier removal is turned on
        if getprefRPSPASS('RPSPASS','OutlierRemoval_TransitTime') == 1
            iteration.TT = testRange(SpikeInTT, getprefRPSPASS('RPSPASS','Threshold_SpikeIn_TT'));
            for i = 1:numel(iteration.TT ) % cycle through each transit time gate
                index.TT(:,i) = SpikeInTT >= iteration.TT(i) & SpikeInTT <= iteration.TT(i)+getprefRPSPASS('RPSPASS','Threshold_SpikeIn_TT');
            end
        end

        % check if CV outlier removal is turned on
        if getprefRPSPASS('RPSPASS','OutlierRemoval_CV') == 1
             iteration.CV = testRange(CVs, getprefRPSPASS('RPSPASS','Threshold_SpikeIn_CV'));
            for i = 1:numel(iteration.CV)  % cycle through each CV gate
                index.CV(:,i) = CVs >= iteration.CV(i) & CVs <= iteration.CV(i)+getprefRPSPASS('RPSPASS','Threshold_SpikeIn_CV');
            end
        end

        % check if SI outlier removal is turned on
        if getprefRPSPASS('RPSPASS','OutlierRemoval_SI') == 1
             iteration.SI = testRange(SI, getprefRPSPASS('RPSPASS','Threshold_SpikeIn_SI'));
            for i = 1:numel(iteration.SI)  % cycle through each SI gate
                index.SI(:,i) = SI >= iteration.SI(i) & SI <= iteration.SI(i)+getprefRPSPASS('RPSPASS','Threshold_SpikeIn_SI');
            end
        end

        % check if TTSN outlier removal is turned on
        if getprefRPSPASS('RPSPASS','OutlierRemoval_TTSN') == 1
             iteration.TTSN = testRange(SpikeInTT2SN, getprefRPSPASS('RPSPASS','Threshold_SpikeIn_TTSN'));
            for i = 1:numel(iteration.TTSN) % cycle through each TTSN gate
                index.TTSN(:,i) = SpikeInTT2SN >= iteration.TTSN(i) & SpikeInTT2SN <= iteration.TTSN(i)+getprefRPSPASS('RPSPASS','Threshold_SpikeIn_TTSN');
            end
        end

        % obtain fields being processed
        IndexFields = fields(iteration);
        test.fieldNo = numel(IndexFields); % obtain number of fields
        test.thresholdSets = getprefRPSPASS('RPSPASS','Threshold_Sets');

        % remove any indices that have less than the number of threshold
        % sets within the threshold range for that parameter
        for i = 1:numel(IndexFields)
            remove = sum(index.(IndexFields{1}),1) < test.thresholdSets;
            iteration.(IndexFields{i})(remove) = [];
            index.(IndexFields{i})(:,remove) = [];
            index.array{i} = 1:size(index.(IndexFields{i}),2); % create an array for each unique index field
        end

        index.uniquecomb = combvec(index.array{:})'; % derive all possible combinations of each index field

        [Best]=OutlierRemoval_ProcessCombinations(iteration, index, IndexFields, test);

        % remove spike-in to non-spikein events that using median absolute
        % deviation
        [~,NoiseSpikeInRatio_Outliers] = rmoutliers(NoiseSpikeInRatio(Best.index),'median');
        indexInt = find(Best.index);
        Best.index(indexInt(NoiseSpikeInRatio_Outliers)) = false; % overwrite best index

        % use outlier set index to create a per event index
        timegate = false(size(Data.AcqID));
        AcqIDind = unique(find(~Best.index));

        for i = 1:numel(AcqIDind)
            timegate = or(timegate, (Data.AcqID(:)==AcqIDind(i)));
        end

        Data.outliers = timegate; % save per event failed acquisitions
        Data.Indices.NotOutliers = ~timegate; % save per event passed acquisitions
        Data.RPSPASS.FailedAcq = ~Best.index; % save failed set acquistions

        % if debug mode is turned on, save variables for debug outputs
        switch getprefRPSPASS('RPSPASS','debugSelected')
            case 'on'
                % pass debug plotting information
                Data.Debug.OutlierRemoval.SI = SI;
                Data.Debug.OutlierRemoval.CV = CVs;
                Data.Debug.OutlierRemoval.NoiseEvents = NoiseEvents;
                Data.Debug.OutlierRemoval.NoiseSpikeInRatio = NoiseSpikeInRatio;
                Data.Debug.OutlierRemoval.NoiseSpikeInRatio_Outliers = NoiseSpikeInRatio_Outliers;
                Data.Debug.OutlierRemoval.SpikeInTT = SpikeInTT;
                Data.Debug.OutlierRemoval.SpikeInTT2SN = SpikeInTT2SN;
                Data.Debug.OutlierRemoval.Best = Best;
        end

    otherwise
        Report(FileID,'Outlier Removal') = {'Off'};
        Data.outliers = false(size(Data.AcqID)); % save per event failed acquisitions
        Data.Indices.NotOutliers = true(size(Data.AcqID)); % save per event passed acquisitions
end

% create normalize gate for removing spike-in bead and reporting statistics
% based on spike-in exclusion
switch Data.RPSPASS.SpikeInUsed
    case 'Yes'
        % if diam calibration passed
        if ~strcmp(Report{FileID,'Diameter Calibration'},'Failed')
            Data.SpikeInGateMaxNorm = max(Data.SpikeInGateMax(~Data.RPSPASS.FailedAcq) .* Data.CaliFactor(~Data.RPSPASS.FailedAcq));
            Data.SpikeInGateMinNorm = min(Data.SpikeInGateMin(~Data.RPSPASS.FailedAcq) .* Data.CaliFactor(~Data.RPSPASS.FailedAcq));
            Data.SpikeInInd = Data.diam >= Data.SpikeInGateMinNorm & Data.diam <= Data.SpikeInGateMaxNorm;
        else % if failed
            Data.SpikeInGateMaxNorm = [];
            Data.SpikeInGateMinNorm = [];
        end
end



% create raw indexing variables of processed data for downstream use and export
Data.Indices.Events_OutlierRemoved = sum([~Data.outliers, ~Data.Indices.NoiseInd(:)],2) == 2;

% create gating indices for downstream use
switch Data.RPSPASS.SpikeInUsed
    case 'Yes'
        Data.Indices.Events_SpikeInRemoved = sum([~Data.SpikeInInd(:), ~Data.Indices.NoiseInd(:)],2) == 2;
        
        Data.Indices.Events_OutlierSpikeinRemoved = sum([~Data.SpikeInInd, ~Data.outliers, ~Data.Indices.NoiseInd(:)],2) == 3;
        Data.Indices.SpikeIn_OutlierRemoved = sum([Data.SpikeInInd, ~Data.outliers, ~Data.Indices.NoiseInd(:)],2) == 3;
        
        NoiseTTSN = Data.TT2SN > getprefRPSPASS('RPSPASS','CohortAnalysis_MinTTSN_Noise') ....
            & Data.TT2SN < getprefRPSPASS('RPSPASS','CohortAnalysis_MinTTSN_Events') & ~Data.outliers ...
            & Data.diam < Data.SpikeInGateMinNorm;

        Data.Threshold.diam = mean(Data.diam(NoiseTTSN))+(std(Data.diam(NoiseTTSN))*2);

        Data.Indices.Events_OutlierRemovedDiamGate = sum([~Data.outliers(:),...
            Data.TT2SN(:)>getprefRPSPASS('RPSPASS','CohortAnalysis_MinTTSN_Events'),...
            Data.diam(:)>Data.Threshold.diam],2)==3;

        Data.Indices.Events_OutlierSpikeinRemovedDiamGate = and(Data.Indices.Events_OutlierRemovedDiamGate, ~Data.SpikeInInd(:));
    otherwise

        Data.Indices.Events_SpikeInRemoved = ~Data.Indices.NoiseInd(:);

        Data.Indices.Events_OutlierSpikeinRemoved = sum([~Data.outliers, ~Data.Indices.NoiseInd(:)],2) == 2;
        Data.Indices.SpikeIn_OutlierRemoved = sum([ ~Data.outliers, ~Data.Indices.NoiseInd(:)],2) == 2;

        NoiseTTSN = Data.TT2SN > getprefRPSPASS('RPSPASS','CohortAnalysis_MinTTSN_Noise') ....
            & Data.TT2SN < getprefRPSPASS('RPSPASS','CohortAnalysis_MinTTSN_Events') & ~Data.outliers;

        Data.Threshold.diam = mean(Data.diam(NoiseTTSN))+(std(Data.diam(NoiseTTSN))*2);

        Data.Indices.Events_OutlierRemovedDiamGate = sum([~Data.outliers(:),...
            Data.TT2SN(:)>getprefRPSPASS('RPSPASS','CohortAnalysis_MinTTSN_Events'),...
            Data.diam(:)>Data.Threshold.diam],2)==3;

        Data.Indices.Events_OutlierSpikeinRemovedDiamGate = Data.Indices.Events_OutlierRemovedDiamGate;

end



end
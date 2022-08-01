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

        % check if P1 pressure outlier removal is turned on
        if getprefRPSPASS('RPSPASS','OutlierRemoval_Pressure') == 1
            iteration.pressure(:) = unique(P1_Pressure);
            for i = 1:numel(iteration.pressure) % cycle through each acquisition P1 pressure
                index.pressure(:,i) = P1_Pressure==iteration.pressure(i);
            end
        end

        % check if TT outlier removal is turned on
        if getprefRPSPASS('RPSPASS','OutlierRemoval_TransitTime') == 1
            iteration.TT = floor(min(SpikeInTT)) : 0.2 : ceil(max(SpikeInTT));
            for i = 1:numel(iteration.TT ) % cycle through each transit time gate
                index.TT(:,i) = SpikeInTT >= iteration.TT(i) & SpikeInTT <= iteration.TT(i)+getprefRPSPASS('RPSPASS','Threshold_SpikeIn_TT');
            end
        end

        % check if CV outlier removal is turned on
        if getprefRPSPASS('RPSPASS','OutlierRemoval_CV') == 1
            iteration.CV = min(CVs):0.1:ceil(max(CVs));
            for i = 1:numel(iteration.CV)  % cycle through each CV gate
                index.CV(:,i) = CVs >= iteration.CV(i) & CVs <= iteration.CV(i)+getprefRPSPASS('RPSPASS','Threshold_SpikeIn_CV');
            end
        end

        % check if SI outlier removal is turned on
        if getprefRPSPASS('RPSPASS','OutlierRemoval_SI') == 1
            iteration.SI = min(SI) : 0.1 : ceil(max(SI));
            for i = 1:numel(iteration.SI)  % cycle through each SI gate
                index.SI(:,i) = SI >= iteration.SI(i) & SI <= iteration.SI(i)+getprefRPSPASS('RPSPASS','Threshold_SpikeIn_SI');
            end
        end

        % check if TTSN outlier removal is turned on
        if getprefRPSPASS('RPSPASS','OutlierRemoval_TTSN') == 1
            iteration.TTSN = min(SpikeInTT2SN) : 0.1 : ceil(max(SpikeInTT2SN));
            for i = 1:numel(iteration.TTSN) % cycle through each TTSN gate
                index.TTSN(:,i) = SpikeInTT2SN >= iteration.TTSN(i) & SpikeInTT2SN <= iteration.TTSN(i)+getprefRPSPASS('RPSPASS','Threshold_SpikeIn_TTSN');
            end
        end

        % obtain fields being processed
        IndexFields = fields(iteration);
        test.fieldNo = numel(IndexFields); % obtain number of fields

        % save to local variable for faster processing in recursive loop
        test.thresholdSets = getprefRPSPASS('RPSPASS','Threshold_Sets'); 

        % remove any indices that have less than the number of threshold
        % sets within the threshold range for that parameter
        for i = 1:numel(IndexFields)
            remove = sum(index.(IndexFields{1}),1) < test.thresholdSets; 
            iteration.(IndexFields{i})(remove) = [];
            index.(IndexFields{i})(remove,:) = []; 
            index.array{i} = 1:size(index.(IndexFields{i}),2); % create an array for each unique index field
        end

        index.uniquecomb = combvec(index.array{:})'; % derive all possible combinations of each index field
        Best.NoCombs = size(index.uniquecomb,1); % get total number of unique combinations

%         % test each unique combination to maximize sets meeting threshold
%         % criteria within range
%         for i = 1:Best.NoCombs
%             test.array = [];
%             proceed = true;
% 
%             % build testing array for each unique combination
%             for ii = 1:numel(IndexFields) 
%                 test.array = [test.array, index.(IndexFields{ii})(:,index.uniquecomb(i,ii))];
%                 if sum(sum(test.array,2) == size(test.array,2)) < test.thresholdSets
%                     proceed = false;
%                     break
%                 end
%             end
% 
%             if proceed == true
%                 test.index = sum(test.array,2)==test.fieldNo;
%                 test.events = sum(test.index);
% 
%                 % test array has more passing sets than current best save it
%                 if test.events > Best.num 
%                     Best.index = test.index;
%                     Best.num = sum(Best.index);
%                     Best.uniqueComb = index.uniquecomb(i,:);
%                 end
%             end
%         end

        %%
        num = 0;
tic
        parfor i = 1:Best.NoCombs
           array = [];
            proceed = true;

            % build testing array for each unique combination
            for ii = 1:numel(IndexFields) 
               array = [array, index.(IndexFields{ii})(:,index.uniquecomb(i,ii))];
                if sum(sum(array,2) == size(array,2)) < test.thresholdSets
                    proceed = false;
                    break
                end
            end

            if proceed == true
                test_index = sum(array,2)==test.fieldNo;
                test_events = sum(test_index);

                % test array has more passing sets than current best save it
                if test_events > num 
                    Best_index = test_index;
                    Best_num = sum(Best_index);
                    Best_uniqueComb = index.uniquecomb(i,:);
                end
            end
        end
toc
        %%

        % obtain threshold values for each tested criteria
        for ii = 1:numel(IndexFields)
            Best.(IndexFields{ii}) = iteration.(IndexFields{ii})(Best.uniqueComb(ii));
        end

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
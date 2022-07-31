function [Report] = createReport(FileID, Report, Data)

CoFact_pl2mL = 1e9;
PassedSetIDs = Data.AcqIDUq(~Data.RPSPASS.FailedAcq);

Set.vol = Data.acqvol(~Data.RPSPASS.FailedAcq).*(1/CoFact_pl2mL);
fields = {'Unprocessed'};
indexNames = {'Unprocessed'};

return
switch getprefRPSPASS('RPSPASS','outlierremovalSelected')
    case 'on'
        switch Data.RPSPASS.SpikeInUsed
            case 'Yes'
                fields = [fields, {'NotOutliers','NoNoise','Events_OutlierRemoved','Events_OutlierSpikeinRemoved','SpikeIn_OutlierRemoved'}];
                indexNames = [indexNames, {'NotOutliers','NotNoise','Events_OutlierRemoved','Events_OutlierSpikeinRemoved','SpikeIn_OutlierRemoved'}];
            case 'No'
                fields = [fields, {'NotOutliers','NoNoise','Events_OutlierRemoved','Events_OutlierSpikeinRemoved','SpikeIn_OutlierRemoved'}];
                indexNames = [indexNames, {'NotOutliers','NotNoise','Events_OutlierRemoved','Events_OutlierSpikeinRemoved','SpikeIn_OutlierRemoved'}];
        end
    case 'off'
        switch Data.RPSPASS.SpikeInUsed
            case 'Yes'
                fields = [fields, {'NotOutliers','NoNoise','Events_OutlierRemoved','Events_OutlierSpikeinRemoved','SpikeIn_OutlierRemoved'}];
                indexNames = [indexNames, {'NotOutliers','NotNoise','Events_OutlierRemoved','Events_OutlierSpikeinRemoved','SpikeIn_OutlierRemoved'}];
            case 'No'

                fields = [fields, {'NoNoise'}];
                indexNames = [indexNames, {'NotNoise'}];
        end
end


for i = 1:numel(PassedSetIDs)
    Set.Raw.Events(i) = sum(Data.AcqID(Data.Indices.(indexNames{i})) == PassedSetIDs(i));
end

for i = 1:numel(fields)
    Set.(fields{i}).Conc.Raw = Set.(fields{i}).Events(:)./Set.vol(:);
    Set.(fields{i}).Conc.Mean = mean(Set.(fields{i}).Conc.Raw);
    Set.(fields{i}).Conc.SD =  std(Set.(fields{i}).Conc.Raw);
end

vol = sum(Set.vol); % gated population volume in mL

ungate_vol = Data.cumvol(end); % ungated volume in pL

Report{FileID,'Unprocessed Total Events'}{1} = Data.UngatedTotalEvents;
Report{FileID,'Unprocessed Total Volume (pL)'}{1} = round(ungate_vol,1); % total volume in nL
Report{FileID,'Unprocessed Total Conc (mL^-1)'}{1} = round(Data.UngatedTotalEvents/(ungate_vol*(1/CoFact_pl2mL)),0);

ind_gate = and(~Data.outliers,~Data.Indices.NoiseInd); % sample gated population

switch Data.RPSPASS.SpikeInUsed
    case 'Yes'
        SpikeIn_IndGate = Data.diam(ind_gate) > Data.SpikeInGateMinNorm & Data.diam(ind_gate) < Data.SpikeInGateMaxNorm;

        Report{FileID,'IndGate Spike-in Events'}{1} = sum(SpikeIn_IndGate);
        Report{FileID,'IndGate Non-spike-in Events'}{1} = sum(Data.diam(ind_gate) < Data.SpikeInGateMinNorm);
%         Report{FileID,'IndGate Diameter Gate (nm)'}{1} = num2str(round([Data.boundary.diam(1) Data.SpikeInGateMinNorm Data.SpikeInGateMinNorm Data.boundary.diam(4)]));

        % concetratraion reporting
        if isempty(Data.RPSPASS.SpikeInConc) % if spike concentration not used
            Report{FileID,'IndGate Sample Conc (mL^-1)'}{1} = round(sum(~SpikeIn_IndGate)/vol,0);
            Report{FileID,'IndGate Spike-In Conc (mL^1)'}{1} = round(sum(SpikeIn_IndGate)/vol,0);
        else % if spike concentration is used
            ConcCalFactor_IndGate = (sum(SpikeIn_IndGate)/vol)/Data.RPSPASS.SpikeInConc;
            Report{FileID,'IndGate Sample Conc (mL^-1)'}{1} = round(sum((~SpikeIn_IndGate)/vol)/ ConcCalFactor_IndGate ,0);
            Report{FileID,'IndGate Spike-In Conc (mL^1)'}{1} = round(sum((SpikeIn_IndGate)/vol)/ ConcCalFactor_IndGate,0);
        end

    case 'No'
        Report{FileID,'IndGate Non-spike-in Events'}{1} = sum(ind_gate);
        Report{FileID,'IndGate Sample Conc (mL^-1)'}{1} = round(sum(ind_gate)/vol,0);
        Report{FileID,'IndGate Spike-In Conc (mL^1)'}{1} = 'N/A';
        Report{FileID,'IndGate Diameter Gate (nm)'}{1} = num2str(round(Data.boundary.diam));
end

Report{FileID,'IndGate Total Volume (pL)'}{1} = round(vol*CoFact_pl2mL,1); % total volume in nL
% Report{FileID,'IndGate Transit Time Gate (µs)'}{1} = num2str(round(Data.boundary.ttime));


%% if cohort gating is turned on
switch getprefRPSPASS('RPSPASS','cohortAnalysisSelected')
    case 'on'
        coh_gate = and(~Data.outliers,~Data.Indices.NoiseInd); % cohort gated population

        switch Data.RPSPASS.SpikeInUsed
            case 'Yes'
                SpikeIn_CoGate = Data.diam(coh_gate) > Data.SpikeInGateMinNorm & Data.diam(coh_gate) < Data.SpikeInGateMaxNorm;

                Report{FileID,'CoGate Spike-in Events'}{1} = sum(SpikeIn_CoGate);
                Report{FileID,'CoGate Non-spike-in Events'}{1} = sum(Data.diam(coh_gate) < Data.RPSPASS.CohortGate.minSpike);
                Report{FileID,'CoGate Diameter Gate (nm)'}{1} = num2str(round([Data.RPSPASS.CohortGate.diam(1) Data.RPSPASS.CohortGate.minSpike Data.RPSPASS.CohortGate.minSpike Data.RPSPASS.CohortGate.diam(4)]));

                % concetratraion reporting
                if isempty(Data.RPSPASS.SpikeInConc) % if spike concentration not used
                    Report{FileID,'CoGate Sample Conc (mL^-1)'}{1} = round(sum(~SpikeIn_CoGate)/vol,0);
                    Report{FileID,'CoGate Spike-In Conc (mL^1)'}{1} = round(sum(SpikeIn_CoGate)/vol,0);
                else % if spike concentration is used
                    ConcCalFactor_CoGate =  (sum(SpikeIn_CoGate)/vol)/Data.RPSPASS.SpikeInConc;
                    Report{FileID,'CoGate Sample Conc (mL^-1)'}{1} = round(sum((~SpikeIn_CoGate)/vol)/ ConcCalFactor_CoGate,0);
                    Report{FileID,'CoGate Spike-In Conc (mL^1)'}{1} = round(sum((SpikeIn_CoGate)/vol)/ ConcCalFactor_CoGate,0);
                end

            case 'No'
                Report{FileID,'CoGate Non-spike-in Events'}{1} = sum(coh_gate);
                Report{FileID,'CoGate Sample Conc (mL^-1)'}{1} = round(sum(coh_gate)/vol,0);
                Report{FileID,'CoGate Spike-In Conc (mL^1)'}{1} = 'N/A';
                Report{FileID,'CoGate Diameter Gate (nm)'}{1} = num2str(round(Data.RPSPASS.CohortGate.diam));
        end

        Report{FileID,'CoGate Total Volume (pL)'}{1} = round(vol*CoFact_pl2mL,1); % total volume in nL
        Report{FileID,'CoGate Transit Time Gate (µs)'}{1} = num2str(round(Data.boundary.ttime));
end

end
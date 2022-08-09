function [Report, Set] = createReport(FileID, Report, Data)

CoFact_pl2mL = 1e9;
PassedSetIDs = Data.AcqIDUq(~Data.RPSPASS.FailedAcq);

Set.vol = Data.acqvol(~Data.RPSPASS.FailedAcq).*(1/CoFact_pl2mL);
fields = {'Unprocessed'};
indexNames = {'Unprocessed'};

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

if isfield(Data.Indices,'Cohort_Events_OutliersSpikeinRemoved')
    fields = [fields, {'Cohort_Events_OutliersSpikeinRemoved'}];
    indexNames = [indexNames, {'Cohort_Events_OutliersSpikeinRemoved'}];
end

for i = 1:numel(fields)
    for ii = 1:numel(PassedSetIDs)
        Set.(fields{i}).Events(ii) = sum(Data.AcqID(Data.Indices.(indexNames{i})) == PassedSetIDs(ii));
    end
end

for i = 1:numel(fields)
    Set.(fields{i}).Conc.Raw = Set.(fields{i}).Events(:)./Set.vol(:);
    Set.(fields{i}).Conc.Mean = mean(Set.(fields{i}).Conc.Raw);
    Set.(fields{i}).Conc.SD =  std(Set.(fields{i}).Conc.Raw);
end

vol = sum(Set.vol); % gated population volume in mL

ungate_vol = Data.cumvol(end); % ungated volume in pL

Report{FileID,'Unprocessed Total Events'}{1} = sum(Set.Unprocessed.Events);
Report{FileID,'Unprocessed Total Volume (pL)'}{1} = round(ungate_vol,1); % total volume in nL
Report{FileID,'Unprocessed Total Conc Mean (mL^-1)'}{1} = round(Set.Unprocessed.Conc.Mean,0);
Report{FileID,'Unprocessed Total Conc SD (mL^-1)'}{1} = round(Set.Unprocessed.Conc.SD,0);

switch Data.RPSPASS.SpikeInUsed
    case 'Yes'

        % concetratraion reporting
        if isempty(Data.RPSPASS.SpikeInConc)
            Set.ConcCalFactor_IndGate = 1; % if spike concentration not used
        else
            Set.ConcCalFactor_IndGate = Set.SpikeIn_OutlierRemoved.Conc.Mean/Data.RPSPASS.SpikeInConc;
        end

        % sample concentration reporting
        Report{FileID,'IndGate Non-spike-in Events'}{1} = sum(Set.Events_OutlierSpikeinRemoved.Events);
        Report{FileID,'CoGate Non-spike-in Events'}{1} = sum(Set.Events_OutlierSpikeinRemoved.Events);

        Report{FileID,'IndGate Sample Conc Mean (mL^-1)'}{1} = round(Set.Events_OutlierSpikeinRemoved.Conc.Mean/ Set.ConcCalFactor_IndGate,0);
        Report{FileID,'IndGate Sample Conc SD (mL^-1)'}{1} = round(Set.Events_OutlierSpikeinRemoved.Conc.SD / Set.ConcCalFactor_IndGate,0);

        if isfield(Data.Indices,'Cohort_Events_OutliersSpikeinRemoved')
            Report{FileID,'CoGate Sample Conc Mean (mL^-1)'}{1} = round(Set.Cohort_Events_OutliersSpikeinRemoved.Conc.Mean / Set.ConcCalFactor_IndGate,0);
            Report{FileID,'CoGate Sample Conc SD (mL^-1)'}{1} = round(Set.Cohort_Events_OutliersSpikeinRemoved.Conc.SD / Set.ConcCalFactor_IndGate,0);
        end

        % spike-in concentration reporting
        Report{FileID,'IndGate Spike-in Events'}{1} = sum(Set.SpikeIn_OutlierRemoved.Events);
        Report{FileID,'CoGate Spike-in Events'}{1} = sum(Set.SpikeIn_OutlierRemoved.Events);

        Report{FileID,'IndGate Spike-In Conc Mean (mL^-1)'}{1} = round(Set.SpikeIn_OutlierRemoved.Conc.Mean / Set.ConcCalFactor_IndGate,0);
        Report{FileID,'IndGate Spike-In Conc SD (mL^-1)'}{1} = round(Set.SpikeIn_OutlierRemoved.Conc.SD / Set.ConcCalFactor_IndGate,0);

        Report{FileID,'CoGate Spike-In Conc Mean (mL^-1)'}{1} = round(Set.SpikeIn_OutlierRemoved.Conc.Mean / Set.ConcCalFactor_IndGate,0);
        Report{FileID,'CoGate Spike-In Conc SD (mL^-1)'}{1} = round(Set.SpikeIn_OutlierRemoved.Conc.SD / Set.ConcCalFactor_IndGate,0);

    case 'No'
        Report{FileID,'IndGate Non-spike-in Events'}{1} = sum(Set.Events_OutlierRemoved.Events);

        Report{FileID,'IndGate Sample Conc Mean (mL^-1)'}{1} = round(Set.Events_OutlierRemoved.Conc.Mean,0);
        Report{FileID,'IndGate Sample Conc SD (mL^-1)'}{1} = round(Set.Events_OutlierRemoved.Conc.SD,0);

        Report{FileID,'IndGate Spike-In Conc Mean (mL^-1)'}{1} = 'N/A';
        Report{FileID,'IndGate Spike-In Conc SD (mL^-1)'}{1} = 'N/A';

        Report{FileID,'IndGate Diameter Gate (nm)'}{1} = num2str(round(Data.boundary.diam));

        if isfield(Data.Indices,'Cohort_Events_OutliersSpikeinRemoved')
            Report{FileID,'CoGate Sample Conc Mean (mL^-1)'}{1} = round(Set.Cohort_Events_OutliersSpikeinRemoved.Conc.Mean,0);
            Report{FileID,'CoGate Spike-In Conc SD (mL^-1)'}{1} = round(Set.Cohort_Events_OutliersSpikeinRemoved.Conc.SD,0);
        end

end

% total volume in nL
Report{FileID,'IndGate Total Volume (pL)'}{1} = round(vol*CoFact_pl2mL,1); 
Report{FileID,'CoGate Total Volume (pL)'}{1} = round(vol*CoFact_pl2mL,1);

end
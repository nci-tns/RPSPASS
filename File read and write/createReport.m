function [Report] = createReport(FileID, Report, Data, Gates)

ind_gate = and(~Data.outliers,Data.Ind_gate); % sample gated population
coh_gate = and(~Data.outliers,Data.Coh_gate); % cohort gated population

CoFact_pl2mL = 1e9;

vol = sum(Data.acqvol(~Data.RPSPASS.FailedAcq))*(1/CoFact_pl2mL); % gated population volume in mL
ungate_vol = Data.cumvol(end); % ungated volume in pL

Report{FileID,'Unprocessed Total Events'}{1} = Data.UngatedTotalEvents;
Report{FileID,'Unprocessed Total Volume (pL)'}{1} = round(ungate_vol,1); % total volume in nL
Report{FileID,'Unprocessed Total Conc (mL^-1)'}{1} = round(Data.UngatedTotalEvents/(ungate_vol*(1/CoFact_pl2mL)),0);

switch Data.RPSPASS.SpikeInUsed
    case 'Yes'
        SpikeIn_IndGate = Data.diam(ind_gate) > Data.SpikeInGateMinNorm & Data.diam(ind_gate) < Data.SpikeInGateMaxNorm;
        SpikeIn_CoGate = Data.diam(coh_gate) > Data.SpikeInGateMinNorm & Data.diam(coh_gate) < Data.SpikeInGateMaxNorm;

        Report{FileID,'IndGate Spike-in Events'}{1} = sum(SpikeIn_IndGate);
        Report{FileID,'IndGate Non-spike-in Events'}{1} = sum(Data.diam(ind_gate) < Data.SpikeInGateMinNorm);
        Report{FileID,'IndGate Diameter Gate (nm)'}{1} = num2str(round([Data.boundary.diam(1) Data.SpikeInGateMinNorm Data.SpikeInGateMinNorm Data.boundary.diam(4)]));

        Report{FileID,'CoGate Spike-in Events'}{1} = sum(SpikeIn_CoGate);
        Report{FileID,'CoGate Non-spike-in Events'}{1} = sum(Data.diam(coh_gate) < Gates.minSpike);
        Report{FileID,'CoGate Diameter Gate (nm)'}{1} = num2str(round([Gates.diam(1) Gates.minSpike Gates.minSpike Gates.diam(4)]));

        % concetratraion reporting
        if isempty(Data.RPSPASS.SpikeInConc) % if spike concentration not used
            Report{FileID,'IndGate Sample Conc (mL^-1)'}{1} = round(sum(~SpikeIn_IndGate)/vol,0);
            Report{FileID,'IndGate Spike-In Conc (mL^1)'}{1} = round(sum(SpikeIn_IndGate)/vol,0);

            Report{FileID,'CoGate Sample Conc (mL^-1)'}{1} = round(sum(~SpikeIn_CoGate)/vol,0);
            Report{FileID,'CoGate Spike-In Conc (mL^1)'}{1} = round(sum(SpikeIn_CoGate)/vol,0);
        else % if spike concentration is used
            ConcCalFactor_IndGate = (sum(SpikeIn_IndGate)/vol)/Data.RPSPASS.SpikeInConc;
            ConcCalFactor_CoGate =  (sum(SpikeIn_CoGate)/vol)/Data.RPSPASS.SpikeInConc;

            Report{FileID,'IndGate Sample Conc (mL^-1)'}{1} = round(sum((~SpikeIn_IndGate)/vol)/ ConcCalFactor_IndGate ,0);
            Report{FileID,'IndGate Spike-In Conc (mL^1)'}{1} = round(sum((SpikeIn_IndGate)/vol)/ ConcCalFactor_IndGate,0);

            Report{FileID,'CoGate Sample Conc (mL^-1)'}{1} = round(sum((~SpikeIn_CoGate)/vol)/ ConcCalFactor_CoGate,0);
            Report{FileID,'CoGate Spike-In Conc (mL^1)'}{1} = round(sum((SpikeIn_CoGate)/vol)/ ConcCalFactor_CoGate,0);
        end

    case 'No'
        Report{FileID,'IndGate Non-spike-in Events'}{1} = sum(ind_gate);
        Report{FileID,'IndGate Sample Conc (mL^-1)'}{1} = round(sum(ind_gate)/vol,0);
        Report{FileID,'IndGate Spike-In Conc (mL^1)'}{1} = 'N/A';
        Report{FileID,'IndGate Diameter Gate (nm)'}{1} = num2str(round(Data.boundary.diam));

        Report{FileID,'CoGate Non-spike-in Events'}{1} = sum(coh_gate);
        Report{FileID,'CoGate Sample Conc (mL^-1)'}{1} = round(sum(coh_gate)/vol,0);
        Report{FileID,'CoGate Spike-In Conc (mL^1)'}{1} = 'N/A';
        Report{FileID,'CoGate Diameter Gate (nm)'}{1} = num2str(round(Gates.diam));
end

Report{FileID,'IndGate Total Volume (pL)'}{1} = round(vol*CoFact_pl2mL,1); % total volume in nL
Report{FileID,'IndGate Transit Time Gate (µs)'}{1} = num2str(round(Data.boundary.ttime));

Report{FileID,'CoGate Total Volume (pL)'}{1} = round(vol*CoFact_pl2mL,1); % total volume in nL
Report{FileID,'CoGate Transit Time Gate (µs)'}{1} = num2str(round(Data.boundary.ttime));

end
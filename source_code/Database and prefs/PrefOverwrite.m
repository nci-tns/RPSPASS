function PrefOverwrite(app)

PrefObj = jsondecode(app.HTML.Data);
fields = fieldnames(PrefObj);

if strcmp(PrefObj.Response, 'Save')
    for i = 1:numel(fields)

        if  strcmp(fields{i},'filelocatorSelected')
            Options = PrefObj.filelocatorOptions;
            Selection = PrefObj.filelocatorSelection;
            setprefRPSPASS('RPSPASS','filelocatorSelected', Options{Selection})

        elseif strcmp(fields{i},'outlierremovalSelected')
            Options = PrefObj.outlierremovalOptions;
            Selection = PrefObj.outlierremovalSelection;
            setprefRPSPASS('RPSPASS','outlierremovalSelected', Options{Selection})

        elseif strcmp(fields{i},'noiseremovalSelected')
            Options = PrefObj.noiseremovalOptions;
            Selection = PrefObj.noiseremovalSelection;
            setprefRPSPASS('RPSPASS','noiseremovalSelected', Options{Selection})

        elseif strcmp(fields{i},'diamcalitypeSelected')
            Options = PrefObj.diamcalitypeOptions;
            Selection = PrefObj.diamcalitypeSelection;
            setprefRPSPASS('RPSPASS','diamcalitypeSelected', Options{Selection})

        elseif strcmp(fields{i},'cohortAnalysisSelected')
            Options = PrefObj.cohortAnalysisOptions;
            Selection = PrefObj.cohortAnalysisSelection;
            setprefRPSPASS('RPSPASS','cohortAnalysisSelected', Options{Selection})

        elseif strcmp(fields{i},'debugSelected')
            Options = PrefObj.debugOptions;
            Selection = PrefObj.debugSelection;
            setprefRPSPASS('RPSPASS','debugSelected', Options{Selection})

        elseif strcmp(fields{i},'DynamicCalSpikeInThresh') || ...
                strcmp(fields{i},'StaticCalSpikeInThresh') || ...
                strcmp(fields{i},'Threshold_SpikeIn_CV') || ...
                strcmp(fields{i},'Threshold_SpikeIn_SI') || ...
                strcmp(fields{i},'Threshold_SpikeIn_TT') || ...
                strcmp(fields{i},'Threshold_SpikeIn_TTSN')

            setprefRPSPASS('RPSPASS',fields{i}, str2num(PrefObj.(fields{i})))

        else
            setprefRPSPASS('RPSPASS',fields{i}, PrefObj.(fields{i}))
        end

    end
    % reset the response preference
    setprefRPSPASS('RPSPASS','Response', '')
end

end
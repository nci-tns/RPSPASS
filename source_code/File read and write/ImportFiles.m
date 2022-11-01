function [status, message]=ImportFiles(app, filepath, mode)

% create default output variables
status = true;
message = '';
FailedFiles = [];

% create a timestamp for the analysis / output of files
timestamp = datestr(datetime('now'), 'yyyy-mm-dd HH:MM:SS');
timestamp_filename = replace(timestamp, ':', '-');

% save path to output dir for subscripting functions
setprefRPSPASS('RPSPASS','OutputDir',fullfile(filepath,['RPSPASS ', timestamp_filename]))

CohortOutput = getprefRPSPASS('RPSPASS','cohortAnalysisSelected'); % cohort analysis on/off

% create figure multipler for completion progression
switch CohortOutput
    case 'on'
        figMultiplier = 2;
    case 'off'
        figMultiplier = 1;
end

% if the filepath exists
if ~isequal(filepath,0)

    % switch to loading screen
    if isempty(mode) % user mode
        app.HTML.HTMLSource = 'Loading_Screen.html';
        app.HTML.Data = '0%';
        pause(0.5);
    else % developer mode
        if mode(1)==1
            app.HTML.HTMLSource = 'Loading_Screen.html';
            app.HTML.Data = '0%';
            pause(0.5);
        end
    end

    % put app at front
    figure(app.RPSPASS)

    % create temporary directory
    preferenceFolder_createTempDir()

    % load .h5 combined files only
    SelectedFolderInfo = dir(fullfile(filepath,'*.h5'));
    [Filenames, FileGroup, FileNo] = ObtainFilenames(natsort({SelectedFolderInfo.name}'));

    if numel(Filenames) > 0

        % create table for reporting
        TableHeaders = {'Filename', 'Sample Information','Sample Source','Sample Isolation','Sample Diluent','Spike-in information','Cartridge ID','Instrument Sheath Fluid',...
            'Diameter Calibration', 'Outlier Removal', 'FCS Creation','MAT Creation','CSV Creation','JSON Creation',...
            'Unprocessed Total Events','Unprocessed Total Volume (pL)','Unprocessed Total Conc Mean (mL^-1)','Unprocessed Total Conc SD (mL^-1)',...
            'IndGate Non-spike-in Events','IndGate Spike-in Events','IndGate Total Volume (pL)','IndGate Sample Conc Mean (mL^-1)','IndGate Sample Conc SD (mL^-1)','IndGate Spike-In Conc Mean (mL^-1)','IndGate Spike-In Conc SD (mL^-1)',...
            'CoGate Non-spike-in Events','CoGate Spike-in Events','CoGate Total Volume (pL)','CoGate Sample Conc Mean (mL^-1)','CoGate Sample Conc SD (mL^-1)','CoGate Spike-In Conc Mean (mL^-1)','CoGate Spike-In Conc SD (mL^-1)',...
            };

        % create report structure from table headers
        Report = cell2table(cell(FileNo,numel(TableHeaders)), 'VariableNames', TableHeaders); % convert TableHeaders cell array to Table format
        Report.('Filename') = Filenames(:); % add filenames to spreadsheet
        Report.('Dilution Factor') = ones(FileNo,1); % create a default dilution factor for spreadsheet concentration calculation

        %% process h5 files
        for i = 1:FileNo

            % turn on parallel computing
            Parallel_Computing()

            % set current filename for exporting files in subscript
            % functions
            setprefRPSPASS('RPSPASS','CurrFile',Filenames{i})


            % extract data from .h5 files for downstream processing
            [app,Data, Report] = ProcessH5File(app, filepath,Filenames{i}, Report, i, FileGroup);



            try % calibrate diameter
                [Data, Report] = DiamCalibration(app, Data, i, Report);
            catch
                Report(i,'Diameter Calibration') = {'Failed'};
            end


            %             try % remove outliers
            [Data,Report] = OutlierRemoval(Data, Report, i);
            %                 Report(i,'Outlier Removal') = {'Passed'};
            %             catch
            %                 Report(i,'Outlier Removal') = {'Failed'};
            %             end


            % output outlier removal debug plots
            Debug_Plots(Data, 'OutlierRemoval')

            if ~strcmp(Report{i,'Diameter Calibration'},'Failed')  % if diameter calibration passed

                % create output plots for file
                plot_QC_data(Data,'individual')

    
                % aggregate common LoDs for cohort gating
                Threshold.Diam.Min(i) =  Data.Threshold.diam;
                if isfield(Data,'SpikeInGateMinNorm')
                    if isempty(Data.SpikeInGateMinNorm)
                        Threshold.Diam.Max(i) =  max(Data.diam);
                    else
                        Threshold.Diam.Max(i) =  Data.SpikeInGateMinNorm;
                    end
                else
                    Threshold.Diam.Max(i) =  max(Data.diam);
                end
            else
                FailedFiles = [FailedFiles, i];
            end

            % save failed QC h5 file data as temporary .mat file for further gating
            % this will speed up analysis and save memory
            filename = ['Data_',num2str(i),'.mat'];
            preferenceFolder_saveTempDir(filename,Data)

            if isempty(mode) % update GUI progress
                app.HTML.Data = [num2str(round(100*(i/(FileNo*figMultiplier)),0)),'%'];
            else
                app.HTML.Data = [num2str(round(100*(mode(1)/mode(2))*(i/(FileNo*figMultiplier)),1)),'%'];
            end
        end

        % check threshold diameters exist and find maximum for cohort gate
        if ~isempty(Threshold.Diam)
            Threshold.Cohort.diam = [max(Threshold.Diam.Min) min(Threshold.Diam.Max)];
        end
        Threshold.Cohort.S2NTT = [getprefRPSPASS('RPSPASS','CohortAnalysis_MinTTSN_Events')];


        %% process files for cohort analysis
        for i = 1:FileNo
            if ~sum(i == FailedFiles)
                % load file from temporary directory
                filename = ['Data_',num2str(i),'.mat'];
                setprefRPSPASS('RPSPASS','CurrFile',Filenames{i})
                Data = preferenceFolder_loadTempDir(filename);

                % write cohort gating data to loaded Data file
                if isfield(Threshold,'Cohort')
                    Data.Threshold.Cohort = Threshold.Cohort;
                    Data.Indices.Cohort_Events_OutliersSpikeinRemoved = Data.diam >= Threshold.Cohort.diam(1) & ...
                        Data.diam <= Data.Threshold.Cohort.diam(2) & Data.TT2SN > Threshold.Cohort.S2NTT & ...
                        Data.Indices.Events_OutlierRemoved;
                end

                % check if cohort analysis is turned on
                switch CohortOutput
                    case 'on'
                        % apply gating and output plots
                        plot_QC_data(Data,'cohort')

                        % update html progress
                        if isempty(mode)
                            app.HTML.Data = [num2str(round(100*((i+FileNo)/(FileNo*figMultiplier)),0)),'%'];
                        else
                            app.HTML.Data = [num2str(round(100*(mode(1)/mode(2))*((i+FileNo)/(FileNo*figMultiplier)),1)),'%'];
                        end
                end
                % collate report information
                [Report, Set{i}] = createReport(i, Report, Data);

                % export selected data files
                Report = ExportDatafileTypes(i, Filenames{i}, Data, timestamp, Report);
            else
                % output plots that failed QC for inspection
                plot_Failed_QC_data(Data,'failed')
            end
        end

        % check if cohort analysis is turned on
        switch CohortOutput
            case 'on'
                Cohort_Comparison(app, Set, Filenames)
        end

        % export report
        outputPath = fullfile(filepath,['RPSPASS ', timestamp_filename],[timestamp_filename,' RPSPASS Report.xlsx']);
        writeReport(TableHeaders, Report, outputPath,Data)

        % open folder containing outputs
        if ismac()
            system(['open ''',fullfile(filepath,['RPSPASS ', timestamp_filename]),'''']);
        end

    end
    % clear temporary file cache
    preferenceFolder_createTempDir()
else
    % if file processing fails
    status = false;
end

end
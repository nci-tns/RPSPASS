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
            'Unprocessed Total Events','Unprocessed Total Volume (pL)','Unprocessed Total Conc (mL^-1)',...
            'IndGate Non-spike-in Events','IndGate Spike-in Events','IndGate Total Volume (pL)','IndGate Sample Conc (mL^-1)','IndGate Spike-In Conc (mL^1)','IndGate Diameter Gate (nm)','IndGate Transit Time Gate (µs)',...
            'CoGate Non-spike-in Events','CoGate Spike-in Events','CoGate Total Volume (pL)','CoGate Sample Conc (mL^-1)','CoGate Spike-In Conc (mL^1)','CoGate Diameter Gate (nm)','CoGate Transit Time Gate (µs)',...
            };

        % create report structure from table headers
        Report = cell2table(cell(FileNo,numel(TableHeaders)), 'VariableNames', TableHeaders); % convert TableHeaders cell array to Table format
        Report.('Filename') = Filenames(:); % add filenames to spreadsheet
        Report.('Dilution Factor') = ones(FileNo,1); % create a default dilution factor for spreadsheet concentration calculation

        %% process h5 files
        for i = 1:FileNo
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
                plot_QC_data(Data)

                % save the h5 file data as temporary .mat file for further gating
                % this will speed up analysis and save memory
                filename = ['Data_',num2str(i),'.mat'];
                preferenceFolder_saveTempDir(filename,Data)

            else
                FailedFiles = [FailedFiles, i];

                % save failed QC h5 file data as temporary .mat file for further gating
                % this will speed up analysis and save memory
                filename = ['Data_',num2str(i),'.mat'];
                preferenceFolder_saveTempDir(filename,Data)

            end
            if isempty(mode)
                app.HTML.Data = [num2str(round(100*(i/(FileNo*figMultiplier)),0)),'%'];
            else
                app.HTML.Data = [num2str(round(100*(mode(1)/mode(2))*(i/(FileNo*figMultiplier)),1)),'%'];
            end
        end

        %% process files for cohort analysis
        for i = 1:FileNo
            % load file from temporary directory
            filename = ['Data_',num2str(i),'.mat'];
            Data = preferenceFolder_loadTempDir(filename);
            setprefRPSPASS('RPSPASS','CurrFile',Filenames{i})

            if ~sum(i == FailedFiles)
                % check if cohort analysis is turned on
                switch CohortOutput
                    case 'on'
                        % check if sample failed calibration/outlier process and exclude
                        if Data.fail == true
                            status = false;
                        else
                            % perform gating
                            [in,on] = inpolygon(Data.ttime, Data.diam, Gates.ttime, Gates.diam);
                            Data.Coh_gate = or(in,on); % cohort gating index

                            % apply gating and output plots
                            outputPath = fullfile(filepath,['RPSPASS ', timestamp_filename],'Cohort Gating',[replace(Filenames{i},'.','-'),'_QC.jpeg']);
                            plot_QC_data(app,Data,outputPath, Data.Coh_gate)
                        end

                end
                % collate report information
                [Report] = createReport(i, Report, Data);

                % export selected data files
                Report = ExportDatafileTypes(i, Filenames{i}, Data, timestamp, Report);
            else
                % output plots that failed QC for inspection
                plot_Failed_QC_data(Data)
            end

            % update html progress
            if isempty(mode)
                app.HTML.Data = [num2str(round(100*((i+FileNo)/(FileNo*figMultiplier)),0)),'%'];
            else
                app.HTML.Data = [num2str(round(100*(mode(1)/mode(2))*((i+FileNo)/(FileNo*figMultiplier)),1)),'%'];
            end
        end

        % export report
        outputPath = fullfile(filepath,['RPSPASS ', timestamp_filename],[timestamp_filename,' RPSPASS Report.xlsx']);
        writeReport(TableHeaders, Report, outputPath,Data)

        % open folder containing outputs
        if ismac()
            system(['open ''',fullfile(filepath,['RPSPASS ', timestamp_filename]),'''']);
        end

        % clear temporary file cache
        preferenceFolder_createTempDir()
    else
        status = false;
    end

else
    % if file processing fails
    status = false;
end



end
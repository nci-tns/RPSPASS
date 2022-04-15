function [status, message]=ImportFiles(app)

% create default output variables
status = true;
message = '';
FailedFiles = [];

timestamp = datestr(datetime('now'), 'yyyy-mm-dd HH:MM:SS');
timestamp_filename = replace(timestamp, ':', '-');

% get file directory
% filepath = testDataset(); % for testing
filepath = uigetdir;

% get output preferences
outputPref.mat = getprefRPSPASS('RPSPASS','matfile');
outputPref.fcs = getprefRPSPASS('RPSPASS','fcsfile');
outputPref.csv = getprefRPSPASS('RPSPASS','csvfile');
filelocator = getprefRPSPASS('RPSPASS','filelocatorSelected');

% if the filepath exists
if ~isequal(filepath,0)

    % switch to loading screen
    app.HTML.HTMLSource = 'Loading_Screen.html';
    app.HTML.Data = '0%';
    pause(0.5);

    % put app at front
    figure(app.RPSPASS)

    % create temporary directory
    preferenceFolder_createTempDir()

    % load .h5 combined files only
    SelectedFolderInfo = dir(fullfile(filepath,'*.h5'));
    Filenames = {SelectedFolderInfo.name}';
    [Filenames, FileGroup, FileNo] = ObtainFilenames(Filenames, filelocator);

    if numel(Filenames) > 0
        % create output folder
        mkdir(fullfile(filepath,['RPSPASS ', timestamp_filename],'Individual Gating'))

        % create table for reporting
        TableHeaders = {'Filename', 'Sample Information','Sample Source','Sample Isolation','Sample Diluent','Spike-in information','Cartridge ID','Instrument Sheath Fluid',...
            'Diameter Calibration', 'Outlier Removal', 'Noise Removal', 'Spike-in Removal', 'FCS Creation','MAT Creation','CSV Creation',...
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

            [app,Data, Report] = ProcessH5File(app, filepath,Filenames{i}, Report, i, FileGroup);

            if ~strcmp(Report{i,'Diameter Calibration'},'Failed') &&...
                    ~strcmp(Report{i,'Outlier Removal'},'Failed') &&...
                    ~strcmp(Report{i,'Noise Removal'},'Failed')

                % create output plots for file
                outputPath = fullfile(filepath,['RPSPASS ', timestamp_filename],'Individual Gating',[replace(Filenames{i},'.','-'),'_QC.jpeg']);
                plot_QC_data(app,Data,outputPath,Data.Ind_gate)

                % collate individual sample gates for downstream group gating
                Gates.diam(i,:) = Data.boundary.diam;
                Gates.ttime(i,:) = Data.boundary.ttime;
                switch Data.RPSPASS.SpikeInUsed
                    case 'Yes'
                        if isempty(Data.SpikeInGateMinNorm)
                            Gates.minSpike(i) = nan;
                        else
                            Gates.minSpike(i) = Data.SpikeInGateMinNorm;
                        end
                end

                % save the h5 file data as temporary .mat file for further gating
                % this will speed up analysis and save memory
                filename = ['Data_',num2str(i),'.mat'];
                preferenceFolder_saveTempDir(filename,Data)

                % update html status
                app.HTML.Data = [num2str(round(100*(i/(FileNo*2)),0)),'%'];
            else
                FailedFiles = [FailedFiles, i];
            end


        end

        % find a suitable gate for all data
        Gates.diam = max(Gates.diam);
        Gates.ttime = max(Gates.ttime);
        switch Data.RPSPASS.SpikeInUsed
            case 'Yes'
                Gates.minSpike = min(Gates.minSpike);
        end

        %% create group directory output
        mkdir(fullfile(filepath,['RPSPASS ', timestamp_filename],'Cohort Gating'))

        % create fcs file output
        if outputPref.fcs == 1
            mkdir(fullfile(filepath,['RPSPASS ', timestamp_filename],'FCS Files'))
        end

        % create mat file output
        if outputPref.mat == 1
            mkdir(fullfile(filepath,['RPSPASS ', timestamp_filename],'MAT Files'))
        end

        % create csv file output
        if outputPref.csv == 1
            mkdir(fullfile(filepath,['RPSPASS ', timestamp_filename],'CSV Files'))
        end

        for i = 1:FileNo

            if ~sum(i == FailedFiles)
                % load file from temporary directory
                filename = ['Data_',num2str(i),'.mat'];
                Data = preferenceFolder_loadTempDir(filename);

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

                %% create fcs filename
                filename = fullfile(filepath,['RPSPASS ', timestamp_filename],'FCS Files',[replace(Filenames{i},'.','-'),'.fcs']);

                % export fcs file data
                if outputPref.fcs == 1
                    try % if turned on
                        fcsfileexport(app, Data, timestamp, filename)
                        Report(i,'FCS Creation') = {'Successful'};
                    catch
                        Report(i,'FCS Creation') = {'Failed'};
                    end
                else % if turned on
                    Report(i,'FCS Creation') = {'Off'};
                end

                %% create .mat filename
                filename = fullfile(filepath,['RPSPASS ', timestamp_filename],'MAT Files',[replace(Filenames{i},'.','-'),'.mat']);

                % export .mat file data
                if outputPref.mat == 1 % if turned on
                    try
                        save(filename, 'Data')
                        Report(i,'MAT Creation') = {'Successful'};
                    catch
                        Report(i,'MAT Creation') = {'Failed'};
                    end
                else % if turned on
                    Report(i,'MAT Creation') = {'Off'};
                end

                %% create .csv filename
                filename = fullfile(filepath,['RPSPASS ', timestamp_filename],'CSV Files',[replace(Filenames{i},'.','-'),'.xlsx']);

                % export fcs file data
                if outputPref.fcs == 1
                    try % if turned on
                        writeSpectradyneCVS(app, Data, timestamp, filename)
                        Report(i,'CSV Creation') = {'Successful'};
                    catch
                        Report(i,'CSV Creation') = {'Failed'};
                    end
                else % if turned on
                    Report(i,'CSV Creation') = {'Off'};
                end

                % update html status
                app.HTML.Data = [num2str(round(100*((i+FileNo)/(FileNo*2)),0)),'%'];

                % collate report information
                [Report] = createReport(i, Report, Data, Gates);
            end
        end

        % export report
        outputPath = fullfile(filepath,['RPSPASS ', timestamp_filename],'RPSPASS Report.xlsx');
        writeReport(TableHeaders, Report, outputPath)

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
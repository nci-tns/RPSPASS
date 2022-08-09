function [Report] = ExportDatafileTypes(FileID, Filename, Data, timestamp, Report)

% get output directory and filename information
outputDir = fullfile(getprefRPSPASS('RPSPASS','OutputDir'),'File Export');
       
% check if output folder path exists
if ~isfolder(outputDir)
    % create directory if it does not exist
    mkdir(outputDir)
end

% file export names
searchName = {'fcs','mat','xlsx','json'};
for i = 1:numel(searchName)

    % check output preferences to deteremine if file will be exported
    if getprefRPSPASS('RPSPASS',[searchName{i},'file']) == 1

        % create folder path
        folderPath = fullfile(outputDir,[searchName{i}, ' files']);

        % check if folder path exists
        if ~isfolder(folderPath)
            % create directory if it does not exist
            mkdir(folderPath)
        end

        % create export path and filename
        export_filename = fullfile(folderPath,[replace(Filename,'.','-'),['.',searchName{i}]]);

        try % perform file export
            switch searchName{i}
                case 'fcs'
                    fcsfileexport(Data, timestamp, export_filename)
                case 'mat'
                    save(export_filename, 'Data')
                case 'xlsx'
                    writeSpectradyneCVS(Data, timestamp, export_filename)
                case 'json'
                    jsondata = jsonencode(Data);
                    fid = fopen(export_filename,'w');
                    fprintf(fid,'%s',jsondata);
                    fclose(fid);
            end
            Report(FileID,[upper(searchName{i}) ,' Creation']) = {'Successful'};
        catch
            Report(FileID,[upper(searchName{i}) ,' Creation']) = {'Failed'};
        end
    else
        Report(FileID,[upper(searchName{i}),' Creation']) = {'Off'};
    end
end


end
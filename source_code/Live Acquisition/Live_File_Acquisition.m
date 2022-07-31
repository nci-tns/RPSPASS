function [status, message]=Live_File_Acquisition(app)

filepath = getprefRPSPASS('RPSPASS','acquisition_dir');
filelocator = getprefRPSPASS('RPSPASS','filelocatorSelected');

% if the filepath exists
if ~isequal(filepath,0)

    % load .h5 combined files only
    SelectedFolderInfo = dir(fullfile(filepath,'*.h5'));
    Filenames = {SelectedFolderInfo.name}';
    [Filenames, FileGroup, FileNo] = ObtainFilenames(Filenames);

    if numel(Filenames) > 0
        % get user selected live file
        app.SampleName.Items = Filenames;
        % fine file group index for selected file
        FileID = strcmp(Filenames, app.SampleName.Value);

        % process selected file
        [app, Data] = Live_ProcessH5File(app, filepath, app.SampleName.Value, FileID, FileGroup);

        % update live plots
        UpdateLivePlots(app,Data)
    else
        status = false;
    end

else
    % if file processing fails
    status = false;
end



end
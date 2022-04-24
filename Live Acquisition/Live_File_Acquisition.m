function [status, message]=Live_File_Acquisition(app)

filepath = getprefRPSPASS('RPSPASS','acquisition_dir');
filelocator = getprefRPSPASS('RPSPASS','filelocatorSelected');

while app.LiveAcquisition == true
    % if the filepath exists
    if ~isequal(filepath,0)

        % load .h5 combined files only
        SelectedFolderInfo = dir(fullfile(filepath,'*.h5'));
        Filenames = {SelectedFolderInfo.name}';
        [Filenames, FileGroup, FileNo] = ObtainFilenames(Filenames, filelocator);

        if numel(Filenames) > 0
            app.SampleName.Items = Filenames;

            %             [app,Data, Report] = ProcessH5File(app, filepath,Filenames{i}, Report, i, FileGroup);

        else
            status = false;
        end

    else
        % if file processing fails
        status = false;
    end
        pause(10)
end


end
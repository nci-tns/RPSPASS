function [status]=dev_file_test(app)

% get directory path
test_path = getprefRPSPASS('RPSPASS','dev_path');

% check path still exists
if isfolder(test_path)

    % get all directories and unique terminal folders
    filestruct = dir(fullfile(test_path,'**/*.h5'));
    Sets = unique({filestruct.folder});
    SetNo = numel(Sets);
    % cycle through each folder to process data
    for i = 1:SetNo

        % split path into individual folders to extract spike-in use,
        % diameter, and concentration for processing
        if ismac()
            filep = strsplit(Sets{i},'/');
        elseif ispc()
             filep = strsplit(Sets{i},'\');
        end

        % get folder name that dictates spike-in concentration
        concStr = str2num(filep{end-1});
        
        if ~isempty(concStr) || concStr ~= 0
            app.SpikeInConc = concStr;
        else
            app.SpikeInConc = [];
        end
       
        SpikeInStr = str2num(filep{end-2});

        if SpikeInStr == 0
            app.SpikeInUsed = 'No';
        else
            app.SpikeInUsed = 'Yes';
            app.SpikeInDiam = SpikeInStr;
        end

        [status, message]=ImportFiles(app, Sets{i},[i SetNo]);
    end


else
    selection = uiconfirm(app.RPSPASS,'Testing directory cannot be found','Test directory',...
                        'Icon','warning','Options',{'Download','Locate','Cancel'}, ...
           'DefaultOption',2,'CancelOption',3);

    switch selection
        case 'Download'
            filename = 'RPSPASS Dev Testing Files.zip';

            % get path to save testing directory
            [~,path] = uiputfile(filename);
            
            % run system command to download installer
            input =['curl ',getprefRPSPASS('RPSPASS','dev_file_download'),' --output ','''',fullfile(path,filename),''''];
            system(input);

            % unzip the installer
            unzip(fullfile(path,filename),path)
            
            % delete the remaining zip folder
            delete(fullfile(path,filename))

            % add location of testing directory in preferences
            setprefRPSPASS('RPSPASS','dev_path',fullfile(path,'RPSPASS Dev Testing Files'))

            % rerun script for path to be verified
            dev_file_test(app)
        case 'Locate'
            % get path to testing directory
            path = uigetdir();

            if isfolder(path)
                % add location of testing directory in preferences
                setprefRPSPASS('RPSPASS','dev_path',path)
            end

            % rerun script for path to be verified
            dev_file_test(app)
        case 'Cancel'
        status = 'Cancel';
    end


end


end
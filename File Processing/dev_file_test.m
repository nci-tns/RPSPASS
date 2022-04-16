function [status]=dev_file_test(app)

test_path = getprefRPSPASS('RPSPASS','dev_path');

if isfolder(test_path)
    filestruct = dir(fullfile(test_path,'**/*.h5'));
    Sets = unique({filestruct.folder});

    for i = 1:numel(Sets)

        if ismac()
            filep = strsplit(Sets{1},'/');
        elseif ispc()
             filep = strsplit(Sets{1},'\');
        end

        if str2num(filep{end-1}) == 0
            app.SpikeInUsed = 'No';
        else
            app.SpikeInUsed = 'Yes';
            app.SpikeInDiam = str2num(filep{end-1});

        end
        app.SpikeInConc = [];

        [status, message]=ImportFiles(app, Sets{i});
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
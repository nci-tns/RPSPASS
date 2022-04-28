function preferenceFolder_createTempDir()

% get account username for accessing correct file directory
username = char(java.lang.System.getProperty('user.name'));

% create path to file directory
if ismac()
    prefFile = ['/Users/', username, '/Library/Application Support/rpspass/temp'];
else
    prefFile = ['C:\Users\', username, '\AppData\Local\rpspass\temp'];
end

% create directory if it doesnt exist
if ~isfolder(prefFile)
    mkdir(prefFile)
else
    % check if there are files within directory already
    files = dir(fullfile(prefFile,'*.mat'));

    if ~isempty(files)
        % if files do exist in the directory remove them
        for i = 1:size(files,1)
            delete(fullfile(files(i).folder,files(i).name))
        end
    end

end

end
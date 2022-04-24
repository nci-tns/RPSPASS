function [Data]=preferenceFolder_loadTempDir(filename)

username = char(java.lang.System.getProperty('user.name'));

if ismac()
    prefFile = ['/Users/', username, '/Library/Application Support/rpspass/temp'];
else
    prefFile = ['C:\Users\', username, '\AppData\Roaming\FCMPASS\rpspass\temp'];
end

load(fullfile(prefFile,filename),'Data')

end
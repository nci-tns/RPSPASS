function [] = RPSPASS_Preference(app)

username = char(java.lang.System.getProperty('user.name'));
PrefType = 'RPSPASS';

if ismac()
    prefpath = ['/Users/', username, '/Library/Application Support/rpspass'];
elseif ispc()
    prefpath = ['C:\Users\', username, '\AppData\Local\rpspass'];
end

if ~isfolder(prefpath)
    mkdir(prefpath)
end

% prefFile = fullfile(prefpath, [PrefType, '_Pref.rpspass']);


PrefVersionUpdate(app.Version, prefpath)



end

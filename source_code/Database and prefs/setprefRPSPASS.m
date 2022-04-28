function setprefFCMPASS(PrefType, prefName, prefValue)

username = char(java.lang.System.getProperty('user.name'));

if ismac()
    prefFile = ['/Users/', username, '/Library/Application Support/rpspass/', PrefType, '_Pref.rpspass'];
else
    prefFile = ['C:\Users\', username, '\AppData\Local\rpspass\', PrefType, '_Pref.rpspass'];
end

D = matfile(prefFile, 'Writable', true);
D.(prefName) = prefValue;

end
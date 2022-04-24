function status = isprefFCMPASS(PrefType, prefName)

username = char(java.lang.System.getProperty('user.name'));

if ismac()

    prefFile = ['/Users/', username, '/Library/Application Support/rpspass/', PrefType, '_Pref.rpspass'];

else

    prefFile = ['C:\Users\', username, '\AppData\Roaming\rpspass\', PrefType, '_Pref.rpspass'];

end

D = matfile(prefFile);
savedPrefs = fieldnames(D);

if sum(strcmp(savedPrefs, prefName)) > 0

    status = true;

else

    status = false;

end

end
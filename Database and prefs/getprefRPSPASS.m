function prefValue = getprefRPSPASS(PrefType, varargin)

username = char(java.lang.System.getProperty('user.name'));

if ismac()
    prefFile = ['/Users/', username, '/Library/Application Support/rpspass/', PrefType, '_Pref.rpspass'];
else
    prefFile = ['C:\Users\', username, '\AppData\Roaming\rpspass\', PrefType, '_Pref.rpspass'];
end

% if second argument is included return specific keyword
if nargin == 2 
    D = matfile(prefFile);
    prefValue = D.(varargin{1});
else % return entire preference structure array
    prefValue = load(prefFile,"-mat");
end

end
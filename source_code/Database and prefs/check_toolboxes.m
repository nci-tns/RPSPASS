
% check for toolbox installation
requiredToolboxes = {'Signal Processing Toolbox',...
    'Statistics and Machine Learning Toolbox',...
    'Deep Learning Toolbox',...
    'Curve Fitting Toolbox',...
    'MATLAB'};
installedToolboxes = ver();
ToolboxCheck = contains(requiredToolboxes,{installedToolboxes.Name});

if ~sum(ToolboxCheck) == numel(requiredToolboxes)
    error('Software is missing critical toolboxes')
end

% check for the installation of other required third party functions from
% file exchange
requiredThirdPartyFunctions = {'natsort'};

for i = 1:numel(requiredThirdPartyFunctions)
    if ~exist(requiredThirdPartyFunctions{i}, 'file')
        error(['Software is missing critical third party function: ', requiredThirdPartyFunctions{i}])
    end
end
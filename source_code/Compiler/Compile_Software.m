clear; clc

% Updates made between versions
ver = '1.0.1';
MasterFile = 'GUI_Master.mlapp';

path = strsplit((which(MasterFile)),filesep);
EmptyPath = cellfun(@isempty, path);
SourcePath = fullfile(path{~EmptyPath(1:end-1)});

% OS spectific
if ismac()
    installDir = '/Applications/RPSPASS';
    outputDir = ['/Users/welshjoa/Library/CloudStorage/OneDrive-SharedLibraries-NationalInstitutesofHealth/CCR-Translational-Nanobiology - Software/RPSPASS/Compiled/Mac/',ver];
    intallerName = 'RPSPASS_Installer_Mac';
elseif ispc()
    installDir = 'C:\Program Files\RPSPASS';
    outputDir = ['C:\Users\welshjoa\Documents\MATLAB\RPSPASS\Compiled\',ver];
    intallerName = 'RPSPASS_Installer_PC';
end

if ~isfolder(outputDir)
    mkdir(outputDir)
end

% application compiler options
App.opts = compiler.build.StandaloneApplicationOptions(fullfile(SourcePath,MasterFile));
App.opts.EmbedArchive= 'on';
App.opts.ExecutableIcon= fullfile(SourcePath,'Icons','RPS Logo.jpg');
App.opts.ExecutableName= 'RPSPASS';
App.opts.ExecutableSplashScreen=  fullfile(SourcePath,'Icons','RPS Logo.jpg');
App.opts.ExecutableVersion= ver;
App.opts.TreatInputsAsNumeric= 'off';
App.opts.AutoDetectDataFiles= 'on';
App.opts.AdditionalFiles = fullfile(SourcePath,'HTML');
App.opts.Verbose= 'on';
App.opts.OutputDir= fullfile(outputDir,'Application');

% compile standalone application
App.results = compiler.build.standaloneApplication(App.opts);
App.runtimeProducts = fullfile(App.results.Options.OutputDir,'requiredMCRProducts.txt');

% installation compiler options
Inst.opts = compiler.package.InstallerOptions(...
    'RuntimeDelivery', 'web',...
    'InstallerSplash',  fullfile(SourcePath,'Icons','RPS Logo.jpg'),...
    'InstallerIcon',  fullfile(SourcePath,'Icons','RPS Logo.jpg'),...
    'InstallerLogo',  fullfile(SourcePath,'Icons','RPS Logo.jpg'),...
    'AuthorName', 'Joshua Welsh',...
    'AuthorEmail', 'joshua.welsh@nih.gov',...
    'AuthorCompany', 'U.S. National Institutes of Health',...
    'Summary', 'Software for the acquisition, calibration and analysis of Spectradyne nCS1 data..',...
    'Description', '',...
    'InstallationNotes', '',...
    'Shortcut', '',...
    'Version', ver,...
    'InstallerName', intallerName,...
    'ApplicationName', 'RPSPASS',...
    'OutputDir', fullfile(outputDir,'Installer'),...
    'DefaultInstallationDir', installDir);

Files = [App.results.Files(:); 'LICENSE'];

% create installation compiler
compiler.package.installer(Files,'Options',Inst.opts);


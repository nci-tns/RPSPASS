clear; clc

% Updates made between versions
ver = '1.0.1';
MasterFile = 'GUI_Master.mlapp';

% OS spectific
if ismac()
    installDir = '/Applications/RPSPASS';
    outputDir = ['/Users/welshjoa/Library/CloudStorage/OneDrive-SharedLibraries-NationalInstitutesofHealth/CCR-Translational-Nanobiology - Software/RPSPASS/Compiled/Mac/',ver];
    intallerName = 'RPSPASS_Installer_Mac';
elseif ispc()
    installDir = 'C:\Program Files\RPSPASS';
    outputDir = ['/Users/welshjoa/Library/CloudStorage/OneDrive-SharedLibraries-NationalInstitutesofHealth/CCR-Translational-Nanobiology - Software/RPSPASS/Compiled/Windows/',ver];
    intallerName = 'RPSPASS_Installer_PC';
end

if ~isfolder(outputDir)
    mkdir(outputDir)
end

path = strsplit((which(MasterFile)),filesep);
EmptyPath = cellfun(@isempty, path);

% application compiler options
App.opts = compiler.build.StandaloneApplicationOptions(which(MasterFile));
App.opts.EmbedArchive= 'on';
App.opts.ExecutableIcon= which('RPS Logo.jpg');
App.opts.ExecutableName= 'RPSPASS';
App.opts.ExecutableSplashScreen= which('RPS Logo.jpg');
App.opts.ExecutableVersion= ver;
App.opts.TreatInputsAsNumeric= 'off';
App.opts.AutoDetectDataFiles= 'on';
App.opts.AdditionalFiles = 'HTML';
App.opts.Verbose= 'on';
App.opts.OutputDir= fullfile(outputDir,'Application');

% compile standalone application
App.results = compiler.build.standaloneApplication(App.opts);

% installation compiler options
Inst.opts = compiler.package.InstallerOptions(...
    'RuntimeDelivery', 'web',...
    'InstallerSplash', fullfile('Icons','RPS Logo.jpg'),...
    'InstallerIcon', fullfile('Icons','RPS Logo.jpg'),...
    'InstallerLogo', fullfile('Icons','RPS Logo.jpg'),...
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

Files = [App.results.Files, 'LICENSE'];

% create installation compiler
compiler.package.installer(Files,'Options',Inst.opts);


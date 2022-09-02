clear; clc

% Updates made between versions
ver = '1.0.1';
MasterFile = 'GUI_Master.mlapp';

% OS spectific
if ismac()
    installDir = '/Applications/RPSPASS';
    outputDir = ['/Users/welshjoa/Library/CloudStorage/OneDrive-SharedLibraries-NationalInstitutesofHealth/CCR-Translational-Nanobiology - Software/RPSPASS/Compiled/Mac/',ver];
elseif ispc()
    installDir = 'C:\Program Files\RPSPASS';
    outputDir = ['/Users/welshjoa/Library/CloudStorage/OneDrive-SharedLibraries-NationalInstitutesofHealth/CCR-Translational-Nanobiology - Software/RPSPASS/Compiled/Mac/',ver];
end

if ~isfolder(outputDir)
    mkdir(outputDir)
end


% application compiler options
App.opts = compiler.build.StandaloneApplicationOptions(MasterFile);
App.opts.EmbedArchive= 'on';
App.opts.ExecutableIcon= fullfile('Icons','RPS Logo.jpg');
App.opts.ExecutableName= 'RPSPASS';
App.opts.ExecutableSplashScreen= fullfile('Icons','RPS Logo.jpg');
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
    'InstallerName', 'RPSPASS_Installer',...
    'ApplicationName', 'RPSPASS',...
    'OutputDir', fullfile(outputDir,'Installer'),...
    'DefaultInstallationDir', installDir);

% create installation compiler
compiler.package.installer(App.results,'Options',Inst.opts);


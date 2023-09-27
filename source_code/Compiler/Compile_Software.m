clear; clc

% check all required toolboxes exist
check_toolboxes()

% Updates made between versions
ver = '1.0.2.0';
MasterFile = 'GUI_Master.mlapp';

path = strsplit((which(MasterFile)),filesep);
EmptyPath = cellfun(@isempty, path);
SourcePath = fullfile(path{~EmptyPath(1:end-1)});
ProjPath = fullfile(path{~EmptyPath(1:end-2)});

% OS spectific
if ismac()
    installDir = '/Applications/RPSPASS';
    outputDir = ['Installation File/Mac/',ver];
    installerName = 'RPSPASS_Installer_Mac';
    installerExtension = '.app';
    SourcePath = [filesep,SourcePath];
    ProjPath = [filesep,ProjPath];
elseif ispc()
    installDir = 'C:\Program Files\RPSPASS';
    outputDir = ['Installation File\Windows\',ver];
    installerName = 'RPSPASS_Installer_PC';
    installerExtension = '.exe';
end

% get non-MATLAB file dependancies
[FileDep] = getFileDependencies(SourcePath);

% remove output directory if exists. Overwrite can cause issues with
% compiling. The recreate the directory.
if isfolder(outputDir)
    rmdir(outputDir,'s')
end
mkdir(outputDir)

% application compiler options
App.opts = compiler.build.StandaloneApplicationOptions(fullfile(SourcePath,MasterFile));
App.opts.EmbedArchive = 'on';
App.opts.ExecutableIcon = fullfile(SourcePath,'Icons','RPS Logo.jpg');
App.opts.ExecutableName = 'RPSPASS';
App.opts.ExecutableSplashScreen =  fullfile(SourcePath,'Icons','RPS Logo.jpg');
App.opts.ExecutableVersion = ver;
App.opts.TreatInputsAsNumeric = 'off';
App.opts.AutoDetectDataFiles = 'on';
App.opts.AdditionalFiles = FileDep;
App.opts.Verbose = 'on';
App.opts.OutputDir = fullfile(outputDir,'Application');

% compile standalone application
App.results = compiler.build.standaloneApplication(App.opts);
App.runtimeProducts = fullfile(App.results.Options.OutputDir,'requiredMCRProducts.txt');

% installation compiler options
Inst.opts = compiler.package.InstallerOptions(App.results);
Inst.opts.RuntimeDelivery =  'web';
Inst.opts.InstallerSplash =  fullfile(SourcePath,'Icons','RPS Logo.jpg');
Inst.opts.InstallerIcon = fullfile(SourcePath,'Icons','RPS Logo.jpg');
Inst.opts.InstallerLogo =  fullfile(SourcePath,'Icons','RPS Logo.jpg');
Inst.opts.AuthorName = 'Joshua Welsh';
Inst.opts.AuthorEmail = 'joshua.welsh@nih.gov';
Inst.opts.AuthorCompany = 'U.S. National Institutes of Health';
Inst.opts.Summary = 'Software for the acquisition, calibration and analysis of Spectradyne nCS1 data.';
Inst.opts.Description = '';
Inst.opts.InstallationNotes = '';
Inst.opts.Shortcut = '';
Inst.opts.Version = ver;
Inst.opts.InstallerName = installerName;
Inst.opts.ApplicationName = 'RPSPASS';
Inst.opts.OutputDir = fullfile(outputDir,'Installer');
Inst.opts.DefaultInstallationDir = installDir;

Files = [App.results.Files(:); fullfile(ProjPath,'LICENSE')];

% create installation compiler
compiler.package.installer(Files,App.runtimeProducts,'Options',Inst.opts);

% remove the application folder
rmdir(App.results.Options.OutputDir,'s')

% zip installation file and remove unzipped file
zip(fullfile(outputDir,'Installer',installerName),fullfile(outputDir,'Installer',[installerName,installerExtension]))
delete(fullfile(outputDir,'Installer',[installerName,installerExtension]))

function [FileDep] = getFileDependencies(SourcePath)

files = dir(fullfile(SourcePath,'HTML','**'));
FileDep = [];
for i = 1:size(files,1)
    rmInd = strcmp(files(i).name,{'.','..','.DS_Store'});
    if sum(rmInd) == 0
        FileDep = [FileDep; string(fullfile(files(i).folder, files(i).name))];
    end
end

end


function [] = softwareUpdate(app)

% obtained current release of the software
software = jsondecode(webread('http://joshuawelsh.co.uk/softwareupdate'));

ReleaseV = software.RPSPASS.version; % current software release
UserV = app.Version; % currently installed software version

% split versions in parts by their decimals
ReleaseVParts = strsplit(ReleaseV,'.');
UserVParts = strsplit(UserV,'.');
check = cell(1, min([numel(ReleaseVParts), numel(UserVParts)]));

% compare each number
for i = 1:min([numel(ReleaseVParts), numel(UserVParts)])
    if str2double(ReleaseVParts{i}) > str2double(UserVParts{i})
        check{i} = 'false';
    else
        check{i} = 'true';
    end
end

% determine if update is required
if max(contains(check,'false')) == 1
    status = 'update';
else
    status = 'pass';
end

% if update is required
if strcmp(status,'update')
    title = 'Software Update';
    message = ['There is a new version of FCMPASS (v', Response.version, '). Would you like to download now?'];
    app.WriteUIAlerts2ErrorLog(title, message)
    selection = uiconfirm(app.StartMenu, message, title, 'Options', {'Ok','Later'}, 'Icon','warning');

    switch selection
        case 'Ok'

            % get download link for software
            if ismac()
                link = software.RPSPASS.downloadPC;
            elseif ispc()
                link = software.RPSPASS.downloadPC;
            end
            selpath = fullfile(getprefRPSPASS('RPSPASS','prefpath'),'Updates');

            % make directory for software update
            if ~isfolder(selpath)
                mkdir(selpath)
            end

            % create output location for installer
            output_loc = fullfile(selpath,'RPSPASS_Installer.zip');

            % run system command to download installer
            input =['curl ',link,' --output ','''',output_loc,''''];
            system(input);

            % unzip the installer
            unzip(output_loc,selpath)

            % open the installer
            if ispc()
                winopen(fullfile(selpath,'Win_RPSPASS_Installer.exe'))
            elseif ismac()
                uiopen(fullfile(selpath,'Mac_RPSPASS_Installer.app'))
            end

            % give update before shutting down
            title = 'Software Update';
            message = 'An updated version of the software has downloaded. Please continue in the installation window.';
            uialert(app.RPSPASS, message, title,'Icon','success')
            pause(5)
            close(app.RPSPASS)
        otherwise
    end

else % if software is the most up to date version

    title = 'Software Update';
    message = 'Your software is up to date';
    uialert(app.RPSPASS, message, title,'Icon','success');

end

end
function ErrorLog(app, errorMessage)

% Open the Error Log file for appending.
if exist(getprefRPSPASS('RPSPASS', 'prefpath'), 'dir')

    fullFileName = fullfile(getprefRPSPASS('RPSPASS', 'prefpath'), 'RPSPASS Error Log.txt');
    [fid] = fopen(fullFileName, 'at');
    fprintf(fid, '%s\n', '%%%%%%%%%%%%%%%%%%%%%%%%%%%%'); % To file
    fprintf(fid, '%s\n', [datestr(datetime('now')), ' version:', char(getprefRPSPASS('RPSPASS', 'version'))]); % To file
    fprintf(fid, '\n'); % To file
    fprintf(fid, '%s\n', errorMessage); % To file
    fprintf(fid, '\n'); % To file
    fclose(fid);

    fileDir = dir(fullFileName);
    if fileDir.bytes > 100000

        fid = fopen(fullFileName, 'r');
        errorLogText = char(fread(fid))';
        fclose(fid);

        splitInd = strfind(errorLogText, '%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
        text2write = errorLogText(splitInd(floor(numel(splitInd) / 2)):end);

        fid = fopen(fullFileName, 'w');
        fwrite(fid, text2write);
        fclose(fid);

    end

    return; % from WarnUser()

end
end
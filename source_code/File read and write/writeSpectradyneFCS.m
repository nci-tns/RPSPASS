function writeSpectradyneFCS(filename, data, hdr, marker_names,channel_names)
% function writeSpectradyneFCSTest(filename, data, marker_names,channel_names)

if size(data,2) ~= length(marker_names) % put the data matrix back to what flow people are familiar with, thin tall matrix
    if size(data,1) == length(marker_names)
        data = data.';
    else
        error('data size and marker_names length do not match!!')
    end
end

% Required Keywords
fcsheader_main=['\$BEGINANALYSIS\0\$ENDANALYSIS\0\$BEGINSTEXT\0\$ENDSTEXT\0\$NEXTDATA\0\'];
fcsheader_main = [fcsheader_main,'$TOT\',num2str(size(data,1)),'\']; % number of cells/events
fcsheader_main = [fcsheader_main,'$PAR\',num2str(size(data,2)),'\']; % number of channels

fcsheader_main = [fcsheader_main,'$BYTEORD\4,3,2,1\'];  % little endian/big endian
fcsheader_main = [fcsheader_main,'$DATATYPE\F\'];  % float precision, 32 bits
fcsheader_main = [fcsheader_main,'$MODE\L\'];  % list mode

% Optional Keywords
[~,NAME,EXT] = fileparts(filename); 
fcsheader_main = [fcsheader_main, '$FIL\',NAME,'\'];
fcsheader_main = [fcsheader_main, '$CREATOR\RPSPASS\'];

% hdr keywords
hdr_fields = fields(hdr);

% Optional Info
for i = 1:numel(hdr_fields)
    
    fieldname = hdr_fields{i};
    fieldvalue = hdr.(hdr_fields{i});

    if ischar(fieldvalue)
        fcsheader_main = [fcsheader_main, fieldname, '\', fieldvalue, '\'];

    elseif iscell(fieldvalue)
        fcsheader_main = [fcsheader_main, fieldname, '\', fieldvalue{1,1}, '\'];

    elseif isempty(fieldvalue)
        fcsheader_main = [fcsheader_main, fieldname, '\', char(fieldvalue), '\'];

    elseif isscalar(fieldvalue)
        fcsheader_main = [fcsheader_main, fieldname, '\', num2str(fieldvalue), '\'];

    else % for arrays
        fcsheader_main = [fcsheader_main, hdr_fields{i}, '\', ...
            strjoin(strrep(cellstr(num2str(fieldvalue)), ' ', ''), ','), '\'];
    end
end

% Required Parameters
for i=1:length(marker_names)
    fcsheader_main = [fcsheader_main,'$P',num2str(i),'B\',num2str(32),'\'];
    if exist('channel_names')
        fcsheader_main = [fcsheader_main,'$P',num2str(i),'N\',channel_names{i},'\'];
        fcsheader_main = [fcsheader_main,'$P',num2str(i),'S\',channel_names{i},'\'];
    else
        fcsheader_main = [fcsheader_main,'$P',num2str(i),'N\',marker_names{i},'\'];
        fcsheader_main = [fcsheader_main,'$P',num2str(i),'S\',marker_names{i},'\'];
    end
    fcsheader_main = [fcsheader_main,'$P',num2str(i),'R\',num2str(ceil(max(data(:,i)))),'\'];
    fcsheader_main = [fcsheader_main,'$P',num2str(i),'E\','0,0','\'];
end

fid = fopen(filename,'w','b');
HeaderStart = 100;
HeaderStop = HeaderStart + length(fcsheader_main)+100-1;
DataStart = HeaderStop;
DataEnd = DataStart+numel(data)*4;
fcsheader_1stline  = sprintf('FCS3.0    %8d%8d%8d%8d%8d%8d',HeaderStart,HeaderStop,DataStart,DataEnd,0,0);
fcsheader_main = [fcsheader_main,'$BEGINDATA\',num2str(DataStart),'\'];
fcsheader_main = [fcsheader_main,'$ENDDATA\',num2str(DataEnd),'\'];
entire_header = [fcsheader_1stline, repmat(char(32),1,HeaderStart-length(fcsheader_1stline)), fcsheader_main];
entire_header = [entire_header, repmat(char(32),1,HeaderStop-length(entire_header))];

fwrite(fid,entire_header,'char');
fwrite(fid,data.','float32');
fclose(fid);

end
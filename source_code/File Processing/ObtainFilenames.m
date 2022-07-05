function [OutputFilenames, FileGroup, FileNo] = ObtainFilenames(InputFilenames, filelocator)

switch filelocator
    case '_ss00'
        [Filenames, FileGroup, FileNo] = get_ss00(InputFilenames, '_ss00');
        if isempty(Filenames)
            [Filenames, FileGroup, FileNo] = get_cc(InputFilenames, '_cc');
        end
    case '_cc'
        [Filenames, FileGroup, FileNo] = get_cc(InputFilenames, '_cc');
        if isempty(Filenames)
            [Filenames, FileGroup, FileNo] = get_ss00(InputFilenames, '_ss00');
        end
end

OutputFilenames = Filenames;

end

function [Filenames, FileGroup, FileNo] = get_ss00(Filenames, filelocator)
% get all statistics files using the '_ss00' file locator
Filenames_ss = {Filenames{contains(Filenames, filelocator)}}';
Filenames_ss2 = cell(1,numel(Filenames_ss)); % create empty array
StrInd = regexp(Filenames_ss, filelocator); % find the location of the filelocator in string

% process each filename to remove the unique elements to
% find the sample name that will act as the unique string for
% the acquisition
for i = 1:numel(Filenames_ss)
    tempFilenameSS = Filenames_ss{i}(1:StrInd{i}(end)-1); % delete everything after filelocator in filename
    StrInd2 = strfind(tempFilenameSS, '_'); % delete everything after the '_' representing run ID
    Filenames_ss2{i} = tempFilenameSS(1:StrInd2-1); % obtain non-unique sample name
end

% find the unique sample names
Filenames = unique(Filenames_ss2);

% group each run for each sample
FileGroup = cell(1,numel(Filenames));
for i = 1:numel(Filenames)
    FileGroup{i} = Filenames_ss(ismember(Filenames_ss2, Filenames{i}));
end

% obtain number of samples to process
FileNo = numel(Filenames);
end

function [Filenames, FileGroup, FileNo] = get_cc(Filenames, filelocator)

Filenames = {Filenames{contains(Filenames, filelocator)}};
FileNo = numel(Filenames);
FileGroup = [];

end
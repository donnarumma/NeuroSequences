function setup_Sequences(rootDir)
%SETUP_SEQUENCES Add Sequences project paths to MATLAB path
%   setup_Sequences(rootDir) adds all subdirectories of rootDir to the 
%   MATLAB path, except for 'legacy' and 'debug' folders.
%
%   Usage:
%       setup_Sequences('~/tools/Sequences')
%       setup_Sequences('/media/Data/OneDrive/tools/Sequences')

% Use default root directory if not provided
if nargin < 1 || isempty(rootDir)
    rootDir = fileparts(mfilename('fullpath'));
end

% Expand home directory shortcut
rootDir = expanduser(rootDir);

% Check if directory exists
if ~isfolder(rootDir)
    error('setup_Sequences:InvalidPath', ...
        'Root directory does not exist: %s', rootDir);
end

% List all subdirectories
contents = dir(rootDir);
subdirs = contents([contents.isdir]);

% Folders to exclude
excludeFolders = {'legacy', 'debug', '.', '..'};

% Add valid subdirectories to path
addedPaths = {};
for i = 1:numel(subdirs)
    folderName = subdirs(i).name;
    
    % Skip excluded folders
    if ismember(folderName, excludeFolders)
        continue;
    end
    
    % Skip hidden folders (starting with .)
    if startsWith(folderName, '.')
        continue;
    end
    
    fullPath = fullfile(rootDir, folderName);
    addpath(fullPath);
    addedPaths{end+1} = fullPath; %#ok<AGROW>
end

% Add root directory itself
addpath(rootDir);
addedPaths{end+1} = rootDir; %#ok<AGROW>

% Display results
fprintf('Sequences project paths added:\n');
fprintf('  Root: %s\n', rootDir);
for i = 1:numel(addedPaths)
    [~, folderName] = fileparts(addedPaths{i});
    if isempty(folderName)
        folderName = '(root)';
    end
    fprintf('  - %s\n', folderName);
end
fprintf('\nTotal: %d paths added\n', numel(addedPaths));

end

function expandedPath = expanduser(pathStr)
%EXPANDUSER Expand ~ to home directory
    if startsWith(pathStr, '~')
        homeDir = char(java.lang.System.getProperty('user.home'));
        expandedPath = fullfile(homeDir, pathStr(2:end));
    else
        expandedPath = pathStr;
    end
end

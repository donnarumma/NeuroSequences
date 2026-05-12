function print_main_dependency_disclaimer(mainName, packages, varargin)
%PRINT_MAIN_DEPENDENCY_DISCLAIMER Print a short startup reminder for MAIN scripts.

if nargin < 1 || isempty(mainName)
    mainName = 'MAIN';
end

if nargin < 2 || isempty(packages)
    packages = {'HAI_LANGUAGE', 'TrialBox', 'SPM'};
end

notes = varargin;
if numel(notes) == 1 && iscell(notes{1})
    notes = notes{1};
end

fprintf('\n============================================================\n');
fprintf('%s dependency disclaimer\n', mainName);
fprintf('Required external packages on the MATLAB path:\n');

for iPackage = 1:numel(packages)
    packageName = packages{iPackage};
    fprintf('  - %s%s\n', packageName, resolve_package_note(packageName));
end

fprintf('To add NeuroSequences paths, run setup_NeuroSequences first.\n');

for iNote = 1:numel(notes)
    if ~isempty(notes{iNote})
        fprintf('Note: %s\n', notes{iNote});
    end
end

fprintf('============================================================\n\n');
end

function packageNote = resolve_package_note(packageName)
% Resolve a short human-readable note for one known dependency.

switch upper(strtrim(packageName))
    case 'HAI_LANGUAGE'
        packageNote = ' (hierarchical active-inference utilities)';
    case 'TRIALBOX'
        packageNote = ' (resolveFunctionParams and parameter helpers)';
    case 'SPM'
        packageNote = ' (MDP / active-inference solver utilities)';
    otherwise
        packageNote = '';
end
end

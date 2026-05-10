function info = vb_describe_lower_level_call(mdp, OPTIONS, runnerHandle)
% Summarise how the lower level would be called in SPM vs the local fork.

if nargin < 3 || isempty(runnerHandle)
    runnerHandle = str2func('VB_MDP_X');
end

[forkMdp, overrides] = vb_apply_level_option_overrides(mdp, OPTIONS);

info = struct();
info.callSPM = struct( ...
    'runner', 'spm_MDP_VB_X', ...
    'signature', 'spm_MDP_VB_X(mdp)', ...
    'nargin', 1);
info.callFork = struct( ...
    'runner', func2str(runnerHandle), ...
    'signature', sprintf('%s(mdp, OPTIONS)', func2str(runnerHandle)), ...
    'nargin', 2);
info.baseParams = local_extract_params(mdp);
info.forkParams = local_extract_params(forkMdp);
info.overrides = overrides;
info.changedFields = local_changed_fields(overrides);

function params = local_extract_params(x)
fields = {'level', 'alpha', 'beta', 'tau', 'chi', 'erp', 'VBNi'};
params = struct();
for iField = 1:numel(fields)
    fieldName = fields{iField};
    if isfield(x, fieldName)
        params.(fieldName) = x.(fieldName);
    else
        params.(fieldName) = [];
    end
end

function changed = local_changed_fields(overridesStruct)
allFields = fieldnames(overridesStruct);
mask = false(size(allFields));
for iField = 1:numel(allFields)
    mask(iField) = overridesStruct.(allFields{iField}).changed;
end
changed = allFields(mask);

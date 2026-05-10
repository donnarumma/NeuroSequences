function [mdpOut, overrides] = vb_apply_level_option_overrides(mdpIn, OPTIONS)
% Apply the entry-time overrides that VB_MDP_X imposes from OPTIONS.level.
% This makes the fork/SPM difference inspectable outside the monolithic runner.

mdpOut = mdpIn;
overrides = struct();

fields = {
    'alpha', 512, true;
    'beta', 1, true;
    'tau', 4, true;
    'chi', 1/64, true;
    'erp', 4, false;
    'VBNi', 16, true;
    };

hasLevelOverrides = isstruct(OPTIONS) && isfield(OPTIONS, 'level') && ...
    isfield(mdpIn, 'level') && mdpIn.level <= numel(OPTIONS.level);

if hasLevelOverrides
    levelPms = OPTIONS.level(mdpIn.level);
else
    levelPms = struct();
end

for iField = 1:size(fields, 1)
    fieldName = fields{iField, 1};
    defaultValue = fields{iField, 2};
    useLevelOverride = fields{iField, 3};

    if isfield(mdpIn, fieldName)
        beforeValue = mdpIn.(fieldName);
    else
        beforeValue = [];
    end

    afterValue = beforeValue;
    source = 'mdp';

    if useLevelOverride && isfield(levelPms, fieldName)
        afterValue = levelPms.(fieldName);
        mdpOut.(fieldName) = afterValue;
        source = sprintf('OPTIONS.level(%d).%s', mdpIn.level, fieldName);
    elseif isempty(beforeValue)
        afterValue = defaultValue;
        mdpOut.(fieldName) = afterValue;
        source = 'runner_default';
    end

    overrides.(fieldName) = struct( ...
        'before', beforeValue, ...
        'after', afterValue, ...
        'source', source, ...
        'changed', ~isequaln(beforeValue, afterValue));
end

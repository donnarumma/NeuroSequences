function MDP = run_hai_trial(langparams, dictionary, parSource)
%RUN_HAI_TRIAL Execute one HAI model and optionally post-process it.

if nargin < 3 || isempty(parSource)
    pms = default_run_hai_trial_params();
else
    pms = default_run_hai_trial_params(parSource);
end

MDP = HAI_RUN(langparams, dictionary);

if pms.applySmartMDP
    MDP = HAI_smartMDP(MDP);
end
end

function pms = default_run_hai_trial_params(parSource)
% Default execution options for run_hai_trial.

pms.applySmartMDP = true; % If true, post-process the raw HAI_RUN output with HAI_smartMDP.

if nargin < 1 || isempty(parSource)
    return;
end

fieldNames = fieldnames(parSource);
for fieldIndex = 1:numel(fieldNames)
    pms.(fieldNames{fieldIndex}) = parSource.(fieldNames{fieldIndex});
end
end

function trialTitle = build_sequence_policy_title(MDP, data_trial)
%BUILD_SEQUENCE_POLICY_TITLE Build the canonical policy label for one sample trial.

trialTitle = '';

if exist('checkMDPTrial', 'file')
    try
        [~, trialLabel] = checkMDPTrial(MDP);
        trialTitle = trialLabel;
    catch
        trialTitle = '';
    end
end

if isempty(trialTitle) && isfield(data_trial, 'trialLabel') && ~isempty(data_trial.trialLabel)
    trialTitle = data_trial.trialLabel;
end

if isempty(trialTitle)
    trialTitle = data_trial.trialName;
end
end

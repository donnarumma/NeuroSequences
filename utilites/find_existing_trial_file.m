function existingTrialFile = find_existing_trial_file(saveDir, pms, sequenceModel)
%FIND_EXISTING_TRIAL_FILE Find a previously-saved trial with matching metadata.

if ~isfield(pms, 'trialDescription') || isempty(pms.trialDescription)
    pms.trialDescription = build_sequence_trial_description(sequenceModel, pms);
end

trialStem = sprintf('MDP_%s_%s', pms.executorName, pms.trialDescription);
trialPattern = [saveDir trialStem '_*.mat'];
trialFiles = dir(trialPattern);

if isempty(trialFiles)
    existingTrialFile = '';
    return;
end

[~, latestIndex] = max([trialFiles.datenum]);
existingTrialFile = fullfile(trialFiles(latestIndex).folder, trialFiles(latestIndex).name);
end

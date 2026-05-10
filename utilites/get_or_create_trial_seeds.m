function randsTrials = get_or_create_trial_seeds(saveDir, nTasks)
%GET_OR_CREATE_TRIAL_SEEDS Reuse or create one random seed per trial.

seedsFile = fullfile(saveDir, 'trialSeeds.mat');

if isfile(seedsFile)
    seedsData = load(seedsFile, 'randsTrials');

    if isfield(seedsData, 'randsTrials') && numel(seedsData.randsTrials) == nTasks
        randsTrials = seedsData.randsTrials(:);
        return;
    end
end

randsTrials = randi(2^9, nTasks, 1);
save(seedsFile, 'randsTrials', '-v7.3');
end

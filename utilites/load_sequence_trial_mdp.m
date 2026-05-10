function [MDP, mdpFile] = load_sequence_trial_mdp(testDir, trialNumber)
%LOAD_SEQUENCE_TRIAL_MDP Load the newest MDP file matching one trial number.

matches = dir(fullfile(testDir, ['MDP_*Trial' num2str(trialNumber) '_*.mat']));
if isempty(matches)
    error('%s:MissingTrialMDP', mfilename, ...
        'No MDP file found for trial %d in %s.', trialNumber, testDir);
end

[~, latestIndex] = max([matches.datenum]);
mdpFile = fullfile(matches(latestIndex).folder, matches(latestIndex).name);
loaded = load(mdpFile, 'MDP');
MDP = loaded.MDP;
end

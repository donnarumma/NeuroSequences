function data_trial = build_sensor_trial_data(MDP, trialIndex, pms)
%BUILD_SENSOR_TRIAL_DATA Reconstruct one sensor trial as data_trials.

if nargin < 3 || isempty(pms)
    pms = default_build_sensor_trial_params();
else
    pms = default_build_sensor_trial_params(pms);
end

if iscell(MDP)
    sensorMDP = MDP{1};
else
    sensorMDP = MDP;
end

dictionary = feval(pms.dictionary);
trialLabel = HAI_retrieveLevel(dictionary.STATES{2}{trialIndex}, '');
trialName = trialLabel(pms.trialNameIndices);

nSensory = numel(dictionary.STATES{1});
nSteps = numel(sensorMDP.mdp);
[popFR, tPopFR, labEpochs] = HAI_MDPtoFiringRates(sensorMDP.mdp(1), pms.iFactor, pms.dt);
tPopFR = tPopFR / tPopFR(end);

for iStep = 2:nSteps
    [curPopFR, curTpopFR, curLabEpochs] = ...
        HAI_MDPtoFiringRates(sensorMDP.mdp(iStep), pms.iFactor, pms.dt);
    curTpopFR = curTpopFR / curTpopFR(end);
    popFR = [popFR, curPopFR]; %#ok<AGROW>
    tPopFR = [tPopFR, iStep - 1 + curTpopFR]; %#ok<AGROW>
    labEpochs = [labEpochs, curLabEpochs * iStep]; %#ok<AGROW>
end

matches = false(nSensory, 1);
matches(1:pms.nActions) = true;
popFR = popFR(matches, :);

type1 = ismember(pms.actions, trialName(1));
type2 = ismember(pms.actions, trialName(2));
type3 = ismember(pms.actions, trialName(3));

popFR = smoothFR(popFR, labEpochs == pms.cueEpochs(1), type1, pms.smoothOptions);
popFR = smoothFR(popFR, labEpochs == pms.cueEpochs(2), type2, pms.smoothOptions);
popFR = smoothFR(popFR, labEpochs == pms.cueEpochs(3), type3, pms.smoothOptions);

percSide = (1 - pms.percCenter) / 2;
[~, nTimes] = size(popFR);
popFRcosine1 = popFR;
popFRcosine2 = popFR;
popFRcosine3 = popFR;

for iTime = 1:nTimes
    if ismember(labEpochs(iTime), pms.cueEpochs)
        popFRcosine1(:, iTime) = cosineTuning(popFR(:, iTime), type1, pms.percCenter, percSide);
        popFRcosine2(:, iTime) = cosineTuning(popFR(:, iTime), type2, pms.percCenter, percSide);
        popFRcosine3(:, iTime) = cosineTuning(popFR(:, iTime), type3, pms.percCenter, percSide);
    end
end

popFRcosine = popFRcosine1 + popFRcosine2 + popFRcosine3;
popFRcosine = popFRcosine / max(popFRcosine(:));

data_trial = struct();
data_trial.popFR = popFRcosine;
data_trial.tPopFR = tPopFR;
data_trial.labEpochs = labEpochs;
data_trial.trialName = trialName;
data_trial.trialLabel = trialName;
data_trial.signalMode = 'preprocessedPopFR';
end

function pms = default_build_sensor_trial_params(parSource)
% Default preprocessing settings shared by the sensor collector.

pms.dictionary = 'DICTIONARY_ABCDEF_Neutral_2LEV';
pms.trialNameIndices = [3, 5, 7];
pms.iFactor = 1;
pms.dt = 1 / 64;
pms.nActions = 6;
pms.actions = {'A', 'B', 'C', 'D', 'E', 'F'};
pms.percCenter = 0.75;
pms.cueEpochs = [2, 3, 4];

pms.smoothOptions = struct();
pms.smoothOptions.extendLR = [1, 0];
pms.smoothOptions.winShape = 'halfcos';
pms.smoothOptions.fillOutside = 'keep';
pms.smoothOptions.norm = struct('type', 'none', 'useMask', true);
pms.smoothOptions.keepAllNeurons = true;

if nargin < 1 || isempty(parSource)
    return;
end

fieldNames = fieldnames(parSource);
for fieldIndex = 1:numel(fieldNames)
    pms.(fieldNames{fieldIndex}) = parSource.(fieldNames{fieldIndex});
end
end

function data_trials = build_mushiake_trial_data(MDP, trialIndex, pms)
%BUILD_MUSHIAKE_TRIAL_DATA Reconstruct one or more Mushiake data_trials entries.

if nargin < 3 || isempty(pms)
    pms = default_mushiake_collect_params();
else
    pms = default_mushiake_collect_params(pms);
end

if iscell(MDP)
    mushiakeMDP = MDP{1};
else
    mushiakeMDP = MDP;
end

MDP_Low = mushiakeMDP.mdp;
if strcmpi(pms.firingRateMode, 'legacy_hai')
    [popFR, tPopFR, labEpochs] = HAI_MDPtoFiringRates(MDP_Low, pms.iFactor, pms.dt);
else
    [popFR, tPopFR, labEpochs] = mushiake_MDPtoFiringRates( ...
        MDP_Low, pms.iFactor, pms.dt, pms.firingRateMode, ...
        pms.policySharpness, pms.policyWeightSource, pms.policyTimeWeightPower);
end
nPops = size(popFR, 1);
nBins = sum(labEpochs == 1);

if pms.addFlatPrior
    popFR = [ones(nPops, nBins) / nPops, popFR];
end

if pms.smoothWindow > 1
    for iPop = 1:nPops
        popFR(iPop, :) = smooth(popFR(iPop, :), pms.smoothWindow);
    end
end

if pms.addFlatPrior
    btime = tPopFR(end) + (1:nBins) * mean(diff(tPopFR));
    tPopFR = [tPopFR, btime];
    labEpochs = [zeros(1, nBins), labEpochs];
end

tPopFR = tPopFR / tPopFR(end);
trialName = [pms.actions{MDP_Low.s(2, 2:end)}];

goalState = NaN;
if isfield(MDP_Low, 'C') && numel(MDP_Low.C) >= 1 && ~isempty(MDP_Low.C{1})
    [~, goalState] = max(MDP_Low.C{1}(:, 1));
end

baseTrial = struct();
baseTrial.popFR = popFR;
baseTrial.tPopFR = tPopFR;
baseTrial.labEpochs = labEpochs;
baseTrial.trialName = trialName;
baseTrial.trialLabel = trialName;
baseTrial.signalMode = 'preprocessedPopFR';
baseTrial.iMushiake = mushiakeMDP.iMushiake;
baseTrial.goalState = goalState;
baseTrial.sourceTrialIndex = trialIndex;

nReplications = max(1, round(pms.trialReplications));
data_trials = repmat(baseTrial, nReplications, 1);
for iReplication = 1:nReplications
    data_trials(iReplication).replicateIndex = iReplication;
end
end

function pms = default_mushiake_collect_params(parSource)
% Default preprocessing parameters for collected Mushiake trials.

pms.iFactor = 2;
pms.dt = 1 / 64;
pms.actions = {'U', 'D', 'L', 'R', 'S'};
pms.addFlatPrior = true;
pms.smoothWindow = 8;
pms.trialReplications = 1;
pms.firingRateMode = 'stacked'; % Full xn stacking by default; MAIN_Mushiake can override for diagnostics.
pms.policySharpness = 1; % Exponent applied to policy weights for committed-average diagnostics.
pms.policyWeightSource = 'final'; % Which policy posterior to freeze: first, mean, final, or a numeric column index.
pms.policyTimeWeightPower = 0; % When policyWeightSource is mean, bias the average toward later columns of R.

if nargin < 1 || isempty(parSource)
    return;
end

fieldNames = fieldnames(parSource);
for fieldIndex = 1:numel(fieldNames)
    pms.(fieldNames{fieldIndex}) = parSource.(fieldNames{fieldIndex});
end
end

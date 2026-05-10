function [popFiringRates, time, labEpochs] = mushiake_MDPtoFiringRates(MDP, factor, dt, mode, policySharpness, policyWeightSource, policyTimeWeightPower)
%MUSHIAKE_MDPTOFIRINGRATES Convert xn into firing rates for Mushiake plots.
% Modes:
%   stacked           - full (represented-epoch, current-epoch) stacking
%   diagonal_expanded - keep the same population layout, but only place
%                       xn(:, :, t, t) in the block of the current epoch
%   map_policy_expanded - full stacking taken from the most probable policy
%                         at each current epoch, using xnP instead of the
%                         policy-averaged xn
%   committed_average_expanded - full stacking from xnP using one fixed
%                         policy posterior over the whole trial, taken from
%                         the final available column of MDP.R
%   cumulative_average_expanded - full stacking from xnP using a policy
%                         posterior averaged only up to the current epoch,
%                         to preserve a more incremental plan build-up

if nargin < 4 || isempty(mode)
    mode = 'stacked';
end
if nargin < 5 || isempty(policySharpness)
    policySharpness = 1;
end
if nargin < 6 || isempty(policyWeightSource)
    policyWeightSource = 'final';
end
if nargin < 7 || isempty(policyTimeWeightPower)
    policyTimeWeightPower = 0;
end

xn = MDP.xn{factor};
[nBins, nStates, nRepEpochs, nCurrentEpochs] = size(xn);

nPopulations = nStates * nRepEpochs;
nTimes = nBins * nCurrentEpochs;

popFiringRates = zeros(nPopulations, nTimes);
time = (1:nTimes) * dt;
labEpochs = zeros(1, nTimes);

if strcmpi(mode, 'committed_average_expanded')
    if ~isfield(MDP, 'xnP') || numel(MDP.xnP) < factor || isempty(MDP.xnP{factor})
        error('%s:MissingPolicyStates', mfilename, ...
            'committed_average_expanded requires MDP.xnP{%d}.', factor);
    end
    if ~isfield(MDP, 'R') || isempty(MDP.R)
        error('%s:MissingPolicyPosterior', mfilename, ...
            'committed_average_expanded requires MDP.R.');
    end
    policyWeights = resolve_policy_weights(MDP, policyWeightSource, ...
        policyTimeWeightPower, policySharpness, size(MDP.R, 2));
end

for iCurrentEpoch = 1:nCurrentEpochs
    timeWindow = (1:nBins) + (iCurrentEpoch - 1) * nBins;
    labEpochs(timeWindow) = iCurrentEpoch;

    switch lower(mode)
        case 'stacked'
            for iRepEpoch = 1:nRepEpochs
                rowWindow = (1:nStates) + (iRepEpoch - 1) * nStates;
                popFiringRates(rowWindow, timeWindow) = squeeze(xn(:, :, iRepEpoch, iCurrentEpoch))';
            end

        case 'diagonal_expanded'
            if iCurrentEpoch <= nRepEpochs
                rowWindow = (1:nStates) + (iCurrentEpoch - 1) * nStates;
                popFiringRates(rowWindow, timeWindow) = squeeze(xn(:, :, iCurrentEpoch, iCurrentEpoch))';
            end

        case 'map_policy_expanded'
            if ~isfield(MDP, 'xnP') || numel(MDP.xnP) < factor || isempty(MDP.xnP{factor})
                error('%s:MissingPolicyStates', mfilename, ...
                    'map_policy_expanded requires MDP.xnP{%d}.', factor);
            end
            if ~isfield(MDP, 'R') || isempty(MDP.R)
                error('%s:MissingPolicyPosterior', mfilename, ...
                    'map_policy_expanded requires MDP.R.');
            end

            policyEpoch = min(iCurrentEpoch, size(MDP.R, 2));
            [~, iPolicy] = max(MDP.R(:, policyEpoch));

            for iRepEpoch = 1:nRepEpochs
                rowWindow = (1:nStates) + (iRepEpoch - 1) * nStates;
                popFiringRates(rowWindow, timeWindow) = ...
                    squeeze(MDP.xnP{factor}(:, :, iRepEpoch, iCurrentEpoch, iPolicy))';
            end

        case 'committed_average_expanded'
            for iRepEpoch = 1:nRepEpochs
                rowWindow = (1:nStates) + (iRepEpoch - 1) * nStates;
                for iPolicy = 1:numel(policyWeights)
                    popFiringRates(rowWindow, timeWindow) = ...
                        popFiringRates(rowWindow, timeWindow) + ...
                        squeeze(MDP.xnP{factor}(:, :, iRepEpoch, iCurrentEpoch, iPolicy))' * policyWeights(iPolicy);
                end
            end

        case 'cumulative_average_expanded'
            if ~isfield(MDP, 'xnP') || numel(MDP.xnP) < factor || isempty(MDP.xnP{factor})
                error('%s:MissingPolicyStates', mfilename, ...
                    'cumulative_average_expanded requires MDP.xnP{%d}.', factor);
            end
            if ~isfield(MDP, 'R') || isempty(MDP.R)
                error('%s:MissingPolicyPosterior', mfilename, ...
                    'cumulative_average_expanded requires MDP.R.');
            end

            cumulativeWeights = resolve_policy_weights(MDP, policyWeightSource, ...
                policyTimeWeightPower, policySharpness, iCurrentEpoch);

            for iRepEpoch = 1:nRepEpochs
                rowWindow = (1:nStates) + (iRepEpoch - 1) * nStates;
                for iPolicy = 1:numel(cumulativeWeights)
                    popFiringRates(rowWindow, timeWindow) = ...
                        popFiringRates(rowWindow, timeWindow) + ...
                        squeeze(MDP.xnP{factor}(:, :, iRepEpoch, iCurrentEpoch, iPolicy))' * cumulativeWeights(iPolicy);
                end
            end

        otherwise
            error('%s:UnknownMode', mfilename, ...
                'Unknown firing-rate extraction mode: %s', mode);
    end
end
end

function policyWeights = resolve_policy_weights(MDP, policyWeightSource, policyTimeWeightPower, policySharpness, maxEpoch)
% Resolve the policy weighting vector used to mix xnP into a readout.

maxEpoch = max(1, min(size(MDP.R, 2), round(maxEpoch)));

if isnumeric(policyWeightSource)
    sourceKey = '';
    numericColumn = policyWeightSource;
else
    sourceKey = lower(char(policyWeightSource));
    numericColumn = str2double(sourceKey);
end

switch sourceKey
    case 'final'
        policyWeights = MDP.R(:, maxEpoch);
    case 'first'
        policyWeights = MDP.R(:, 1);
    case 'mean'
        policySlice = MDP.R(:, 1:maxEpoch);
        if policyTimeWeightPower == 0
            policyWeights = mean(policySlice, 2);
        else
            timeWeights = (1:size(policySlice, 2)) .^ policyTimeWeightPower;
            timeWeights = timeWeights / sum(timeWeights);
            policyWeights = policySlice * timeWeights';
        end
    otherwise
        if ~isnan(numericColumn)
            numericColumn = max(1, min(size(MDP.R, 2), round(numericColumn)));
            policyWeights = MDP.R(:, numericColumn);
        else
            error('%s:UnknownPolicyWeightSource', mfilename, ...
                'Unknown policy weight source: %s', char(policyWeightSource));
        end
end

if policySharpness ~= 1
    policyWeights = policyWeights .^ policySharpness;
end
policyWeights = policyWeights / sum(policyWeights);
end

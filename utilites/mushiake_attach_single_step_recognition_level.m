function MDP = mushiake_attach_single_step_recognition_level(MDP, parSource)
%MUSHIAKE_ATTACH_SINGLE_STEP_RECOGNITION_LEVEL
% Attach a one-step recognition mirror under the current Mushiake low level.
%
% The added sub-level is stored as:
%   MDP.mdp(1).mdp(iEpoch)
%
% Each inner element is a single-step copy of the current low level,
% collapsed onto one epoch using the diagonal posterior slice
% xn(:, :, iEpoch, iEpoch). This preserves the current outer computation
% while exposing an explicit recognition level for state/action readout.

if nargin < 2 || isempty(parSource)
    pms = default_mushiake_single_step_params();
else
    pms = default_mushiake_single_step_params(parSource);
end

if ~pms.enabled
    return;
end

if iscell(MDP)
    for iEntry = 1:numel(MDP)
        MDP{iEntry} = attach_to_root(MDP{iEntry}, pms);
    end
else
    MDP = attach_to_root(MDP, pms);
end
end

function root = attach_to_root(root, pms)
% Add the nested recognition level to each available low-level MDP.

if ~isstruct(root) || ~isfield(root, 'mdp') || isempty(root.mdp)
    return;
end

for iLow = 1:numel(root.mdp)
    parentLow = strip_existing_recognition_level(root.mdp(iLow));
    root.mdp(iLow).mdp = build_single_step_sequence(parentLow, pms);
    root.mdp(iLow).singleStepRecognitionInfo = struct( ...
        'enabled', true, ...
        'mode', pms.mode, ...
        'nEpochs', numel(root.mdp(iLow).mdp), ...
        'description', 'Single-step mirror of the solved low-level posterior');
end
end

function subMdps = build_single_step_sequence(parentLow, pms)
% Build one inner single-step MDP per outer epoch.

nEpochs = infer_parent_epoch_count(parentLow);
if nEpochs < 1
    subMdps = struct([]);
    return;
end

firstSubMdp = build_single_step_mdp(parentLow, 1, pms);
subMdps = repmat(firstSubMdp, 1, nEpochs);
for iEpoch = 2:nEpochs
    subMdps(iEpoch) = build_single_step_mdp(parentLow, iEpoch, pms);
end
end

function sub = build_single_step_mdp(parentLow, iEpoch, pms)
% Collapse the solved low-level MDP into one single-step recognition MDP.

sub = strip_existing_recognition_level(parentLow);
sub.T = 1;
sub.singleStepRecognition = true;
sub.recognitionEpoch = iEpoch;
sub.recognitionMode = pms.mode;
sub.parentEpochCount = infer_parent_epoch_count(parentLow);

sub.s = build_single_step_state_matrix(parentLow, iEpoch);
sub.recognisedStateIndex = resolve_factor_state_index(parentLow, 1, iEpoch);
sub.recognisedActionIndex = resolve_factor_state_index(parentLow, 2, iEpoch);
sub.recognisedStateLabel = resolve_factor_state_label(parentLow, 1, sub.recognisedStateIndex);
sub.recognisedActionLabel = resolve_factor_state_label(parentLow, 2, sub.recognisedActionIndex);

if isfield(parentLow, 'X') && ~isempty(parentLow.X)
    for iFactor = 1:numel(parentLow.X)
        sub.X{iFactor} = extract_single_epoch_column(parentLow.X{iFactor}, iEpoch);
    end
end

if isfield(parentLow, 'xn') && ~isempty(parentLow.xn)
    for iFactor = 1:numel(parentLow.xn)
        sub.xn{iFactor} = extract_single_epoch_xn(parentLow.xn{iFactor}, iEpoch, pms.mode);
    end
end

if isfield(parentLow, 'xnP') && ~isempty(parentLow.xnP)
    for iFactor = 1:numel(parentLow.xnP)
        sub.xnP{iFactor} = extract_single_epoch_xnp(parentLow.xnP{iFactor}, iEpoch, pms.mode);
    end
end

if isfield(parentLow, 'R') && ~isempty(parentLow.R)
    sub.R = extract_single_epoch_column(parentLow.R, iEpoch);
end

if isfield(parentLow, 'V') && ~isempty(parentLow.V)
    sub.V = extract_single_epoch_firstdim(parentLow.V, iEpoch);
end

if isfield(parentLow, 'o') && ~isempty(parentLow.o)
    sub.o = extract_single_epoch_observations(parentLow.o, iEpoch);
end

if isfield(parentLow, 'u') && ~isempty(parentLow.u)
    sub.u = extract_single_epoch_column(parentLow.u, iEpoch);
end
end

function stateMatrix = build_single_step_state_matrix(parentLow, iEpoch)
% Build one column of recognised factor states for the inner one-step MDP.

nFactors = 0;
if isfield(parentLow, 'D') && ~isempty(parentLow.D)
    nFactors = numel(parentLow.D);
elseif isfield(parentLow, 'X') && ~isempty(parentLow.X)
    nFactors = numel(parentLow.X);
elseif isfield(parentLow, 's') && ~isempty(parentLow.s)
    nFactors = size(parentLow.s, 1);
end

stateMatrix = ones(max(1, nFactors), 1);
for iFactor = 1:nFactors
    stateIndex = resolve_factor_state_index(parentLow, iFactor, iEpoch);
    if ~isnan(stateIndex) && stateIndex >= 1
        stateMatrix(iFactor, 1) = stateIndex;
    end
end
end

function out = extract_single_epoch_column(dataIn, iEpoch)
% Keep only the relevant time column for a single-step readout.

out = dataIn;
if isempty(dataIn) || ~ismatrix(dataIn)
    return;
end

timeIndex = min(size(dataIn, 2), max(1, iEpoch));
out = dataIn(:, timeIndex);
end

function out = extract_single_epoch_firstdim(dataIn, iEpoch)
% Keep only the relevant outer-epoch slice along the first dimension.

out = dataIn;
if isempty(dataIn) || ndims(dataIn) < 2
    return;
end

epochIndex = min(size(dataIn, 1), max(1, iEpoch));
subs = repmat({':'}, 1, ndims(dataIn));
subs{1} = epochIndex;
out = dataIn(subs{:});
end

function out = extract_single_epoch_observations(dataIn, iEpoch)
% Collapse observation cells to a single current epoch where possible.

out = dataIn;
if isempty(dataIn)
    return;
end

if iscell(dataIn)
    out = dataIn;
    for iObs = 1:numel(dataIn)
        if isempty(dataIn{iObs}) || ~ismatrix(dataIn{iObs})
            continue;
        end
        timeIndex = min(size(dataIn{iObs}, 2), max(1, iEpoch));
        out{iObs} = dataIn{iObs}(:, timeIndex);
    end
    return;
end

if ismatrix(dataIn)
    timeIndex = min(size(dataIn, 2), max(1, iEpoch));
    out = dataIn(:, timeIndex);
end
end

function out = extract_single_epoch_xn(xnFactor, iEpoch, mode)
% Extract one (represented, current) epoch pair from xn.

out = xnFactor;
if isempty(xnFactor) || ndims(xnFactor) < 4
    return;
end

[~, ~, nRepEpochs, nCurrentEpochs] = size(xnFactor);
[repEpoch, currentEpoch] = resolve_epoch_pair(iEpoch, nRepEpochs, nCurrentEpochs, mode);
out = xnFactor(:, :, repEpoch, currentEpoch);
out = reshape(out, size(xnFactor, 1), size(xnFactor, 2), 1, 1);
end

function out = extract_single_epoch_xnp(xnPFactor, iEpoch, mode)
% Extract one (represented, current) epoch pair from xnP.

out = xnPFactor;
if isempty(xnPFactor) || ndims(xnPFactor) < 5
    return;
end

[~, ~, nRepEpochs, nCurrentEpochs, nPolicies] = size(xnPFactor);
[repEpoch, currentEpoch] = resolve_epoch_pair(iEpoch, nRepEpochs, nCurrentEpochs, mode);
out = xnPFactor(:, :, repEpoch, currentEpoch, :);
out = reshape(out, size(xnPFactor, 1), size(xnPFactor, 2), 1, 1, nPolicies);
end

function [repEpoch, currentEpoch] = resolve_epoch_pair(iEpoch, nRepEpochs, nCurrentEpochs, mode)
% Map one outer epoch to one single-step inner recognition slice.

repEpoch = min(max(1, iEpoch), max(1, nRepEpochs));
currentEpoch = min(max(1, iEpoch), max(1, nCurrentEpochs));

switch lower(char(mode))
    case 'diagonal'
        return;
    case 'current'
        repEpoch = min(max(1, nRepEpochs), currentEpoch);
    otherwise
        % Fall back to the diagonal interpretation, which mirrors the
        % current represented state at the current task epoch.
end
end

function nEpochs = infer_parent_epoch_count(parentLow)
% Infer how many outer epochs should get one inner recognition MDP.

nEpochs = 0;

if isfield(parentLow, 'xn') && ~isempty(parentLow.xn) && ...
        numel(parentLow.xn) >= 1 && ~isempty(parentLow.xn{1}) && ...
        ndims(parentLow.xn{1}) >= 4
    nEpochs = size(parentLow.xn{1}, 4);
end

if nEpochs < 1 && isfield(parentLow, 'T') && ~isempty(parentLow.T)
    nEpochs = parentLow.T;
end

nEpochs = max(0, round(nEpochs));
end

function stateIndex = resolve_factor_state_index(parentLow, iFactor, iEpoch)
% Decode the most likely state/action at one epoch for one factor.

stateIndex = NaN;

if isfield(parentLow, 'X') && numel(parentLow.X) >= iFactor && ~isempty(parentLow.X{iFactor})
    currentX = parentLow.X{iFactor};
    if ismatrix(currentX)
        timeIndex = min(size(currentX, 2), max(1, iEpoch));
        [~, stateIndex] = max(currentX(:, timeIndex));
        return;
    end
end

if isfield(parentLow, 's') && size(parentLow.s, 1) >= iFactor && ~isempty(parentLow.s)
    timeIndex = min(size(parentLow.s, 2), max(1, iEpoch));
    stateIndex = parentLow.s(iFactor, timeIndex);
end
end

function stateLabel = resolve_factor_state_label(parentLow, iFactor, stateIndex)
% Resolve a readable label for one recognised factor state.

stateLabel = '';
if isnan(stateIndex) || stateIndex < 1
    return;
end

if isfield(parentLow, 'sname') && numel(parentLow.sname) >= iFactor && ...
        numel(parentLow.sname{iFactor}) >= stateIndex
    stateLabel = char(parentLow.sname{iFactor}{stateIndex});
    return;
end

stateLabel = sprintf('state_%d', stateIndex);
end

function low = strip_existing_recognition_level(low)
% Prevent recursive growth if the augmentation is applied twice.

if isfield(low, 'mdp')
    low = rmfield(low, 'mdp');
end
if isfield(low, 'singleStepRecognitionInfo')
    low = rmfield(low, 'singleStepRecognitionInfo');
end
if isfield(low, 'singleStepRecognition')
    low = rmfield(low, 'singleStepRecognition');
end
if isfield(low, 'recognitionEpoch')
    low = rmfield(low, 'recognitionEpoch');
end
if isfield(low, 'recognitionMode')
    low = rmfield(low, 'recognitionMode');
end
if isfield(low, 'parentEpochCount')
    low = rmfield(low, 'parentEpochCount');
end
if isfield(low, 'recognisedStateIndex')
    low = rmfield(low, 'recognisedStateIndex');
end
if isfield(low, 'recognisedActionIndex')
    low = rmfield(low, 'recognisedActionIndex');
end
if isfield(low, 'recognisedStateLabel')
    low = rmfield(low, 'recognisedStateLabel');
end
if isfield(low, 'recognisedActionLabel')
    low = rmfield(low, 'recognisedActionLabel');
end
end

function pms = default_mushiake_single_step_params(parSource)
% Default options for the nested one-step recognition sub-level.

pms.enabled = true;
pms.mode = 'diagonal';

if nargin < 1 || isempty(parSource)
    return;
end

fieldNames = fieldnames(parSource);
for iField = 1:numel(fieldNames)
    pms.(fieldNames{iField}) = parSource.(fieldNames{iField});
end
end

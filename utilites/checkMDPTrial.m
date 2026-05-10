function [isok, trialLabel, details] = checkMDPTrial(MDP)
%CHECKMDPTRIAL Validate one sequence trial directly from the MDP posterior.
%
% This checker does not rely on spike conversion. It:
%   1) reads the resolved temporal-order type from factor 3,
%   2) reconstructs the symbolic target sequence from factor 2,
%   3) reconstructs the executed action sequence from factor 1,
%   4) compares executed vs expected order.
%
% OUTPUTS
%   isok        true if execution and target trajectory are consistent
%   trialLabel  symbolic target sequence with resolved type label (e.g. ABCbw)
%   details     struct with decoded sequences and factor-state summaries

cMDP = MDP{1}.mdp;

[factor1Path, factor1Labels] = decode_factor_path(cMDP.X{1}, cMDP.sname{1});
[factor2Path, factor2Labels] = decode_factor_path(cMDP.X{2}, cMDP.sname{2});
[factor3Path, factor3Labels] = decode_factor_path(cMDP.X{3}, cMDP.sname{3});

typeLabel = strtrim(factor3Labels{end});
presentedSequence = collapse_target_symbols(factor2Labels);
executedSequence = collapse_goto_symbols(factor1Labels);
expectedSequence = apply_type_to_sequence(presentedSequence, typeLabel);

trialLabel = [presentedSequence typeLabel];

isTypeResolved = ~isempty(typeLabel) && ~strcmp(typeLabel, 'idk');
hasTargetSequence = ~isempty(presentedSequence);
hasExecution = ~isempty(executedSequence);
isok = isTypeResolved && hasTargetSequence && hasExecution && ...
    strcmp(executedSequence, expectedSequence);

details = struct();
details.typeLabel = typeLabel;
details.presentedSequence = presentedSequence;
details.executedSequence = executedSequence;
details.expectedSequence = expectedSequence;
details.factor1Path = factor1Path;
details.factor2Path = factor2Path;
details.factor3Path = factor3Path;
details.factor1Labels = factor1Labels;
details.factor2Labels = factor2Labels;
details.factor3Labels = factor3Labels;
details.isTypeResolved = isTypeResolved;
end

function [statePath, labelPath] = decode_factor_path(X, labels)
% Decode the most likely state label at each timestep.

[~, statePath] = max(X, [], 1);
statePath = statePath(:)';

labelPath = cell(1, numel(statePath));
for timeIndex = 1:numel(statePath)
    labelPath{timeIndex} = normalise_label(labels{statePath(timeIndex)});
end
end

function sequence = collapse_target_symbols(labelPath)
% Extract the symbolic target sequence from factor-2 labels.

symbols = '';
for timeIndex = 1:numel(labelPath)
    symbol = extract_target_symbol(labelPath{timeIndex});

    if isempty(symbol)
        continue;
    end

    if isempty(symbols) || symbols(end) ~= symbol
        symbols(end + 1) = symbol; %#ok<AGROW>
    end
end

sequence = symbols;
end

function sequence = collapse_goto_symbols(labelPath)
% Extract the executed action sequence from factor-1 labels.

symbols = '';
for timeIndex = 1:numel(labelPath)
    symbol = extract_goto_symbol(labelPath{timeIndex});

    if isempty(symbol)
        continue;
    end

    if isempty(symbols) || symbols(end) ~= symbol
        symbols(end + 1) = symbol; %#ok<AGROW>
    end
end

sequence = symbols;
end

function sequenceOut = apply_type_to_sequence(sequenceIn, typeLabel)
% Reorder the presented target sequence according to the resolved type.

sequenceOut = sequenceIn;

if isempty(sequenceIn) || isempty(typeLabel)
    return;
end

switch typeLabel
    case 'fw'
        return;
    case 'bw'
        sequenceOut = fliplr(sequenceIn);
        return;
end

orderDigits = regexp(typeLabel, '\d', 'match');

if isempty(orderDigits)
    return;
end

order = str2double(orderDigits);
if numel(order) ~= numel(sequenceIn) || any(isnan(order))
    return;
end

if numel(unique(order)) ~= numel(order) || any(order < 1) || ...
        any(order > numel(sequenceIn))
    return;
end

sequenceOut = sequenceIn(order);
end

function symbol = extract_goto_symbol(label)
% Extract the symbolic target letter from GoToTarget labels.

symbol = '';

if strncmp(label, 'GoTo', 4) && numel(label) >= 5
    candidate = label(5);
else
    candidate = '';
end

if ~isempty(candidate) && isstrprop(candidate, 'alpha')
    symbol = upper(candidate);
end
end

function symbol = extract_target_symbol(label)
% Extract the symbolic target letter from factor-2 target labels.

symbol = '';

if isempty(label)
    return;
end

candidate = label(1);
if isstrprop(candidate, 'alpha')
    symbol = upper(candidate);
end
end

function label = normalise_label(rawLabel)
% Convert labels from char/string/cellstr-like inputs to plain char.

if isstring(rawLabel)
    label = char(rawLabel);
else
    label = char(rawLabel);
end

label = strtrim(label);
end

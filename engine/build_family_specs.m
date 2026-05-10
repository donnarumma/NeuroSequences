function familySpecs = build_family_specs(goDirections, typeInfo, pms)
%BUILD_FAMILY_SPECS Construct the active sequence families.
%
% Each family corresponds to a sequence-length class:
%   3D = full 3-item sequences
%   2D = shortened 2-item sequences
%   1D = single-item sequences
%
% For each family, the function stores:
%   - symbolic target sequences (e.g. ABC, AC, B),
%   - execution sequences in GoToTarget space including neutral states,
%   - sequence generators used by SequenceTransitions,
%   - compatible type indices,
%   - neutral and terminal action states.
%
% OUTPUT
%   familySpecs is a struct array with fields:
%     name, labelLength, goSequences, sequences, goGenerator, typeIndices,
%     goNeutrals, goEnds, nSteps, nSequences

familySpecs = struct( ...
    'name', {}, ...
    'labelLength', {}, ...
    'goSequences', {}, ...
    'sequences', {}, ...
    'goGenerator', {}, ...
    'typeIndices', {}, ...
    'goNeutrals', {}, ...
    'goEnds', {}, ...
    'nSteps', {}, ...
    'nSequences', {});

% -------------------------------------------------------------------------
% 3D family
% -------------------------------------------------------------------------
if pms.include3D && ~pms.only2D
    [goSequences, sequences, goGenerator, goNeutrals, goEnds] = ...
        Sequences3D(goDirections, typeInfo.selectedTypes3D, ...
        pms.minSeqLen, pms.nStayStates);

    familySpecs(end + 1) = make_family_spec( ... %#ok<AGROW>
        '3D', 3, goSequences, sequences, goGenerator, ...
        1:typeInfo.nEffectiveTypes, goNeutrals, goEnds);
end

% -------------------------------------------------------------------------
% 2D family
% -------------------------------------------------------------------------
if pms.include2D
    [types2D, typeIndices2D] = select_2d_types(typeInfo);

    if ~isempty(types2D)
        [goSequences, sequences, goGenerator, goNeutrals, goEnds] = ...
            Sequences2D(goDirections, types2D, pms.sequence2DMaxLen, ...
            pms.minSeqLen, pms.nStayStates);

        familySpecs(end + 1) = make_family_spec( ... %#ok<AGROW>
            '2D', 2, goSequences, sequences, goGenerator, ...
            typeIndices2D, goNeutrals, goEnds);
    end
end

% -------------------------------------------------------------------------
% 1D family
% -------------------------------------------------------------------------
if pms.include1D
    [goSequences, sequences, goNeutrals, goEnds] = ...
        Sequences1D(goDirections, pms.sequence1DMaxLen, pms.nStayStates);

    % The 1D family can be paired with every selected type. This does not
    % change the symbolic sequence itself, but it creates one task per type.
    %
    % SequenceTransitions expects an "exploration" matrix. For 1D sequences,
    % the GoToTarget trajectory is already fully specified row-wise in
    % goSequences, so we simply use the identity ordering over the available
    % timesteps.
    goGenerator = 1:size(goSequences, 2);

    familySpecs(end + 1) = make_family_spec( ... %#ok<AGROW>
        '1D', 1, goSequences, sequences, goGenerator, ...
        1:typeInfo.nEffectiveTypes, goNeutrals, goEnds);
end
end

function familySpec = make_family_spec( ...
    name, labelLength, goSequences, sequences, goGenerator, ...
    typeIndices, goNeutrals, goEnds)
%MAKE_FAMILY_SPEC Pack one sequence family into a single struct.

familySpec              = struct();
familySpec.name         = name;
familySpec.labelLength  = labelLength;
familySpec.goSequences  = goSequences;
familySpec.sequences    = sequences;
familySpec.goGenerator  = goGenerator;
familySpec.typeIndices  = typeIndices;
familySpec.goNeutrals   = goNeutrals;
familySpec.goEnds       = goEnds;
familySpec.nSteps       = size(goSequences, 2);
familySpec.nSequences   = size(goSequences, 1);
end

function [types2D, typeIndices2D] = select_2d_types(typeInfo)
%SELECT_2D_TYPES Retain only canonical forward/backward order for 2D families.
%
% The 2D family is typically interpreted only with the directional abstractions
% corresponding to:
%   fw -> [1 2]
%   bw -> [2 1]

types2D = zeros(0, 2);
typeIndices2D = zeros(0, 1);

if ~isempty(typeInfo.forwardTypeIndex)
    types2D(end + 1, :) = [1, 2]; %#ok<AGROW>
    typeIndices2D(end + 1, 1) = typeInfo.forwardTypeIndex; %#ok<AGROW>
end

if ~isempty(typeInfo.backwardTypeIndex)
    types2D(end + 1, :) = [2, 1]; %#ok<AGROW>
    typeIndices2D(end + 1, 1) = typeInfo.backwardTypeIndex; %#ok<AGROW>
end
end

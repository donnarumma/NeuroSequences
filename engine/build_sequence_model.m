function sequenceModel = build_sequence_model(pms)
%BUILD_SEQUENCE_MODEL Construct the static generative model for the sequence task.
%
% This function defines:
%   - admissible temporal-order types (fw, bw, and optional permutations),
%   - active sequence families (3D, 2D, 1D),
%   - the common hidden and observation state spaces,
%   - hidden-state transition matrices B,
%   - observation likelihood matrices A,
%   - state priors D,
%   - policy structure V,
%   - human-readable labels for states and tasks.
%
% CONCEPTUAL DISTINCTIONS
%   type     = temporal order template (e.g. fw, bw, 132, ...)
%   family   = sequence length class (3D, 2D, 1D)
%   sequence = symbolic target content (e.g. ABC, AC, B)
%   task     = one concrete sequence under one specific type
%
% STATE-SPACE INTERPRETATION
%   Hidden factor 1 (GoToTarget):
%       latent action/execution state. This includes:
%       - effective target-directed actions (GoToA ... GoToF),
%       - neutral/delay states,
%       - terminal/end states.
%
%   Hidden factor 2 (Target):
%       target identity unfolded across trial time.
%       Each symbolic target is represented at each timestep
%       (e.g. A1...A9, B1...B9, ..., F1...F9), plus auxiliary states
%       corresponding to neutral/delay phases.
%
%   Hidden factor 3 (Type):
%       latent temporal-order state (fw, bw, other permutations, plus idk).

% -------------------------------------------------------------------------
% 1. Action directions and admissible sequence types
% -------------------------------------------------------------------------
goDirections = 1:pms.nDirs;
typeInfo = build_type_info(pms.typeMask3D);

% -------------------------------------------------------------------------
% 2. Build active sequence families
% -------------------------------------------------------------------------
familySpecs = build_family_specs(goDirections, typeInfo, pms);
if isempty(familySpecs)
    error('%s:NoFamiliesEnabled', mfilename, ...
        'At least one sequence family must be enabled.');
end

% All enabled families must share the same trial length in GoToTarget space
nSteps = unique([familySpecs.nSteps]);
if numel(nSteps) ~= 1
    error('%s:IncompatibleStepCount', mfilename, ...
        'All enabled sequence families must share the same number of steps.');
end
nSteps = nSteps(1);

% -------------------------------------------------------------------------
% 3. Determine the common GoToTarget state space
% -------------------------------------------------------------------------
% The global action space should follow the main task layout.
% We therefore prioritise:
%   3D -> 2D -> 1D
% rather than picking the family with the largest neutral/end support.
%
% This is important because the neutral and terminal state codes are part of
% the intended temporal layout of the task (delay -> cues -> delay/end).
familyNames = {familySpecs.name};

if any(strcmp(familyNames, '3D'))
    referenceFamily = find(strcmp(familyNames, '3D'), 1);
elseif any(strcmp(familyNames, '2D'))
    referenceFamily = find(strcmp(familyNames, '2D'), 1);
else
    referenceFamily = find(strcmp(familyNames, '1D'), 1);
end

goNeutralStates = familySpecs(referenceFamily).goNeutrals;
goEndStates     = familySpecs(referenceFamily).goEnds;

nGoToTargets    = max([goDirections, goNeutralStates, goEndStates]);
goTargets       = 1:nGoToTargets;

% -------------------------------------------------------------------------
% 4. Build per-family GoToTarget transitions
% -------------------------------------------------------------------------
% For each family, SequenceTransitions builds one transition matrix per:
%   (symbolic sequence) x (temporal-order template).
%
% In the GoToTarget space, each row of goSequences already contains the full
% action-layout skeleton of the trial, including neutral/delay states and
% final terminal states.
for familyIndex = 1:numel(familySpecs)
    [familySpecs(familyIndex).goTransitions, ~] = SequenceTransitions( ...
        goTargets, ...
        familySpecs(familyIndex).goSequences, ...
        familySpecs(familyIndex).goGenerator);
end

% -------------------------------------------------------------------------
% 5. Assign row indices in the concatenated symbolic-sequence table
% -------------------------------------------------------------------------
sequenceCursor = 0;
for familyIndex = 1:numel(familySpecs)
    familySpecs(familyIndex).sequenceIndices = ...
        sequenceCursor + (1:familySpecs(familyIndex).nSequences);
    sequenceCursor = familySpecs(familyIndex).sequenceIndices(end);
end

combinedGoSequences = vertcat(familySpecs.goSequences);

% The symbolic target sequence table is initially filled with a neutral
% symbolic code (nDirs+1). Then the actual symbolic targets are inserted
% after the initial delay slot(s).
%
% Example:
%   a 3-item symbolic sequence such as ABC becomes a symbolic timeline with
%   neutral slots followed by A,B,C in the appropriate positions.
combinedTargetSequences = (pms.nDirs + 1) * ones(size(combinedGoSequences));
for familyIndex = 1:numel(familySpecs)
    currentRows = familySpecs(familyIndex).sequenceIndices;
    currentSequences = familySpecs(familyIndex).sequences;
    combinedTargetSequences(currentRows, 1 + (1:size(currentSequences, 2))) = ...
        currentSequences;
end

% -------------------------------------------------------------------------
% 6. Expand symbolic target sequences into time-unfolded target states
% -------------------------------------------------------------------------
% expandedSequenceTransitions transforms symbolic target trajectories into
% an exploded state space of the form:
%   A1...A_nSteps, B1...B_nSteps, ..., plus auxiliary neutral/delay states.
%
% Thus factor 2 does not represent only "which target", but:
%   (which target) x (at which timestep of the trial).
[targetTransitionsPerSequence, expandedSequences, targetLabels] = ...
    expandedSequenceTransitions([goDirections, pms.nDirs + 1], ...
        combinedTargetSequences, 1:size(combinedTargetSequences, 2));
nTargets = numel(targetLabels);

% -------------------------------------------------------------------------
% 7. Expand families into task/policy space
% -------------------------------------------------------------------------
% Each family contributes:
%   nSequences x nCompatibleTypes
% tasks/policies.
taskCursor = 0;
for familyIndex = 1:numel(familySpecs)
    familyTaskCount = familySpecs(familyIndex).nSequences * ...
        numel(familySpecs(familyIndex).typeIndices);
    familySpecs(familyIndex).taskIndices = taskCursor + (1:familyTaskCount);
    taskCursor = familySpecs(familyIndex).taskIndices(end);
end
nTasks = taskCursor;

goTransitions = nan(nGoToTargets, nGoToTargets, nTasks);
targetTransitions = nan(nTargets, nTargets, nTasks);
expandedTaskSequences = nan(nTasks, nSteps);
typeIndexPerTask = nan(nTasks, 1);
taskLabels = cell(1, nTasks);

for familyIndex = 1:numel(familySpecs)
    familyTaskIndices = familySpecs(familyIndex).taskIndices;
    familySequenceIndices = familySpecs(familyIndex).sequenceIndices;
    goTransitions(:, :, familyTaskIndices) = familySpecs(familyIndex).goTransitions;

    nFamilySequences = familySpecs(familyIndex).nSequences;
    cursorWithinFamily = 0;

    for typeSlot = 1:numel(familySpecs(familyIndex).typeIndices)
        currentTaskIndices = familyTaskIndices(cursorWithinFamily + (1:nFamilySequences));
        currentTypeIndex = familySpecs(familyIndex).typeIndices(typeSlot);

        targetTransitions(:, :, currentTaskIndices) = ...
            targetTransitionsPerSequence(:, :, familySequenceIndices);
        expandedTaskSequences(currentTaskIndices, :) = ...
            expandedSequences(familySequenceIndices, :);
        typeIndexPerTask(currentTaskIndices) = currentTypeIndex;

        currentLabels = cell(1, nFamilySequences);
        for sequenceIndex = 1:nFamilySequences
            symbolicSequence = familySpecs(familyIndex).sequences( ...
                sequenceIndex, 1:familySpecs(familyIndex).labelLength);
            symbolicLabel = char(('A' - 1) + symbolicSequence);
            currentLabels{sequenceIndex} = ...
                [symbolicLabel typeInfo.TypeLabels{currentTypeIndex}];
        end
        taskLabels(currentTaskIndices) = currentLabels;

        cursorWithinFamily = cursorWithinFamily + nFamilySequences;
    end
end

% -------------------------------------------------------------------------
% 8. Add optional transition noise and normalise each task-specific B slice
% -------------------------------------------------------------------------
goTransitions = goTransitions + pms.transitionNoise;
for taskIndex = 1:nTasks
    goTransitions(:, :, taskIndex) = spm_norm(goTransitions(:, :, taskIndex));
    targetTransitions(:, :, taskIndex) = spm_norm(targetTransitions(:, :, taskIndex));
end

% -------------------------------------------------------------------------
% 9. Define hidden and observation spaces
% -------------------------------------------------------------------------
nEffectiveTypes         = typeInfo.nEffectiveTypes;
typeLabelsWithUnknown   = [typeInfo.TypeLabels, {'idk'}];
nTypes                  = nEffectiveTypes + 1;

nHiddens                = [nGoToTargets, nTargets, nTypes];
nObs                    = [nGoToTargets, nTargets, nTypes];

% -------------------------------------------------------------------------
% 10. Build generative model matrices B and A
% -------------------------------------------------------------------------
B = build_transition_matrices( ...
    goTransitions, targetTransitions, typeIndexPerTask, ...
    nTypes, nEffectiveTypes);

A = build_likelihood_matrices( ...
    pms, nObs, nGoToTargets, nTargets, nTypes, nSteps, typeInfo);

% -------------------------------------------------------------------------
% 11. Build state priors D and policy matrix V
% -------------------------------------------------------------------------
% D places a flat prior on GoToTarget and Target, and starts Type in the
% unknown-type state ('idk').
D = { ...
    ones(nGoToTargets, 1); ...
    ones(nTargets, 1); ...
    zeros(nTypes, 1) ...
    };
D{3}(end) = 1;

% Each policy controls all three hidden factors by selecting the same task
% index across factors. In this task formulation, a policy corresponds to a
% complete hypothesis about:
%   - action sequence,
%   - target trajectory,
%   - temporal-order type.
V = zeros(nSteps - 1, nTasks, numel(nHiddens));
for taskIndex = 1:nTasks
    V(:, taskIndex, 1) = taskIndex;
    V(:, taskIndex, 2) = taskIndex;
    V(:, taskIndex, 3) = taskIndex;
end

% -------------------------------------------------------------------------
% 12. Build labels
% -------------------------------------------------------------------------
% The last nSteps target labels correspond to the auxiliary symbolic target
% (nDirs+1) unfolded across time. We relabel them as 0* to make their role
% as neutral/delay target states visually clearer.
for stepIndex = 1:nSteps
    targetLabels{end - nSteps + stepIndex}(1) = '0';
end

goToTargetLabels = cell(1, nGoToTargets);
allTargetNames = 'A':'Z';
allTargetNames = allTargetNames(1:pms.nDirs);

allNeutralNames = num2str((0:9)')';
allNeutralNames = allNeutralNames(1:(nGoToTargets - pms.nDirs));

allNames = [allTargetNames, allNeutralNames];
for targetIndex = 1:nGoToTargets
    goToTargetLabels{targetIndex} = ['GoTo' allNames(targetIndex)];
end

% -------------------------------------------------------------------------
% 13. Pack output
% -------------------------------------------------------------------------
sequenceModel = struct();
sequenceModel.A = A;
sequenceModel.B = B;
sequenceModel.D = D;
sequenceModel.V = V;

sequenceModel.familySpecs = familySpecs;
sequenceModel.goNeutralStates = goNeutralStates;
sequenceModel.goEndStates = goEndStates;
sequenceModel.typeIndexPerTask = typeIndexPerTask;
sequenceModel.tTasks = expandedTaskSequences;

sequenceModel.TaskLabels = taskLabels;
sequenceModel.effectiveTypeLabels = typeInfo.TypeLabels;
sequenceModel.TypeLabels = typeLabelsWithUnknown;
sequenceModel.GoToTargetLabels = goToTargetLabels;
sequenceModel.TargetLabels = targetLabels;

sequenceModel.Aname = {'GoToTarget', 'Target', 'Type'};
sequenceModel.Bname = {'GoToTarget', 'Target', 'Type'};
sequenceModel.sname = {goToTargetLabels, targetLabels, typeLabelsWithUnknown};
sequenceModel.oname = {goToTargetLabels, targetLabels, typeLabelsWithUnknown};

sequenceModel.description = sprintf('%s%g_nT%gnS%gsRg%gH%g', ...
    pms.namefor, pms.iTrial, nGoToTargets, nSteps, pms.irng, numel(nHiddens));

sequenceModel.forwardTypeIndex = typeInfo.forwardTypeIndex;
sequenceModel.backwardTypeIndex = typeInfo.backwardTypeIndex;

sequenceModel.nSteps = nSteps;
sequenceModel.nTasks = nTasks;
sequenceModel.nTypes = nTypes;
sequenceModel.nTargets = nTargets;
sequenceModel.nGoToTargets = nGoToTargets;

sequenceModel.nObs = nObs;
sequenceModel.nHiddens = nHiddens;
sequenceModel.nObsFactors = numel(nObs);
sequenceModel.nHiddenFactors = numel(nHiddens);
end

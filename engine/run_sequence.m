function MDP = run_sequence(sequenceModel, pms, varargin)
%RUN_SEQUENCE Run one Active Inference trial of the ABC/XIE sequence task.
%
% The generative model (A, B, D, V, labels) is pre-built in sequenceModel.
% This function only:
%   - selects the task (policy),
%   - builds trial-specific initial states and preferences,
%   - runs inference (VB_MDP_X),
%   - saves results.
%
% Reference point for the current generic sequence formulation:
% see https://www.biorxiv.org/content/10.1101/2025.11.26.690672v1
%
% HIDDEN FACTORS
%   1) GoToTarget : action / execution states (targets + neutral + end)
%   2) Target     : target identity unfolded over time (A1...F9, etc.)
%   3) Type       : temporal order (fw, bw, ..., idk)

pms = resolveFunctionParams(mfilename, pms, varargin{:});
fprintf('Entering %s\n', pms.executorName);

rng(pms.irng);

% -------------------------------------------------------------------------
% Select task
% -------------------------------------------------------------------------
taskIndex = pms.iTrial;

if taskIndex < 1 || taskIndex > sequenceModel.nTasks
    error('%s:InvalidTrialIndex', mfilename, ...
        'iTrial=%d is outside [1, %d]', ...
        taskIndex, sequenceModel.nTasks);
end

% -------------------------------------------------------------------------
% INITIAL STATE
% -------------------------------------------------------------------------
initialState = zeros(sequenceModel.nHiddenFactors, sequenceModel.nSteps);

% Factor 1: GoToTarget (neutral → ... → end)
initialState(1, 1:numel(sequenceModel.goNeutralStates)) = ...
    sequenceModel.goNeutralStates;
initialState(1, end) = sequenceModel.goEndStates(end);

% Factor 2: Target trajectory (expanded)
initialState(2, :) = sequenceModel.tTasks(taskIndex, :);

% Factor 3: Type (unknown → known)
initialState(3, :) = sequenceModel.nTypes;
initialState(3, numel(sequenceModel.goNeutralStates):end) = ...
    sequenceModel.typeIndexPerTask(taskIndex);

% -------------------------------------------------------------------------
% PREFERENCES (C)
% -------------------------------------------------------------------------
C = cell(1, sequenceModel.nObsFactors);

C{1} = ones(sequenceModel.nObs(1), sequenceModel.nSteps);
C{2} = ones(sequenceModel.nObs(2), sequenceModel.nSteps);

C{3} = zeros(sequenceModel.nObs(3), sequenceModel.nSteps);
C{3} = log(C{3} + eps);

if ~isempty(sequenceModel.forwardTypeIndex)
    C{3}(sequenceModel.forwardTypeIndex, :) = pms.typePreferenceValue;
end

if ~isempty(sequenceModel.backwardTypeIndex)
    C{3}(sequenceModel.backwardTypeIndex, :) = pms.typePreferenceValue;
end

% -------------------------------------------------------------------------
% POLICY PRIOR (E) – optional
% -------------------------------------------------------------------------
E = [];

if ~isempty(pms.policyFamilyWeights) || ~isempty(pms.policyTypeWeights)

    E = ones(sequenceModel.nTasks, 1);

    if ~isempty(pms.policyFamilyWeights)
        if numel(pms.policyFamilyWeights) ~= numel(sequenceModel.familySpecs)
            error('%s:InvalidPolicyFamilyWeights', mfilename, ...
                'policyFamilyWeights size mismatch');
        end

        for f = 1:numel(sequenceModel.familySpecs)
            idx = sequenceModel.familySpecs(f).taskIndices;
            E(idx) = E(idx) * (pms.policyFamilyWeights(f) / numel(idx));
        end
    end

    if ~isempty(pms.policyTypeWeights)
        nEffectiveTypes = numel(sequenceModel.effectiveTypeLabels);

        if numel(pms.policyTypeWeights) ~= nEffectiveTypes
            error('%s:InvalidPolicyTypeWeights', mfilename, ...
                'policyTypeWeights must contain one weight per enabled type: %s', ...
                strjoin(sequenceModel.effectiveTypeLabels, ', '));
        end

        for typeIndex = 1:nEffectiveTypes
            idx = sequenceModel.typeIndexPerTask == typeIndex;
            if any(idx)
                E(idx) = E(idx) * (pms.policyTypeWeights(typeIndex) / nnz(idx));
            end
        end
    end

    if any(E < 0)
        error('%s:NegativePolicyWeights', mfilename, ...
            'Policy prior weights must be non-negative.');
    end

    if ~any(E > 0)
        error('%s:ZeroPolicyWeights', mfilename, ...
            'At least one policy prior weight must be strictly positive.');
    end
end

% -------------------------------------------------------------------------
% BUILD MDP
% -------------------------------------------------------------------------
mdp.MDP.A = sequenceModel.A;
mdp.MDP.B = sequenceModel.B;
mdp.MDP.C = C;
mdp.MDP.D = sequenceModel.D;

if ~isempty(E)
    mdp.MDP.E = E;
end

mdp.MDP.V = sequenceModel.V;
mdp.MDP.T = sequenceModel.nSteps;
mdp.MDP.s = initialState;

mdp.MDP.sname = sequenceModel.sname;
mdp.MDP.oname = sequenceModel.oname;
mdp.MDP.Aname = sequenceModel.Aname;
mdp.MDP.Bname = sequenceModel.Bname;

mdp.MDP.Hname = 'Level 2';
mdp.MDP.level = 2;
mdp.MDP.beta  = 1;
mdp.MDP.eta   = 1;

mdp.MDP.PolLabels = sequenceModel.TaskLabels;

% -------------------------------------------------------------------------
% PARAMETERS
% -------------------------------------------------------------------------
langparams = HAI_initialiseParams(HAI_DefaultParams(pms.langContext));
langparams.debugmode = pms.debugmode;

% -------------------------------------------------------------------------
% DEBUG PRINT
% -------------------------------------------------------------------------
fprintf('Hidden: ');
for i = 1:sequenceModel.nHiddenFactors
    fprintf('%s ', sequenceModel.Bname{i});
end
fprintf('\n');

fprintf('Obs: ');
for i = 1:sequenceModel.nObsFactors
    fprintf('%s ', sequenceModel.Aname{i});
end
fprintf('\n');

fprintf('\n=== RUN %s ===\n', sequenceModel.TaskLabels{taskIndex});

% -------------------------------------------------------------------------
% RUN INFERENCE
% -------------------------------------------------------------------------
MDP{1}.mdp = VB_MDP_X(mdp.MDP, langparams);

% -------------------------------------------------------------------------
% TIME REPORT
% -------------------------------------------------------------------------
RT = sum(MDP{1}.mdp.rt);
sec = seconds(RT);
sec.Format = 'mm:ss';

fprintf('Elapsed Time %s\n', char(sec));

fprintf('VB_MDP_X -> %s\n', sequenceModel.TaskLabels{taskIndex});
MDP{1}.mdp.X{1}

% -------------------------------------------------------------------------
% SAVE
% -------------------------------------------------------------------------
if pms.saveOutput

    if ~isfolder(pms.saveDir)
        mkdir(pms.saveDir);
    end

    timestamp           = char(datetime('now', 'Format', 'yyyyMMddHHmmss'));
    trialDescription    = pms.trialDescription;

    filename = [pms.saveDir 'MDP_' pms.executorName '_' ...
        trialDescription '_' timestamp];

    fprintf('Saving %s\n', filename);
    save(filename, 'MDP', '-v7.3');
end

end

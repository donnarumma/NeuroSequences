function pms = run_sequenceParams(parSource)
%RUN_SEQUENCEPARAMS Defaults for run_sequence.

pms.iTrial              = 1;                    % Task index to execute within the model task list.
pms.irng                = 1;                    % Per-trial random seed for reproducibility.
pms.saveDir             = '~/TESTS/HAI_SEQUENCES/'; % Output directory for saved MDP files.
pms.mainProb            = [1, 1];              % Observation precision for GoToTarget and Target modalities.
pms.namefor             = 'Trial';             % Human-readable trial prefix used in saved file names.
pms.trialDescription    = 'SequenceTrial';     % Canonical descriptive label for one trial.
pms.executorName        = 'run_sequence';      % Short executor identifier embedded in file names.
pms.experimentLabel     = 'Sequence';          % External experiment label (for example Chen01).

pms.nDirs               = 6;                   % Number of available target directions.
pms.include3D           = true;                % Include 3-item sequence family.
pms.include2D           = false;               % Include 2-item sequence family.
pms.include1D           = false;               % Include 1-item sequence family.
pms.only2D              = false;               % If true, suppress 3D family even when include3D is true.
pms.minSeqLen           = 2;                   % Minimum symbolic sequence length used in the task.
pms.sequence2DMaxLen    = 3;                   % Trial timeline length template used by the 2D family.
pms.sequence1DMaxLen    = 3;                   % Trial timeline length template used by the 1D family.
pms.nStayStates         = [];                  % Number of distinct stay states; [] means one stay state per trial step.
pms.typeMask3D          = logical([1, 0, 0, 0, 0, 1]); % Active temporal-order templates among 3D permutations.

pms.transitionNoise     = 0;                   % Additive noise before normalising transition matrices.
pms.policyFamilyWeights = [];                  % Optional prior weights over enabled sequence families.
pms.policyTypeWeights   = [];                  % Optional prior weights over enabled temporal-order types, in selected-type order (for example [fw, bw] = [10, 1]).
pms.saveOutput          = true;                % Save the inferred MDP structure to disk.

pms.langContext         = 'DICTIONARY_ABC_t2_CONTEXT'; % Context used to initialise language/inference options.
pms.debugmode           = true;                % Verbosity/debug flag for the inference engine.
pms.typePreferenceValue = 2^4;                 % Preference strength applied to canonical type observations.

if nargin < 1 || isempty(parSource)
    return;
end

fieldNames = fieldnames(parSource);
for fieldIndex = 1:numel(fieldNames)
    pms.(fieldNames{fieldIndex}) = parSource.(fieldNames{fieldIndex});
end

function pms = run_sensorsParams(parSource)
%RUN_SENSORSPARAMS Defaults for run_sensors.

pms.iTrial              = 1;                        % Trial index to execute within the dictionary word list.
pms.irng                = 1;                        % Per-trial random seed for reproducibility.
pms.saveDir             = '~/TESTS/HAI_SEQUENCES/'; % Output directory for saved MDP files.
pms.saveOutput          = true;                     % Save the inferred MDP structure to disk.

pms.namefor             = 'Trial';                 % Human-readable trial prefix used in saved file names.
pms.trialDescription    = 'SensorTrial';           % Canonical descriptive label for one trial.
pms.executorName        = 'run_sensors';           % Short executor identifier embedded in file names.
pms.experimentLabel     = 'Chen01';                % External experiment label used by calling scripts.
pms.mainProb            = [0.8, 1.0];             % Legacy naming parameter kept for batch descriptions.

pms.dictionary          = 'DICTIONARY_ABCDEF_Neutral_2LEV'; % Dictionary used by the sensor task.
pms.trialRunner         = [];                      % Optional custom trial runner (function handle or function name). When set, it replaces the default ABCDEF sensor construction.
pms.isfix               = true;                    % If true, do not clamp the top-level sentence prior.
pms.nGoToTargets        = 6;                       % Number of sensory target/action categories.
pms.nSteps              = 5;                       % Number of task epochs in the level-2 sensor experiment.
pms.nHiddenFactors      = 3;                       % Legacy metadata used in saved trial descriptions.

pms.level1MaxT          = 1;                       % Number of updates at level 1.
pms.level2MaxT          = 5;                       % Number of updates at level 2.
pms.level2Jump          = false;                   % Whether level 2 can jump between states.
pms.maskval             = 1;                       % Rotational mask value at level 1.
pms.obsnoise            = 0;                       % Observation noise used by the sensory level.
pms.debugmode           = true;                    % Verbosity/debug flag for the inference engine.

if nargin < 1 || isempty(parSource)
    return;
end

fieldNames = fieldnames(parSource);
for fieldIndex = 1:numel(fieldNames)
    pms.(fieldNames{fieldIndex}) = parSource.(fieldNames{fieldIndex});
end
end

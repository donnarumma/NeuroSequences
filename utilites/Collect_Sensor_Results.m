function Collect_Sensor_Results(test_dir, description, namefor, nTasks, parSource)
%COLLECT_SENSOR_RESULTS Collect preprocessed sensor data_trials from saved MDP files.

if nargin < 5 || isempty(parSource)
    pms = default_collect_sensor_params();
else
    pms = default_collect_sensor_params(parSource);
end

if nargin < 4 || isempty(nTasks)
    nTasks = 120;
end

if nargin < 3 || isempty(namefor)
    namefor = 'Trial';
end

if nargin < 2 || isempty(description)
    description = '';
end

fprintf('Collecting sensor data in %s\n', test_dir);

if ~pms.forceRebuild
    existingResultPattern = [test_dir mfilename '_' description '_*'];
    existingResults = dir(existingResultPattern);
    if ~isempty(existingResults)
        [~, latestIndex] = max([existingResults.datenum]);
        existingResultFile = fullfile(existingResults(latestIndex).folder, ...
            existingResults(latestIndex).name);
        fprintf('Existing collected sensor results found: %s\n', existingResultFile);
        return;
    end
end

data_trials = struct([]);
for iTrial = 1:nTasks
    trialPattern = [test_dir '*' namefor num2str(iTrial) '_*'];
    trialFiles = dir(trialPattern);

    if isempty(trialFiles)
        error('%s:MissingTrialFile', mfilename, ...
            'No saved file found for trial %d in %s', iTrial, test_dir);
    end

    if numel(trialFiles) > 1
        [~, latestIndex] = max([trialFiles.datenum]);
        trialFiles = trialFiles(latestIndex);
    end

    trialFile = fullfile(trialFiles.folder, trialFiles.name);
    fprintf('Now Loading %s\n', trialFile);

    loaded = load(trialFile);
    builtTrials = build_collected_sensor_trials(loaded.MDP, iTrial, pms);

    for iBuiltTrial = 1:numel(builtTrials)
        if ~isfield(builtTrials(iBuiltTrial), 'sourceTrialIndex') || ...
                isempty(builtTrials(iBuiltTrial).sourceTrialIndex)
            builtTrials(iBuiltTrial).sourceTrialIndex = iTrial;
        end

        if isempty(data_trials)
            data_trials = builtTrials(iBuiltTrial);
        else
            data_trials(end + 1) = builtTrials(iBuiltTrial); %#ok<AGROW>
        end
    end
end

timestamp = char(datetime('now', 'Format', 'yyyyMMddHHmmss'));
saveFile = [test_dir mfilename '_' description '_' timestamp];
fprintf('Saving %s\n', saveFile);
save(saveFile, '-v7.3', 'data_trials');
end

function pms = default_collect_sensor_params(parSource)
% Default preprocessing settings used by the current sensor pipeline.

pms.dictionary = 'DICTIONARY_ABCDEF_Neutral_2LEV';
pms.buildTrialDataFcn = []; % Optional custom builder (function handle or function name) returning one or more data_trials entries from a saved MDP.
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
pms.forceRebuild = false; % If true, always rebuild collected data_trials from saved MDP files.

if nargin < 1 || isempty(parSource)
    return;
end

fieldNames = fieldnames(parSource);
for fieldIndex = 1:numel(fieldNames)
    pms.(fieldNames{fieldIndex}) = parSource.(fieldNames{fieldIndex});
end
end

function builtTrials = build_collected_sensor_trials(MDP, trialIndex, pms)
% Rebuild one or more data_trials entries from the saved per-trial MDP.

builder = pms.buildTrialDataFcn;
if isempty(builder)
    builtTrials = build_sensor_trial_data(MDP, trialIndex, pms);
    return;
end

if ischar(builder) || isstring(builder)
    builder = str2func(char(builder));
end

builtTrials = builder(MDP, trialIndex, pms);
if ~isstruct(builtTrials) || isempty(builtTrials)
    error('%s:InvalidCustomBuilder', mfilename, ...
        'Custom sensor trial builder must return a non-empty struct array.');
end
end

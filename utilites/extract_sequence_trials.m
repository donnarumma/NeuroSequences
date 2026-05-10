function [data_trials, testDir, collectedFile] = extract_sequence_trials(sourcePath, pms)
%EXTRACT_SEQUENCE_TRIALS Load and prepare data_trials for direct plotting utilities.

if nargin < 2 || isempty(pms)
    pms = extract_sequence_data_trialsParams();
else
    pms = extract_sequence_data_trialsParams(pms);
end

[testDir, collectedFile]    = resolve_sequence_source(sourcePath);
data_trials                 = load_sequence_trials(testDir, collectedFile);
if isempty(data_trials)
    error('%s:NoTrialsLoaded', mfilename, ...
        'No trial data could be loaded from %s.', sourcePath);
end

if ~isempty(pms.trialIndices)
    data_trials             = data_trials(pms.trialIndices);
end

data_trials                 = normalise_trial_names(data_trials, pms.trialNameTailLength);

if pms.usePreprocessedPopFR
    data_trials = extend_preprocessed_sequence_trials(data_trials, pms);
else
    %data_trials = extend_sequence_firing_rates(data_trials, pms);
    data_trials = build_sequence_one_hot_codes(data_trials, pms);
    data_trials = convert_sequence_firing_to_spikes(data_trials, pms);
end
end

function [testDir, collectedFile] = resolve_sequence_source(sourcePath)
% Resolve input into a directory plus an optional collected MAT file.

if isfolder(sourcePath)
    testDir = ensure_trailing_filesep(sourcePath);
    collectedFile = find_latest_collected_file(testDir);
    return;
end

if isfile(sourcePath)
    testDir = ensure_trailing_filesep(fileparts(sourcePath));
    collectedFile = sourcePath;
    return;
end

error('%s:InvalidSource', mfilename, ...
    'Input must be an existing directory or file: %s', sourcePath);
end

function collectedFile = find_latest_collected_file(testDir)
% Prefer collected data_trials files, then fallback to generic collect files.

patterns = {'Collect_Sensor_Results*.mat', 'Collect_SEQUENCES_RESULTS*.mat', ...
    'Collect_Trial_Results*.mat', 'Collect*.mat'};

for patternIndex = 1:numel(patterns)
    matches = dir(fullfile(testDir, patterns{patternIndex}));
    if ~isempty(matches)
        [~, latestIndex] = max([matches.datenum]);
        collectedFile = fullfile(matches(latestIndex).folder, matches(latestIndex).name);
        return;
    end
end

collectedFile = '';
end

function data_trials = load_sequence_trials(testDir, collectedFile)
% Load data_trials from a collected MAT file.

data_trials = struct([]);

if isempty(collectedFile)
    error('%s:MissingCollectFile', mfilename, ...
        'No Collect_* file found in %s.', testDir);
end

Res = load(collectedFile);
fprintf('Loading collected data in %s...\n', collectedFile);

if ~isfield(Res, 'data_trials')
    error('%s:InvalidCollectFile', mfilename, ...
        'Collect file %s does not contain data_trials.', collectedFile);
end

data_trials = Res.data_trials;
for iTrial = 1:numel(data_trials)
    data_trials(iTrial).sourceTrialIndex = iTrial;
end
end

function data_trials = normalise_trial_names(data_trials, tailLength)
% Trim trial names to the symbolic suffix used by downstream plots.

for iTrial = 1:numel(data_trials)
    trialName                       = data_trials(iTrial).trialName;
    keepCount                       = min(numel(trialName), tailLength);
    data_trials(iTrial).trialName   = trialName(end - keepCount + 1:end);
end
end

function data_trials = extend_preprocessed_sequence_trials(data_trials, pms)
% Extend already-processed population firing rates and generate spikes.

labEpochs = data_trials(1).labEpochs;
nBins = sum(labEpochs == 1);
Nev = pms.Nev;
if isempty(Nev)
    Nev = ones(1, pms.nLength);
end

for iTrial = 1:numel(data_trials)
    popFR = data_trials(iTrial).popFR;
    [FR, tFR, extLabEpochs]             = HAI_extendFiringRates(popFR, nBins, pms.Nnr, Nev, pms.dt);
    PopRates                            = HAI_extendFiringRates(popFR, nBins, 1, Nev, pms.dt);
    timePopRates                        = pms.nLength * tFR / tFR(end);
    data_trials(iTrial).PopRates        = PopRates;
    data_trials(iTrial).timePopRates    = timePopRates;
    data_trials(iTrial).firingRates     = FR;
    data_trials(iTrial).timeFiringRates = pms.nLength * tFR / tFR(end);
    data_trials(iTrial).extLabEpochs    = extLabEpochs;
    % Route preprpercSideocessed sensor/maze rasters through the configurable spike generator.
    % This also fixes the historical bug where the legacy code passed the time vector
    % instead of the fpopFRcosineiring rates into HAI_fireToSpikes.
    data_trials(iTrial).Spikes          = firingRatesToSpikes(FR, pms);
    data_trials(iTrial).timeSpikes      = data_trials(iTrial).timeFiringRates;
    data_trials(iTrial).popFRcosine     = FR;
end
end

function data_trials = extend_sequence_firing_rates(data_trials, pms)
% Extend firing rates and neuron populations.

labEpochs = data_trials(1).labEpochs;
nBins = sum(labEpochs == 1);
Nev = pms.Nev;
if isempty(Nev)
    Nev = ones(1, pms.nLength);
end

for iTrial = 1:numel(data_trials)
    FR                                  = data_trials(iTrial).popFR;
    [FR, tFR, extLabEpochs]             = HAI_extendFiringRates(FR, nBins, pms.Nnr, Nev, pms.dt);
    data_trials(iTrial).firingRates     = FR;
    data_trials(iTrial).timeFiringRates = pms.nLength * tFR / tFR(end);
    data_trials(iTrial).extLabEpochs    = extLabEpochs;
end
end

function data_trials = build_sequence_one_hot_codes(data_trials, pms)
% Build one-hot symbolic encodings for each trial.

tbasis = onehotencode(categorical(1:numel(pms.catNames))', 2);
nSteps = length(data_trials(1).trialName);

for iTrial = 1:numel(data_trials)
    ctbasis = [];
    for indLab = 1:nSteps
        tname                                           = data_trials(iTrial).trialName(indLab);
        ind                                             = find(ismember(pms.catNames, tname), 1);
        data_trials(iTrial).(['type' num2str(indLab)])  = tbasis(ind, :);
        ctbasis = [ctbasis, tbasis(ind, :)]; %#ok<AGROW>
    end
    data_trials(iTrial).type                            = ctbasis;
end
end

function data_trials = convert_sequence_firing_to_spikes(data_trials, pms)
% Convert extended firing rates into cosine-tuned spike trains.
labEpochs   = data_trials(1).labEpochs;
nBins       = sum(labEpochs == 1);
Nev         = pms.Nev;
if isempty(Nev)
    Nev     = ones(1, pms.nLength);
end
for iTrial = 1:numel(data_trials)
    labs = neuronLabels([pms.Nnr, pms.Nnr, pms.Nnr]);
    matches = false(size(labs{2})); 
    matches = matches | ~cellfun(@isempty, regexp(labs{2}, '\(1\)$'));
    matches = matches | ~cellfun(@isempty, regexp(labs{2}, '\(2\)$'));
    matches = matches | ~cellfun(@isempty, regexp(labs{2}, '\(3\)$'));

    labsPopFR = neuronLabels([1, 1, 1]);
    matchesPopFR = false(size(labsPopFR{2}));
    matchesPopFR = matchesPopFR | ~cellfun(@isempty, regexp(labsPopFR{2}, '\(1\)$'));
    matchesPopFR = matchesPopFR | ~cellfun(@isempty, regexp(labsPopFR{2}, '\(2\)$'));
    matchesPopFR = matchesPopFR | ~cellfun(@isempty, regexp(labsPopFR{2}, '\(3\)$'));

    % data_trials(iTrial).popFR = data_trials(iTrial).popFR(matchesPopFR, :);
    % data_trials(iTrial).firingRates = data_trials(iTrial).firingRates(matches, :);
    % data_trials(iTrial).neuronLabels = labs{2}(matches);
    % data_trials(iTrial).neuronLabelsFR = labsPopFR{2}(matchesPopFR);

    popFR                   = data_trials(iTrial).popFR(matchesPopFR,:);
    % add cosine tuning
    if ~isempty(pms.cosineTuning)
        [~, nTimes] = size(data_trials(iTrial).popFR);
        % popFR = nan(size(data_trials(iTrial).popFR));
        % percSide = (1 - pms.percCenter) / 2;
        for iTime = 1:nTimes
            %popFR(matchesPopFR, iTime) = pms.cosineTuning(popFR(matchesPopFR, iTime), ...
            popFR(:, iTime) = pms.cosineTuning( popFR(:, iTime), ...
                                                data_trials(iTrial).type,pms.cosinepms);
        end 
    end
    
    [firingRates, tFiringRates, extLabEpochs] = HAI_extendFiringRates(popFR, nBins, pms.Nnr, Nev, pms.dt);
    PopRates                                = HAI_extendFiringRates(popFR, nBins, 1, Nev, pms.dt);
    tFiringRates                            = pms.nLength * tFiringRates / tFiringRates(end);
    
    data_trials(iTrial).popFR               = popFR;
    data_trials(iTrial).PopRates            = PopRates;
    data_trials(iTrial).timePopRates        = tFiringRates;
    data_trials(iTrial).firingRates         = firingRates;
    data_trials(iTrial).timeFiringRates     = tFiringRates;
    % data_trials(iTrial).Spikes              = HAI_fireToSpikes(firingRates, pms.cap, pms.th, pms.SpT);
    data_trials(iTrial).Spikes              = firingRatesToSpikes(firingRates, pms);
    data_trials(iTrial).timeSpikes          = tFiringRates;
    data_trials(iTrial).timeSpikesCosine    = tFiringRates;

    %data_trials(iTrial).popFR               = data_trials(iTrial).popFR(matches, :);
    %data_trials(iTrial).firingRates         = data_trials(iTrial).firingRates(matches, :);
    data_trials(iTrial).neuronLabels        = labs{2}(matches);
    data_trials(iTrial).neuronLabelsFR      = labsPopFR{2}(matchesPopFR);
    data_trials(iTrial).extLabEpochs        = extLabEpochs; 

end
end

function pathOut = ensure_trailing_filesep(pathIn)
% Ensure directory paths end with a file separator.

if isempty(pathIn)
    pathOut = filesep;
elseif pathIn(end) == filesep
    pathOut = pathIn;
else
    pathOut = [pathIn filesep];
end
end

function Collect_Trial_Results(test_dir, description, namefor, nTasks)
%COLLECT_TRIAL_RESULTS Collect data_trials from saved MDP trial files.
%
% This collector reconstructs trial data via TEST_ABDEF_3LEV_fromMDP2Trials
% and saves only the resulting data_trials structure.

try
    namefor;
catch
    namefor = 'Trail';
end

try
    nTasks;
catch
    nTasks = 300;
end

try
    description;
catch
    description = '';
end

fprintf('Collecting data in %s\n', test_dir);

existingResultPattern = [test_dir mfilename '_' description '_*'];
existingResults = dir(existingResultPattern);

if ~isempty(existingResults)
    [~, latestIndex] = max([existingResults.datenum]);
    existingResultFile = fullfile(existingResults(latestIndex).folder, ...
        existingResults(latestIndex).name);
    fprintf('Existing collected results found: %s\n', existingResultFile);
    return;
end

firstTrialPattern = [test_dir '*' namefor '1_*'];
firstTrialSource = dir(firstTrialPattern);
if isempty(firstTrialSource)
    error('%s:MissingFirstTrial', mfilename, ...
        'No saved file found for the first trial in %s', test_dir);
end
if numel(firstTrialSource) > 1
    [~, latestIndex] = max([firstTrialSource.datenum]);
    firstTrialSource = firstTrialSource(latestIndex);
end

FMDP = load(fullfile(firstTrialSource.folder, firstTrialSource.name));
MDP = FMDP.MDP;

goToTargetsLabels = MDP{1}.mdp.oname{1};
for iGoToTarget = 1:numel(goToTargetsLabels)
    goToTargetsLabels{iGoToTarget} = goToTargetsLabels{iGoToTarget}(end);
end

nSteps = MDP{1}.mdp.T;
gglb = repmat(goToTargetsLabels, 1, nSteps);
goods = zeros(size(gglb));
allTarNames = 'A':'F';
for iDir = 1:numel(allTarNames)
    goods = goods + ismember(gglb, allTarNames(iDir));
end

pms = struct();
pms.iFactor = 1;
pms.Nnr = 8;
pms.dt = 1 / 64;
pms.cap = 0.8;
pms.th = 0.1;
pms.SpT = 1 / 16;
pms.goods = logical(goods);
pms.actions = goToTargetsLabels;
pms.reduce = false;

data_trials = struct([]);
for iTrial = 1:nTasks
    strf = [test_dir '*' namefor num2str(iTrial) '_*'];
    FMDPsource = dir(strf);

    if isempty(FMDPsource)
        error('%s:MissingTrialFile', mfilename, ...
            'No saved file found for trial %d in %s', iTrial, test_dir);
    end

    if numel(FMDPsource) > 1
        [~, latestIndex] = max([FMDPsource.datenum]);
        FMDPsource = FMDPsource(latestIndex);
    end

    fn = fullfile(FMDPsource.folder, FMDPsource.name);
    fprintf('Now Loading %s\n', fn);

    FMDP = load(fn);
    MDP = FMDP.MDP;
    builtTrial = TEST_ABDEF_3LEV_fromMDP2Trials(pms, MDP);
    builtTrial = builtTrial(1);
    builtTrial.sourceTrialIndex = iTrial;

    if isempty(data_trials)
        data_trials = builtTrial;
    else
        data_trials(end + 1) = builtTrial; %#ok<AGROW>
    end
end

timestamp = char(datetime('now', 'Format', 'yyyyMMddHHmmss'));
fn = [test_dir mfilename '_' description '_' timestamp];
fprintf('Saving %s\n', fn);
save(fn, '-v7.3', 'data_trials');
end

% function MAIN_Mushiake()
%MAIN_MUSHIAKE Run the Mushiake AY 2-level maze experiment with reusable pipelines.

rng(3);
nReps               = 1;
randsReps           = randi(2^9, nReps, 1);
saveRootDir         = '~/TESTS/HAI_SEQUENCES/Mushiake/';
saveRootDir         = '/TESTS/HAI_SEQUENCES/Mushiake/';

ifplot              = false;
saveFigures         = true;
saveMazeFigures     = saveFigures;
forceRebuildTrials  = true;
forceRecollectData  = true;
stayPlot            = false;
sampleTemporalOversampling = 4; % Increase internal raster bins while keeping the displayed time axis fixed.
% sampleTemporalOversampling = 1; % Legacy binning.

mushiakeReadoutPreset           = 'legacy_starting_spikes';

runPms                          = run_sensorsParams();
runPms.experimentLabel          = 'Mushiake';
runPms.executorName             = 'run_sensors';
runPms.dictionary               = 'DICTIONARY_AY_2LEV_Mushiake';
runPms.namefor                  = 'Trial';
runPms.debugmode                = false;
runPms.isfix                    = true;
runPms.trialRunner              = 'run_mushiake_trial';
runPms.goalStates               = [8, 4, 14, 18];
runPms.mazeIndices              = [1, 1, 1, 1];
runPms.sentenceId               = 0;
runPms.obsNoise                 = 0.1;
runPms.stateNoise               = 0.1;
runPms.nGoToTargets             = 5; % U D L R S
runPms.nSteps                   = 4;
runPms.nHiddenFactors           = 2;
runPms.actions                  = {'U', 'D', 'L', 'R', 'S'};
plotActions                     = resolve_mushiake_plot_actions(runPms.actions, stayPlot);
plotTargetLabel                 = strjoin(plotActions, '');
%rasterTargetActions             = resolve_mushiake_plot_actions(runPms.actions, false);
%rasterTargetLabel               = strjoin(rasterTargetActions, '');

nTasks                          = numel(runPms.goalStates);
iTasks                          = 1:nTasks;
description                     = 'Mushiake_SEQUENCES_UDLRS';
lastSaveDir                     = '';

collectPms                      = struct();
collectPms.buildTrialDataFcn    = 'build_mushiake_trial_data';
collectPms.iFactor              = 2;
collectPms.dt                   = 1 / 64;
collectPms.actions              = runPms.actions;
collectPms.trialReplications    = 1;
collectPms.forceRebuild         = forceRecollectData;
collectPms                      = mushiake_apply_readout_preset(collectPms, mushiakeReadoutPreset);

for rep = 1:nReps
    rng(randsReps(rep));
    
    saveDir = [fullfile(saveRootDir, description, sprintf('Rep%02d', rep)) filesep];
    fprintf('Executing %s, Rep %g, save dir: %s\n', mfilename, rep, saveDir);
    if ~isfolder(saveDir)
        mkdir(saveDir);
    end

    runPms.saveDir = saveDir;
    lastSaveDir = saveDir;
    saveDirs{rep} = saveDir; %#ok<AGROW>;
    randsTrials = get_or_create_trial_seeds(saveDir, nTasks);

    for iTrial = iTasks
        runPms.iTrial = iTrial;
        runPms.irng = randsTrials(iTrial);
        runPms.trialDescription = build_sensor_trial_description(runPms);

        existingTrialFile = find_existing_trial_file(saveDir, runPms, []);
        if ~forceRebuildTrials && ~isempty(existingTrialFile)
            fprintf('Reusing existing trial %g from %s\n', iTrial, existingTrialFile);
            continue;
        end

        run_sensors(runPms);
    end

    fprintf('Ended %s!\n', mfilename);
    Collect_Sensor_Results(saveDir, description, runPms.namefor, nTasks, collectPms);

    mazePms                 = struct();
    mazePms.ifplot          = ifplot;
    mazePms.saveFigures     = saveMazeFigures;
    mazePms.actions         = runPms.actions;
    mazePms.arrowScale      = 0.5;
    mazePms.arrowOffset     = 0.25;
    mazePms.arrowColor      = [0.6, 0.3, 0];
    mazePms.figurePrefix    = sprintf('Maze_Mushiake_%s', plotTargetLabel);
    mazePms.stayPlot        = stayPlot;
    hfgMaze = plot_mushiake_mazes(saveDir, iTasks, mazePms); % Plot the mazes and action paths for the completed trials.
end

%% Sample plots
lastSaveDir = saveDirs{1};
sampleDataPms = extract_sequence_data_trialsParams();
sampleDataPms.usePreprocessedPopFR = true;
sampleDataPms.trialNameTailLength = runPms.nSteps;
sampleDataPms.actions = runPms.actions;
sampleDataPms.iFactor = 2;
sampleDataPms.Nnr = 4;
sampleDataPms.dt = 1 / 64;
if collectPms.addFlatPrior
    sampleEpochLabels = {'Pre', 'M1', 'M2', 'M3', 'M4'};
    sampleDataPms.Nev = ones(1, runPms.nSteps + 1);
else
    sampleEpochLabels = {'M1', 'M2', 'M3', 'M4'};
    sampleDataPms.Nev = ones(1, runPms.nSteps);
end
sampleDataPms.Nev               = sampleTemporalOversampling * sampleDataPms.Nev;
sampleDataPms.cap               = 0.8;
sampleDataPms.th                = 0.1;
sampleDataPms.SpT               = 1 / 16;
sampleDataPms.nActions          = numel(runPms.actions);
sampleDataPms.nLength           = 1;
SpikeMode                       = 'thresholded_refractory'; % legacy
% SpikeMode                       = 'legacy'; % Legacy spike generator.
sampleDataPms.spikeGenerationMode = SpikeMode;
if strcmpi(sampleDataPms.spikeGenerationMode, 'thresholded_refractory')
    sampleDataPms.refractoryBins = sampleTemporalOversampling * sampleDataPms.refractoryBins;
    % sampleDataPms.refractoryBins = 2; % Legacy-scale refractory bins, independent of oversampling.
end
[data_trials, ~, ~]             = extract_sequence_data_trials(lastSaveDir, sampleDataPms);

sampleFRPms                     = plot_sequence_firing_rateParams();
sampleFRPms.ifplot              = ifplot;
sampleFRPms.experimentLabel     = runPms.experimentLabel;
sampleFRPms.figureTargetLabel   = plotTargetLabel;
sampleFRPms.figureFamilyLabel   = '';
sampleFRPms.figureDirectionLabel= '';
sampleFRPms.actions             = runPms.actions;
sampleFRPms.firingRatePlotter   = 'HAI_ABC_XIE_FiringRate_L1';
sampleFRPms.firingRateAppendEpochIndex = true;
sampleFRPms.firingRateKeepActions = plotActions;
sampleFRPms.firingRateKeepEpochIndices = 1:numel(sampleDataPms.Nev);
sampleFRPms.firingRateLegendNumColumns = numel(plotActions);
sampleFRPms.cmaps = lines(runPms.nSteps);
sampleFRPms.iFactor = 2;
sampleFRPms.Nnr = 4;
sampleFRPms.dt = 1 / 64;
sampleFRPms.Nev = 1;
sampleFRPms.cap = 0.8;
sampleFRPms.th = 0.1;
sampleFRPms.SpT = 1 / 16;
sampleFRPms.nActions = numel(runPms.actions);
sampleFRPms.nLength = 1;
sampleFRPms.scaleFiringRateTimeByEpochs = false;
sampleFRPms.firingRateTimeOffset = 0;
sampleFRPms.epochLabels     = cell(0,0);
sampleFRPms.epochFractions  = ones(1, numel(sampleFRPms.epochLabels)) / numel(sampleFRPms.epochLabels);
sampleFRPms.thresh          = eps;
sampleFRPms.smooth          = 15; % Preserve the raw xn trajectory in the plotted firing rates.
sampleFRPms.noise           = 0;
sampleFRPms.jitter          = 0;
sampleFRPms.offset          = 0.001;
sampleFRPms.asim            = false;
sampleFRPms.jitterAmplitude = 0;
sampleFRPms.nPoints         = 8;
sampleFRPms.firingRateFirstTimeOverride = [];
sampleFRPms.dstFiringRate   = [0.2, 0.05];
sampleFRPms.firingRateSectorTime = 0:0.01:1;
sampleFRPms.firingRateXLim = [0, 1.02];

sampleRasterPms = plot_sequence_rasterParams();
sampleRasterPms.ifplot = ifplot;
sampleRasterPms.experimentLabel = runPms.experimentLabel;
sampleRasterPms.figureTargetLabel = plotTargetLabel;
sampleRasterPms.figureFamilyLabel = '';
sampleRasterPms.figureDirectionLabel = '';
sampleRasterPms.actions = runPms.actions;
sampleRasterPms.iFactor = 2;
sampleRasterPms.Nnr = 4;
sampleRasterPms.nActions = numel(runPms.actions);
sampleRasterPms.rasterPlotter = 'HAI_Mushiake_SampleRaster';
sampleRasterPms.rasterApplyGenericPostprocessing = false;
sampleRasterPms.rasterKeepActions = resolve_mushiake_plot_actions(runPms.actions, true);
sampleRasterPms.rasterKeepEpochIndices = 1:(runPms.nSteps - 1);

%sampleRasterPms.rasterShowStayInTitle = fullS;
sampleRasterPms.dstRaster       = [0.15, 0.05];
sampleRasterPms.nEpochsRaster   = numel(sampleRasterPms.rasterKeepEpochIndices);
sampleRasterPms.rasterSectorTime= 0:0.01:1;
sampleRasterPms.rasterXLim      = [0, 1.02];
sampleRasterPms.epochLabels     = sampleEpochLabels(sampleRasterPms.rasterKeepEpochIndices);
sampleRasterPms.epochFractions  = ones(1, numel(sampleRasterPms.epochLabels)) / numel(sampleRasterPms.epochLabels);
sampleRasterPms.reset           = -1;  % Shift epoch indices by one to align with the original Mushiake plots, which show the first update during the first movement epoch. 
sampleIndices = resolve_mushiake_sample_indices(data_trials, [1, 2, 3, 4]);
for iSample = 1:numel(sampleIndices)
    sampleIndex = sampleIndices(iSample);
    sampleTrialNumber = data_trials(sampleIndex).sourceTrialIndex;
    [sampleMDP, mdpFile] = load_sequence_trial_mdp(lastSaveDir, sampleTrialNumber);
    fprintf('Using sample MDP %s\n', mdpFile);

    sampleFRPms.sampleTrial = sampleIndex;
    sampleRasterPms.sampleTrial = sampleIndex;

    hfgSample = struct();
    [hfgSample, oldFRName] = plot_sequence_firing_rate(hfgSample, data_trials, sampleMDP, sampleIndex, sampleFRPms);
    [hfgSample, oldRasterName] = plot_sequence_raster(hfgSample, data_trials, sampleMDP, sampleIndex, sampleRasterPms);
    %set_visible_axes_title(hfgSample.(oldRasterName), ...
    %    resolve_mushiake_sample_title(sampleMDP, data_trials(sampleIndex), runPms.actions, fullS));

    sampleFRFigureTag = sprintf('%s_%s_Trial%d', ...
        sampleFRPms.experimentLabel, sampleFRPms.figureTargetLabel, sampleTrialNumber);
    sampleRasterFigureTag = sprintf('%s_%s_Trial%d', ...
        sampleRasterPms.experimentLabel, sampleRasterPms.figureTargetLabel, sampleTrialNumber);
    hfgSample.(['FiringRate_' sampleFRFigureTag]) = hfgSample.(oldFRName);
    hfgSample = rmfield(hfgSample, oldFRName);
    hfgSample.(['Raster_' sampleRasterFigureTag]) = hfgSample.(oldRasterName);
    hfgSample = rmfield(hfgSample, oldRasterName);
    if saveFigures
        save_sequence_figures(hfgSample, ...
            sprintf('SUMMARY_%s_%s', sampleFRPms.experimentLabel, ...
            sampleFRPms.figureTargetLabel), ...
            lastSaveDir);
    end
end
return
%% PCA analysis
BETApms = BETA_pcaParams();
BETApms.ifplot = ifplot;
BETApms.saveFigures = saveFigures;
BETApms.usePreprocessedPopFR = true;
BETApms.experimentLabel = runPms.experimentLabel;
BETApms.figureTargetLabel = plotTargetLabel;
BETApms.figureFamilyLabel = 'Mushiake';
BETApms.figureDirectionLabel = 'Main';
BETApms.trialIndices = 1:numel(data_trials);
BETApms.trialNameTailLength = runPms.nSteps;
BETApms.typeStepCount = 3;
BETApms.catNames = {'U', 'D', 'L', 'R'};
BETApms.iFactor = 2;
BETApms.Nnr = 8;
BETApms.dt = 1 / 64;
BETApms.Nev = sampleDataPms.Nev;
BETApms.cap = 0.8;
BETApms.th = 0.1;
BETApms.SpT = 1 / 16;
BETApms.nActions = numel(runPms.actions);
BETApms.nLength = 1;
BETApms.hm = 3;
BETApms.signalName = 'Spikes';
BETApms.Wlength = [];
BETApms.overlap = 1;
BETApms.plotPcaPolygons = true;
BETApms.plotPcaTrajectories = false;
BETApms.plotPcaTime = false;
BETApms.plotPcaExplainedVariance = true;
BETApms.plotPcaManifoldAngles = false;
BETApms.plotPopulationResponses = true;
[hfgBeta, betaResults] = BETA_pca(lastSaveDir, BETApms); %#ok<NASGU,ASGLU>

function hfg = plot_mushiake_mazes(testDir, trials, parSource)
% Plot the maze and inferred action path for the requested saved trials.

par = default_mushiake_maze_params(parSource);
hfg = struct();

for iTrial = trials
    [MDP, mdpFile] = load_mushiake_trial_mdp(testDir, iTrial);
    fprintf('Using maze MDP %s\n', mdpFile);

    mushiakeMDP = MDP{1};
    MDP_Low = mushiakeMDP.mdp;
    testMaze = MAZE_Mushiake(mushiakeMDP.iMushiake);

    start_state = MDP_Low.s(1, 1);
    [~, goal_state] = max(MDP_Low.C{1}(:, 1));
    [start_2d(2), start_2d(1)] = find(testMaze.map2D == start_state, 1);
    [goal_2d(2), goal_2d(1)] = find(testMaze.map2D == goal_state, 1);

    plotPms = plot_MAZEParams(testMaze);
    plotPms.exec = false;
    plotPms.fs = 30;
    plotPms.bordercol = [0, 0, 0];
    plotPms.labelsmode = 1;
    plotPms.hfig = figure('Visible', par.ifplot);
    plotPms.start2d = start_2d;
    plotPms.goal2d = goal_2d;

    figName = sprintf('%s_Trial%d', par.figurePrefix, iTrial);
    hfg.(figName) = plot_MAZE(testMaze.MAZE, plotPms);
    hold on;
    title(resolve_mushiake_maze_title(MDP_Low, par), 'FontSize', 28);

    actionSeq = MDP_Low.s(2, 2:end);
    currentPos = [start_2d(1), start_2d(2)];
    for iAction = actionSeq
        switch iAction
            case 1
                dirVec = [-1, 0];
            case 2
                dirVec = [1, 0];
            case 3
                dirVec = [0, -1];
            case 4
                dirVec = [0, 1];
            otherwise
                dirVec = [0, 0];
        end

        if any(dirVec ~= 0)
            arrowStart = currentPos + par.arrowOffset * dirVec;
            arrowEnd = arrowStart + par.arrowScale * dirVec;
            quiver(arrowStart(2), arrowStart(1), ...
                arrowEnd(2) - arrowStart(2), ...
                arrowEnd(1) - arrowStart(1), 0, ...
                'LineWidth', 5, ...
                'Color', par.arrowColor, ...
                'MaxHeadSize', 7);
        end

        currentPos = currentPos + dirVec;
    end

    ax = gca;
    ax.XAxis.FontSize = 30;
    ax.YAxis.FontSize = 30;

end
end

function par = default_mushiake_maze_params(parSource)
% Default parameters for the Mushiake-specific maze summary plot.

par.ifplot          = false;
par.saveFigures     = true;
par.actions         = {'U', 'D', 'L', 'R', 'S'};
par.arrowScale      = 0.5;
par.arrowOffset     = 0.25;
par.arrowColor      = [0.6, 0.3, 0];
par.figurePrefix    = 'Maze_Mushiake';
par.stayPlot        = true;

if nargin < 1 || isempty(parSource)
    return;
end

fieldNames = fieldnames(parSource);
for fieldIndex = 1:numel(fieldNames)
    par.(fieldNames{fieldIndex}) = parSource.(fieldNames{fieldIndex});
end
end

function actionsOut = resolve_mushiake_plot_actions(actionsIn, stayPlot)
% Select whether the stay state is included in displayed action labels.

actionsOut = actionsIn;
if ~stayPlot
    actionsOut = actionsOut(~strcmp(actionsOut, 'S'));
end
end

function titleText = resolve_mushiake_maze_title(MDP_Low, par)
% Build the maze-title string with optional stay suppression.

policyActions = par.actions(MDP_Low.s(2, 2:end));
if ~par.stayPlot
    policyActions = policyActions(~strcmp(policyActions, 'S'));
end
titleText = ['Policy ' strjoin(policyActions, '')];
end

function titleText = resolve_mushiake_sample_title(MDP, data_trial, actions, stayPlot)
% Build a sample title from the MDP, falling back to the collected trial data.

titleText = build_sequence_policy_title(MDP, data_trial);

if iscell(MDP)
    root = MDP{1};
else
    root = MDP;
end

if isfield(root, 'mdp') && ~isempty(root.mdp) && isfield(root.mdp(1), 's')
    policyActions = actions(root.mdp(1).s(2, 2:end));
    if ~stayPlot
        policyActions = policyActions(~strcmp(policyActions, 'S'));
    end
    titleText = strjoin(policyActions, '');
end
end

function [MDP, mdpFile] = load_mushiake_trial_mdp(testDir, trialNumber)
% Load the newest saved MDP matching one Mushiake trial number.

matches = dir(fullfile(testDir, ['MDP_*Trial' num2str(trialNumber) '_*.mat']));
if isempty(matches)
    error('%s:MissingTrialMDP', mfilename, ...
        'No MDP file found for trial %d in %s.', trialNumber, testDir);
end

[~, latestIndex] = max([matches.datenum]);
mdpFile = fullfile(matches(latestIndex).folder, matches(latestIndex).name);
loaded = load(mdpFile, 'MDP');
MDP = loaded.MDP;
end

function collectedData = load_latest_mushiake_collect(testDir)
% Load the newest collected Mushiake data_trials file from one batch folder.

matches = dir(fullfile(testDir, 'Collect_Sensor_Results*.mat'));
if isempty(matches)
    error('%s:MissingCollectFile', mfilename, ...
        'No Collect_Sensor_Results file found in %s.', testDir);
end

[~, latestIndex] = max([matches.datenum]);
collectedFile = fullfile(matches(latestIndex).folder, matches(latestIndex).name);
collectedData = load(collectedFile, 'data_trials');
end

function sampleIndices = resolve_mushiake_sample_indices(data_trials, sourceTrials)
% Map requested source trial ids to the first matching collected entries.

sampleIndices = [];
sourceTrialIndex = [data_trials.sourceTrialIndex];

for iSourceTrial = 1:numel(sourceTrials)
    sampleIndex = find(sourceTrialIndex == sourceTrials(iSourceTrial), 1, 'first');
    if isempty(sampleIndex)
        continue;
    end
    sampleIndices(end + 1) = sampleIndex; %#ok<AGROW>
end

if isempty(sampleIndices)
    error('%s:MissingSampleTrial', mfilename, ...
        'None of the requested Mushiake sample trials are present in the collected results.');
end
end

function catNames = resolve_mushiake_beta_categories(data_trials, stepIndex)
% Derive the available symbolic labels at one position from collected trials.

symbols = '';
for iTrial = 1:numel(data_trials)
    if numel(data_trials(iTrial).trialName) < stepIndex
        continue;
    end
    symbol = data_trials(iTrial).trialName(stepIndex);
    if any(symbols == symbol)
        continue;
    end
    symbols(end + 1) = symbol; %#ok<AGROW>
end

if isempty(symbols)
    error('%s:MissingBetaCategories', mfilename, ...
        'No symbolic categories could be inferred for Mushiake step %d.', stepIndex);
end

catNames = cellstr(symbols(:))';
end

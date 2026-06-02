% function MAIN_Mushiake_Exp_Supp()
%MAIN_MUSHIAKE_EXP_SUPP Run the Mushiake AY 2-level maze experiment with reusable pipelines.

print_main_dependency_disclaimer(mfilename, {'HAI_LANGUAGE', 'TrialBox', 'SPM'});

rng(3); % For reproducibility of the trial seeds, which are saved and reused independently of the main RNG state.
nReps               = 1;
randsReps           = randi(2^9, nReps, 1);
saveRootDir         = '~/TESTS/HAI_SEQUENCES/Mushiake/';
saveRootDir         = '/TESTS/HAI_SEQUENCES/Mushiake/Supp/';

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
runPms.obsNoise                 = 0;0.1;
runPms.stateNoise               = 0;0.1;
runPms.nGoToTargets             = 5; % U D L R S
runPms.nSteps                   = 4;
runPms.nHiddenFactors           = 2;
runPms.actions                  = {'U', 'D', 'L', 'R', 'S'};
plotActions                     = resolve_mushiake_plot_actions(runPms.actions, stayPlot);
plotTargetLabel                 = strjoin(plotActions, '');
%rasterTargetActions             = resolve_mushiake_plot_actions(runPms.actions, false);
%rasterTargetLabel               = strjoin(rasterTargetActions, '');
factorIndeces                   = [1, 2];
fact_actions{1}                 = mushiake_state_labels_2lev();
fact_actions{2}                 = {'U', 'D', 'L', 'R', 'S'};

nTasks                          = numel(runPms.goalStates);
iTasks                          = 1:nTasks;
description                     = 'Mushiake_SEQUENCES_UDLRS';
lastSaveDir                     = '';
MDP                             = cell(nReps, nTasks);
collectPms                      = struct();
collectPms.buildTrialDataFcn    = 'build_mushiake_trial_data';
collectPms.iFactor              = factorIndeces(1);
collectPms.dt                   = 1 / 64;
collectPms.actions              = runPms.actions;
collectPms.trialReplications    = 1;
collectPms.forceRebuild         = forceRecollectData;
collectPms.useSingleStepRecognitionLevel = true;
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

        MDP{rep,iTrial} = run_sensors(runPms);
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
lastSaveDir                 = saveDirs{1};
levelConfigs                = resolve_mushiake_sample_level_configs();
for iFactor = factorIndeces
    for iLevel = 1:numel(levelConfigs)
        levelConfig = levelConfigs(iLevel);
        sampleDataPms                       = extract_sequence_data_trialsParams();
        sampleDataPms.usePreprocessedPopFR  = true;
        sampleDataPms.trialNameTailLength   = runPms.nSteps;
        sampleDataPms.actions               = fact_actions{iFactor};
        sampleDataPms.iFactor               = iFactor;
        sampleDataPms.Nnr                   = 4;
        sampleDataPms.dt                    = 1 / 64;
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
        sampleDataPms.nActions          = numel(sampleDataPms.actions);
        sampleDataPms.nLength           = 1;
        SpikeMode                       = 'thresholded_refractory'; % legacy
        sampleDataPms.spikeGenerationMode = SpikeMode;
        if strcmpi(sampleDataPms.spikeGenerationMode, 'thresholded_refractory')
            sampleDataPms.refractoryBins = sampleTemporalOversampling * sampleDataPms.refractoryBins;
        end

        levelCollectPms = collectPms;
        levelCollectPms.iFactor = iFactor;
        levelCollectPms.dt = sampleDataPms.dt;
        levelCollectPms.actions = runPms.actions;
        levelCollectPms.trialReplications = 1;
        levelCollectPms.useSingleStepRecognitionLevel = levelConfig.useSingleStepRecognitionLevel;
        if iFactor == 2 && levelConfig.useSingleStepRecognitionLevel
            levelCollectPms.flatPriorLevel = 0.01;
        end
        data_trials = build_mushiake_plot_trials(lastSaveDir, iTasks, levelCollectPms, sampleDataPms);

        figureLevelLabel = sprintf('F%d_%s', iFactor, levelConfig.figureTag);

        sampleFRPms                     = plot_sequence_firing_rateParams();
        sampleFRPms.ifplot              = ifplot;
        sampleFRPms.experimentLabel     = runPms.experimentLabel;
        sampleFRPms.figureTargetLabel   = [plotTargetLabel '_' figureLevelLabel];
        sampleFRPms.figureFamilyLabel   = '';
        sampleFRPms.figureDirectionLabel= '';
        sampleFRPms.actions             = fact_actions{iFactor};
        sampleFRPms.firingRatePlotter   = 'HAI_ABC_XIE_FiringRate_L1';
        sampleFRPms.firingRateAppendEpochIndex = true;
        sampleFRPms.firingRateKeepActions = resolve_mushiake_keep_actions(iFactor, fact_actions{iFactor}, plotActions);
        sampleFRPms.firingRateKeepEpochIndices = resolve_mushiake_firing_rate_keep_epochs(iFactor, collectPms.addFlatPrior, runPms.nSteps, numel(sampleDataPms.Nev));
        sampleFRPms.firingRateLegendNumColumns = numel(plotActions);
        sampleFRPms.firingRateLegendUnique = false;
        sampleFRPms.firingRateLegendFontSize = ternary_numeric(iFactor == 1, 9, 14);
        sampleFRPms.cmaps = resolve_mushiake_firing_rate_cmaps(iFactor, runPms.nSteps, collectPms.addFlatPrior);
        sampleFRPms.iFactor = iFactor;
        sampleFRPms.Nnr = 4;
        sampleFRPms.dt = 1 / 64;
        sampleFRPms.Nev = 1;
        sampleFRPms.cap = 0.8;
        sampleFRPms.th = 0.1;
        sampleFRPms.SpT = 1 / 16;
        sampleFRPms.nActions        = numel(sampleFRPms.actions);
        sampleFRPms.nLength = 1;
        sampleFRPms.scaleFiringRateTimeByEpochs = false;
        sampleFRPms.firingRateTimeOffset = 0;
        sampleFRPms.epochLabels     = cell(0,0);
        sampleFRPms.epochFractions  = ones(1, numel(sampleFRPms.epochLabels)) / numel(sampleFRPms.epochLabels);
        sampleFRPms.thresh          = 0.4;
        sampleFRPms.smooth          = 20;
        sampleFRPms.noise           = 0;
        sampleFRPms.jitter          = 0.01;
        sampleFRPms.offset          = 0.002;
        sampleFRPms.asim            = false;
        sampleFRPms.jitterAmplitude = 0;
        sampleFRPms.nPoints         = 7;
        sampleFRPms.firingRateFirstTimeOverride = [];
        sampleFRPms.dstFiringRate   = [0.2, 0.05];
        sampleFRPms.firingRateSectorTime = 0:0.01:1;
        sampleFRPms.firingRateXLim = [-0.02, 1.02];
        if iFactor == 2 && ~levelConfig.useSingleStepRecognitionLevel && collectPms.addFlatPrior
            sampleFRPms.firingRateKeepEpochIndices = 0:(runPms.nSteps - 1);
            sampleFRPms.cmaps = resolve_mushiake_zero_indexed_epoch_cmaps(runPms.nSteps);
        end
        if iFactor == 2 && levelConfig.useSingleStepRecognitionLevel
            sampleFRPms.firingRateAppendEpochIndex = false;
            sampleFRPms.firingRateKeepActions = resolve_mushiake_plot_actions(runPms.actions, false);
            sampleFRPms.firingRateKeepEpochIndices = [];
            sampleFRPms.firingRateColorMode = 'action';
            sampleFRPms.cmaps = lines(numel(sampleFRPms.actions));
            sampleFRPms.firingRateUseBrightnessScaling = false;
            sampleFRPms.smooth = 6;
        end
        if iFactor == 1 && ~levelConfig.useSingleStepRecognitionLevel
            sampleFRPms.offset = 0.0003;
            if collectPms.addFlatPrior
                sampleFRPms.firingRateKeepTimeMax = runPms.nSteps / (runPms.nSteps + 1);
            else
                sampleFRPms.firingRateKeepTimeMax = (runPms.nSteps - 1) / runPms.nSteps;
            end
            sampleFRPms.firingRateNormalizeTimeAfterCrop = true;
        end
        if iFactor == 1 && levelConfig.useSingleStepRecognitionLevel
            sampleFRPms.smooth = 6;
            sampleFRPms.firingRateColorMode = 'action';
            sampleFRPms.firingRateUseBrightnessScaling = false;
            sampleFRPms.cmaps = lines(numel(sampleFRPms.actions));
            if collectPms.addFlatPrior
                sampleFRPms.firingRateKeepTimeMax = runPms.nSteps / (runPms.nSteps + 1);
            else
                sampleFRPms.firingRateKeepTimeMax = (runPms.nSteps - 1) / runPms.nSteps;
            end
            sampleFRPms.firingRateNormalizeTimeAfterCrop = true;
        end

        sampleRasterPms = plot_sequence_rasterParams();
        sampleRasterPms.ifplot = ifplot;
        sampleRasterPms.experimentLabel = runPms.experimentLabel;
        sampleRasterPms.figureTargetLabel = [plotTargetLabel '_' figureLevelLabel];
        sampleRasterPms.figureFamilyLabel = '';
        sampleRasterPms.figureDirectionLabel = '';
        sampleRasterPms.actions = fact_actions{iFactor};
        sampleRasterPms.iFactor = iFactor;
        sampleRasterPms.Nnr = 4;
        sampleRasterPms.nActions = numel(sampleRasterPms.actions);
        sampleRasterPms.rasterPlotter = 'HAI_Mushiake_SampleRaster';
        sampleRasterPms.rasterApplyGenericPostprocessing = false;
        sampleRasterPms.rasterKeepActions = resolve_mushiake_keep_actions(iFactor, sampleRasterPms.actions, sampleRasterPms.actions);
        if collectPms.addFlatPrior
            sampleRasterPms.rasterKeepEpochIndices = 0:runPms.nSteps;
            sampleRasterPms.epochLabels = sampleEpochLabels;
            sampleRasterPms.reset = -1;
        else
            sampleRasterPms.rasterKeepEpochIndices = 1:runPms.nSteps;
            sampleRasterPms.epochLabels = sampleEpochLabels;
            sampleRasterPms.reset = 0;
        end
        sampleRasterPms.rasterAppendEpochIndex = true;
        sampleRasterPms.rasterUseOrdinalEpochLabels = iFactor == 1;
        sampleRasterPms.rasterStartEpochIndex = ternary_numeric(iFactor == 1, 0, 1);
        sampleRasterPms.rasterZeroIndexedStepColors = iFactor == 1 || ...
            (iFactor == 2 && ~levelConfig.useSingleStepRecognitionLevel && collectPms.addFlatPrior);
        sampleRasterPms.rasterYTickFontSize = ternary_numeric(iFactor == 1, 9, 16);
        sampleRasterPms.rasterFigurePosition = ternary_position(iFactor == 1, [0, 0, 1100, 1800], []);
        sampleRasterPms.rasterVisibleEpochCount = ternary_numeric(iFactor == 1, 4, []);
        sampleRasterPms.policyActions = runPms.actions;
        sampleRasterPms.dstRaster       = [0.15, 0.05];
        sampleRasterPms.nEpochsRaster   = numel(sampleRasterPms.rasterKeepEpochIndices);
        sampleRasterPms.rasterSectorTime= 0:0.01:1;
        sampleRasterPms.rasterXLim      = [0, 1.02];
        sampleRasterPms.epochFractions  = ones(1, numel(sampleRasterPms.epochLabels)) / numel(sampleRasterPms.epochLabels);
        sampleRasterPms.rasterOmitZeroEpochSuffix = false;
        if iFactor == 1 && levelConfig.useSingleStepRecognitionLevel
            sampleRasterPms.rasterOmitZeroEpochSuffix = true;
            sampleRasterPms.rasterColorMode = 'action';
            sampleRasterPms.rasterCmaps = lines(numel(sampleRasterPms.actions));
        end
        if iFactor == 2 && levelConfig.useSingleStepRecognitionLevel
            sampleRasterPms.rasterAppendEpochIndex = false;
            sampleRasterPms.rasterKeepActions = runPms.actions;
            sampleRasterPms.rasterVisibleEpochCount = 4;
            sampleRasterPms.rasterVisibleEpochStart = 1;
            sampleRasterPms.rasterMuteActions = {'S'};
            sampleRasterPms.rasterMuteEpochIndices = ternary_numeric(collectPms.addFlatPrior, 2, 1);
            sampleRasterPms.rasterColorMode = 'action';
            sampleRasterPms.rasterCmaps = lines(numel(sampleRasterPms.actions));
        end
        if iFactor == 2 && ~levelConfig.useSingleStepRecognitionLevel
            sampleRasterPms.rasterVisibleEpochCount = 3;
            sampleRasterPms.rasterVisibleEpochStart = 2;
        end

        sampleIndices                   = resolve_mushiake_sample_indices(data_trials, [1, 2, 3, 4]);
        hfgLevelFigures                 = hfgMaze;

        for iSample = 1:numel(sampleIndices)
            sampleIndex = sampleIndices(iSample);
            sampleTrialNumber = data_trials(sampleIndex).sourceTrialIndex;
            [sampleMDP, mdpFile] = load_sequence_trial_mdp(lastSaveDir, sampleTrialNumber);
            fprintf('Using sample MDP %s for %s\n', mdpFile, levelConfig.displayLabel);
            sampleFRPms.sampleTrial     = sampleIndex;
            sampleRasterPms.sampleTrial = sampleIndex;
            if iFactor == 1
                stateTitle = resolve_mushiake_state_sequence_title( ...
                    sampleMDP, ...
                    sampleRasterPms.rasterVisibleEpochCount, ...
                    sampleRasterPms.rasterStartEpochIndex);
                sampleFRPms.firingRateTitle = ['Firing Rate: ' stateTitle];
                sampleFRPms.firingRateTitleInterpreter = 'tex';
                sampleRasterPms.rasterTitle = ['Unit firing: ' stateTitle];
                sampleRasterPms.rasterTitleInterpreter = 'tex';
            else
                sampleFRPms.firingRateTitle = '';
                sampleFRPms.firingRateTitleInterpreter = '';
                sampleRasterPms.rasterTitle = '';
                sampleRasterPms.rasterTitleInterpreter = '';
            end

            hfgSample = struct();
            [hfgSample, oldFRName] = plot_sequence_firing_rate(hfgSample, data_trials, sampleMDP, sampleIndex, sampleFRPms);
            [hfgSample, oldRasterName] = plot_sequence_raster(hfgSample, data_trials, sampleMDP, sampleIndex, sampleRasterPms);
            if iFactor == 1
                set_visible_axes_title(hfgSample.(oldFRName), sampleFRPms.firingRateTitle, sampleFRPms.firingRateTitleInterpreter);
                set_visible_axes_title(hfgSample.(oldRasterName), sampleRasterPms.rasterTitle, sampleRasterPms.rasterTitleInterpreter);
            end

            sampleFRFigureTag = sprintf('%s_%s_Trial%d', ...
                sampleFRPms.experimentLabel, sampleFRPms.figureTargetLabel, sampleTrialNumber);
            sampleRasterFigureTag = sprintf('%s_%s_Trial%d', ...
                sampleRasterPms.experimentLabel, sampleRasterPms.figureTargetLabel, sampleTrialNumber);
            hfgSample.(['FiringRate_' sampleFRFigureTag]) = hfgSample.(oldFRName);
            hfgSample = rmfield(hfgSample, oldFRName);
            hfgSample.(['Raster_' sampleRasterFigureTag]) = hfgSample.(oldRasterName);
            hfgSample = rmfield(hfgSample, oldRasterName);
            hfgLevelFigures = merge_struct_fields(hfgLevelFigures, hfgSample);
        end

        if saveFigures
            save_sequence_figures(hfgLevelFigures, ...
                sprintf('SUMMARY_%s_%s', sampleFRPms.experimentLabel, sampleFRPms.figureTargetLabel), ...
                lastSaveDir);
        end
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

function actionsOut = resolve_mushiake_keep_actions(iFactor, factorActions, fallbackActions)
% Keep all factor-1 state labels, but preserve compact action filtering for factor 2.

if iFactor == 1
    actionsOut = factorActions;
    return;
end

actionsOut = fallbackActions;
end

function labels = mushiake_state_labels_2lev()
% Return the accessible 2D maze states in row-major order, excluding blocked corners.

labels = { ...
    'S_{12}', 'S_{13}', 'S_{14}', ...
    'S_{21}', 'S_{22}', 'S_{23}', 'S_{24}', 'S_{25}', ...
    'S_{31}', 'S_{32}', 'S_{33}', 'S_{34}', 'S_{35}', ...
    'S_{41}', 'S_{42}', 'S_{43}', 'S_{44}', 'S_{45}', ...
    'S_{52}', 'S_{53}', 'S_{54}'};
end

function labels = mushiake_state_labels_2lev_plain()
% Plain-text companion labels used in titles.

labels = { ...
    'S_12', 'S_13', 'S_14', ...
    'S_21', 'S_22', 'S_23', 'S_24', 'S_25', ...
    'S_31', 'S_32', 'S_33', 'S_34', 'S_35', ...
    'S_41', 'S_42', 'S_43', 'S_44', 'S_45', ...
    'S_52', 'S_53', 'S_54'};
end

function titleText = resolve_mushiake_state_sequence_title(MDP, visibleEpochCount, startEpochIndex)
% Build the factor-1 state-sequence title shown on firing-rate and raster panels.

if nargin < 2 || isempty(visibleEpochCount)
    visibleEpochCount = 4;
end
if nargin < 3 || isempty(startEpochIndex)
    startEpochIndex = 0;
end

if iscell(MDP)
    root = MDP{1};
else
    root = MDP;
end

labels = mushiake_state_labels_2lev();
stateSequence = root.mdp(1).s(1, :);
nVisible = min(visibleEpochCount, numel(stateSequence));
chunks = cell(1, nVisible);

for iState = 1:nVisible
    stateIndex = stateSequence(iState);
    if stateIndex >= 1 && stateIndex <= numel(labels)
        stateLabel = labels{stateIndex};
    else
        stateLabel = sprintf('S_{%d}', stateIndex);
    end
    chunks{iState} = sprintf('%s(%d)', stateLabel, startEpochIndex + iState - 1);
end

titleText = strjoin(chunks, ', ');
end

function out = ternary_numeric(condition, valueTrue, valueFalse)
% Small local helper to keep parameter assignments compact.

if condition
    out = valueTrue;
else
    out = valueFalse;
end
end

function out = ternary_position(condition, valueTrue, valueFalse)
% Local helper mirroring ternary_numeric for optional position vectors.

if condition
    out = valueTrue;
else
    out = valueFalse;
end
end

function epochIndices = resolve_mushiake_firing_rate_keep_epochs(iFactor, addFlatPrior, nSteps, defaultCount)
% Keep the same visible epoch subset used by the raster in the Supp figure.

if iFactor == 1 && addFlatPrior
    epochIndices = 0:(nSteps - 1);
    return;
end

epochIndices = 1:defaultCount;
end

function cmaps = resolve_mushiake_firing_rate_cmaps(iFactor, nSteps, addFlatPrior)
% Match firing-rate epoch colors to the Mushiake raster sector colors.

if iFactor == 1 && addFlatPrior
    cmaps = resolve_mushiake_zero_indexed_epoch_cmaps(nSteps);
    return;
end

cmaps = lines(nSteps);
end

function cmaps = resolve_mushiake_zero_indexed_epoch_cmaps(nSteps)
% Remap colors so epoch (0) uses the old fourth-step color while 1:3 keep cmaps(1:3,:).

baseCmaps = lines(nSteps + 2);
baseCmaps = baseCmaps(2:end, :);
cmaps = baseCmaps([4, 1, 2, 3], :);
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

function levelConfigs = resolve_mushiake_sample_level_configs()
% Plot both the current outer low-level MDP and the nested one-step recognition level.

levelConfigs = struct([]);

levelConfigs(1).displayLabel = 'outer';
levelConfigs(1).figureTag = 'Outer';
levelConfigs(1).useSingleStepRecognitionLevel = false;

levelConfigs(2).displayLabel = 'inner';
levelConfigs(2).figureTag = 'Inner';
levelConfigs(2).useSingleStepRecognitionLevel = true;
end

function data_trials = build_mushiake_plot_trials(testDir, trialNumbers, collectPms, sampleDataPms)
% Rebuild Mushiake data_trials directly from saved per-trial MDPs for one plot level.

data_trials = struct([]);

for iTrial = 1:numel(trialNumbers)
    trialNumber = trialNumbers(iTrial);
    [trialMDP, mdpFile] = load_sequence_trial_mdp(testDir, trialNumber);
    fprintf('Rebuilding data_trials from %s\n', mdpFile);
    builtTrials = build_mushiake_trial_data(trialMDP, trialNumber, collectPms);

    for iBuilt = 1:numel(builtTrials)
        if isempty(data_trials)
            data_trials = builtTrials(iBuilt);
        else
            data_trials(end + 1) = builtTrials(iBuilt); %#ok<AGROW>
        end
    end
end

data_trials = normalise_mushiake_plot_trial_names(data_trials, sampleDataPms.trialNameTailLength);
data_trials = prepare_mushiake_preprocessed_plot_trials(data_trials, sampleDataPms);
end

function data_trials = normalise_mushiake_plot_trial_names(data_trials, tailLength)
% Mirror the trim logic used by extract_sequence_data_trials.

for iTrial = 1:numel(data_trials)
    trialName = data_trials(iTrial).trialName;
    keepCount = min(numel(trialName), tailLength);
    data_trials(iTrial).trialName = trialName(end - keepCount + 1:end);
end
end

function data_trials = prepare_mushiake_preprocessed_plot_trials(data_trials, pms)
% Extend preprocessed population firing rates and generate spikes in memory.

labEpochs = data_trials(1).labEpochs;
nBins = sum(labEpochs == 1);
Nev = pms.Nev;
if isempty(Nev)
    Nev = ones(1, pms.nLength);
end

for iTrial = 1:numel(data_trials)
    popFR = data_trials(iTrial).popFR;
    [FR, tFR, extLabEpochs] = HAI_extendFiringRates(popFR, nBins, pms.Nnr, Nev, pms.dt);
    PopRates = HAI_extendFiringRates(popFR, nBins, 1, Nev, pms.dt);
    timePopRates = pms.nLength * tFR / tFR(end);

    data_trials(iTrial).PopRates = PopRates;
    data_trials(iTrial).timePopRates = timePopRates;
    data_trials(iTrial).firingRates = FR;
    data_trials(iTrial).timeFiringRates = pms.nLength * tFR / tFR(end);
    data_trials(iTrial).extLabEpochs = extLabEpochs;
    data_trials(iTrial).Spikes = firingRatesToSpikes(FR, pms);
    data_trials(iTrial).timeSpikes = data_trials(iTrial).timeFiringRates;
    data_trials(iTrial).popFRcosine = FR;
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

function merged = merge_struct_fields(baseStruct, extraStruct)
merged = baseStruct;
if isempty(extraStruct)
    return;
end
fieldNames = fieldnames(extraStruct);
for fieldIndex = 1:numel(fieldNames)
    merged.(fieldNames{fieldIndex}) = extraStruct.(fieldNames{fieldIndex});
end
end

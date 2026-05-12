%function MAIN_Chen01_S1S2S3_Sensors_Exp
%MAIN_CHEN01_S1S2S3_SENSORS_EXP Clean Chen01 sensor main with generic plotting pipeline.

print_main_dependency_disclaimer(mfilename, {'HAI_LANGUAGE', 'TrialBox', 'SPM'});

%% Global settings
rng(3);
nReps                           = 1;
randsReps                       = randi(2^9, nReps, 1);
saveRootDir                     = '~/TESTS/HAI_SEQUENCES/Chen01/';
saveRootDir                     = '/TESTS/HAI_SEQUENCES/Chen01/';
appendReadoutSuffix             = false;
hfgSample                       = struct();
lastSaveDir                     = '';
saveFigures                     = true;
sampleTemporalOversampling      = 3; % Increase internal raster bins while keeping the displayed time axis fixed.
% sampleTemporalOversampling      = 1; % Legacy binning.

%% Experiment parameters
runPms                          = run_sensorsParams();
runPms.experimentLabel          = 'Chen01';
runPms.mainProb                 = [0.8, 1.0];
runPms.debugmode                = false;
dictionary                      = feval(runPms.dictionary);
nTasks                          = numel(dictionary.STATES{2});
iTasks                          = 1:nTasks;
description                     = sprintf('%s_SEQUENCES_ABCDEF_Sensors_Ord_COS(%g,%g)', ...
    runPms.experimentLabel, runPms.mainProb(1) * 100, runPms.mainProb(2) * 100);

%% Run trials
for rep = 1:nReps
    rng(randsReps(rep));

    saveDir = [fullfile(saveRootDir, description, sprintf('Rep%02d', rep)) filesep];
    fprintf('Executing %s, Rep %g, save dir: %s\n', mfilename, rep, saveDir);
    if ~isfolder(saveDir)
        mkdir(saveDir);
    end

    runPms.saveDir = saveDir;
    lastSaveDir = saveDir;
    randsTrials = get_or_create_trial_seeds(saveDir, nTasks);

    for iTrial = iTasks
        runPms.iTrial = iTrial;
        runPms.irng = randsTrials(iTrial);
        runPms.trialDescription = build_sensor_trial_description(runPms);

        existingTrialFile = find_existing_trial_file(saveDir, runPms, []);
        if ~isempty(existingTrialFile)
            fprintf('Reusing existing trial %g from %s\n', iTrial, existingTrialFile);
            continue;
        end

        run_sensors(runPms);
    end

    fprintf('Ended %s!\n', mfilename);
    Collect_Sensor_Results(saveDir, description, runPms.namefor, nTasks);
end

%% Extract sequence trials parameters
extractPms                       = extract_sequence_data_trialsParams();
extractPms.usePreprocessedPopFR  = true;
extractPms.nLength               = 5;
extractPms.Nev                   = ones(1, extractPms.nLength);
extractPms.Nev                   = sampleTemporalOversampling * extractPms.Nev;
extractPms.Nnr                   = 4;%128;
extractPms.th                    = 0.2;
SpikeMode                        = 'thresholded_refractory';
% SpikeMode                        = 'legacy'; % Legacy spike generator.
extractPms.spikeGenerationMode   = SpikeMode;
if strcmpi(extractPms.spikeGenerationMode, 'thresholded_refractory')
    extractPms.refractoryBins    = sampleTemporalOversampling * extractPms.refractoryBins;
    % extractPms.refractoryBins    = 2; % Legacy-scale refractory bins, independent of oversampling.
end

sampleTrials                     = extract_sequence_trials(lastSaveDir, extractPms);
readoutSuffix                    = build_optional_readout_suffix( ...
    appendReadoutSuffix, 'Sensors', 0, 0, extractPms.th, extractPms.Nnr);

%% Plot parameters
firingRatePms                        = plot_sequence_firing_rateParams();
firingRatePms.ifplot                 = false;
%firingRatePms.saveFigures            = true;
firingRatePms.experimentLabel        = runPms.experimentLabel;
firingRatePms.figureTargetLabel      = 'ABCDEF';
firingRatePms.figureFamilyLabel      = 'Sensors';
firingRatePms.figureDirectionLabel   = 'Ord';
firingRatePms.firingRatePlotter      = 'HAI_ABC_XIE_FiringRate_L1';
firingRatePms.firingRateColorMode    = 'action';
firingRatePms.firingRateUseBrightnessScaling = false;
firingRatePms.actions                = {'A', 'B', 'C', 'D', 'E', 'F'};
firingRatePms.cmaps                  = lines(6);
firingRatePms.nLength                = 5;
firingRatePms.Nev                    = ones(1, firingRatePms.nLength);
firingRatePms.th                     = 0.2;
firingRatePms.scaleFiringRateTimeByEpochs = false;
firingRatePms.firingRateTimeOffset   = 0.1;
firingRatePms.thresh                 = eps;
firingRatePms.smooth                 = 3;
firingRatePms.offset                 = 0.002;

rasterPms                            = plot_sequence_rasterParams();
rasterPms.ifplot                     = false;
% rasterPms.saveFigures                = true;
rasterPms.experimentLabel            = runPms.experimentLabel;
rasterPms.figureTargetLabel          = 'ABCDEF';
rasterPms.figureFamilyLabel          = 'Sensors';
rasterPms.figureDirectionLabel       = 'Ord';
rasterPms.rasterPlotter              = 'HAI_ABCDEF_LEV1_SampleRaster';
rasterPms.actions                    = firingRatePms.actions;
rasterPms.cmaps                      = firingRatePms.cmaps;
rasterPms.nEpochsRaster              = 6;
rasterPms.matchRasterYLimToPlotter   = true;
rasterPms.rasterYTickLabels          = rasterPms.actions;

summaryFigureTag = sprintf('%s_%s_%s_%s%s', ...
    firingRatePms.experimentLabel, firingRatePms.figureTargetLabel, ...
    firingRatePms.figureFamilyLabel, firingRatePms.figureDirectionLabel, ...
    readoutSuffix);

%% Sample trials
sampleIndices = [1, 121];
for iSample = 1:numel(sampleIndices)
    hfgSample = add_sample_trial_plots( ...
        hfgSample, sampleTrials, sampleIndices(iSample), firingRatePms, ...
        rasterPms, lastSaveDir, readoutSuffix);
end

%% Polar plots
sampleTrials = add_sensor_type_fields(sampleTrials, firingRatePms.actions);
typeFields = {'type1', 'type2', 'type3'};
polarPms = plotNeuronPolarByConditionParams();
polarPms.DataField = 'PopRates'; dx = 1;
% polarPms.DataField = 'Spikes'; dx = extractPms.Nnr;
polarPms.RLimits = [0 1];
polarPms.FigurePosition = [0, 0, 398, 900];
polarPms.TimeField = 'timeSpikes';
polarPms.TimeWindow = [0.9, 1.0];
polarPms.ErrorType = 'none';
polarPms.Visible = resolve_visible_flag(firingRatePms.ifplot);

hstruct = tileNeuronPolarByTypes(sampleTrials, 1:4:4*6, typeFields, polarPms);
hfgSample.(['PolarPlotRank1_' summaryFigureTag]) = hstruct.fig;

%% BETA pca space plots
betaPms                             = BETA_pcaSpaceParams();
betaPms.ifplot                      = false;
%betaPms.saveFiguresDir              = lastSaveDir;
betaPms.usePreprocessedPopFR        = true;
betaPms.signalName                  = 'Spikes';       % pca on population firing rates (trial-averaged)
betaPms.signalName                  = 'Spikes';       % pca on population firing rates (trial-averaged)
%betaPms.signalName                  = 'popFRcosine';       % pca on population firing rates (trial-averaged)
betaPms.signalName                  = 'PopRates';       % pca on population firing rates (trial-averaged)

betaPms.experimentLabel             = runPms.experimentLabel;
betaPms.figureTargetLabel           = 'ABCDEF';
betaPms.figureFamilyLabel           = 'Sensors';
betaPms.figureDirectionLabel        = 'Ord';
betaPms.figureDescription           = 'BETA_pca';
betaPms.figureSuffixAppend          = readoutSuffix;
betaPms.trialIndices                = 1:120;
betaPms.nLength                     = 5;
betaPms.Wlength                     = 90;
betaPms.overlap                     = 4;
betaPms.pcaTimeXLim                 = [0,5.1];
betaPms.pcaTimeYLim                 = [];
betaPms.pcaTimeZLim                 = [];
betaPms.plotPcaPolygons             = true;
betaPms.plotPcaTrajectories         = true;
betaPms.plotPcaTime                 = true;
betaPms.trajectorySmoothing         = 10;
betaPms.timeSmoothing               = 2;
betaPms.pcaTimeOffset               = 0.4;
betaPms.prependPcaTimeAnchor        = false;
betaPms.pcaTimeHullAnchor           = 'highlight';
betaPms.pcaTimeHighlightIndices     = [5, 8, 10];
betaPms.betaCompatibilityMode       = 'sensor_legacy';
betaPms.pcaTimeFigurePosition       = [0, 0, 800, 1000];
% label positions
betaPms.pcaTimeEpochLabelXOffsets       = [0, 0, 0] + 0.34;  % positive values move labels to the right, negative to the left
betaPms.pcaTimeEpochLabelYOffsets       = [0, 0, 0] + 0.01;  % positive values move labels up, negative down
betaPms.pcaTimeEpochLabelAxisTilt       = +0.02;             % rotate clockwise (positive) or counterclockwise (negative) to better align epoch labels with tilted time axes
betaPms.pcaTimeEpochLabelSpacingScale   = 0.85;


[hfgBeta, betaResults]              = BETA_pcaSpace(sampleTrials, betaPms); %#ok<NASGU,ASGLU>
hfgSample = merge_struct_fields(hfgSample, hfgBeta);

%% Save figures
if saveFigures
    save_sequence_figures(hfgSample, ...
        sprintf('SUMMARY_%s', summaryFigureTag), ...
        lastSaveDir);
    close all;
end

%% auxiliary functions
function hfgOut = add_sample_trial_plots(hfgIn, sampleTrials, sampleIndex, firingRatePms, rasterPms, lastSaveDir, readoutSuffix)
hfgOut = hfgIn;
sampleTrialNumber = sampleTrials(sampleIndex).sourceTrialIndex;
[sampleMDP, mdpFile] = load_sequence_trial_mdp(lastSaveDir, sampleTrialNumber);
fprintf('Using sample MDP %s\n', mdpFile);

localFRPms = firingRatePms;
localFRPms.sampleTrial = sampleIndex;

localRasterPms = rasterPms;
localRasterPms.sampleTrial = sampleIndex;

[hfgOut, oldFRName] = plot_sequence_firing_rate(hfgOut, sampleTrials, sampleMDP, sampleIndex, localFRPms);
[hfgOut, oldRasterName] = plot_sequence_raster(hfgOut, sampleTrials, sampleMDP, sampleIndex, localRasterPms);
set_visible_axes_title(hfgOut.(oldFRName), '');
sampleTitle = build_sensor_raster_title(sampleMDP, sampleTrials(sampleIndex), localRasterPms.actions);
set_visible_axes_title(hfgOut.(oldRasterName), sampleTitle);

sampleFigureTag = sprintf('%s_%s_%s_%s_Trial%d%s', ...
    localFRPms.experimentLabel, localFRPms.figureTargetLabel, ...
    localFRPms.figureFamilyLabel, localFRPms.figureDirectionLabel, ...
    sampleTrialNumber, readoutSuffix);

hfgOut.(['FiringRate_' sampleFigureTag]) = hfgOut.(oldFRName);
hfgOut = rmfield(hfgOut, oldFRName);
hfgOut.(['Raster_' sampleFigureTag]) = hfgOut.(oldRasterName);
hfgOut = rmfield(hfgOut, oldRasterName);
end

function sampleTrials = add_sensor_type_fields(sampleTrials, actions)
% Rebuild sensor condition fields locally so the generic polar plotters can run.

for iTrial = 1:numel(sampleTrials)
    trialName = char(sampleTrials(iTrial).trialName);
    nSteps = min(3, numel(trialName));

    for iStep = 1:3
        typeField = ['type' num2str(iStep)];
        sampleTrials(iTrial).(typeField) = false(1, numel(actions));

        if iStep <= nSteps
            sampleTrials(iTrial).(typeField) = ismember(actions, trialName(iStep));
        end
    end
end
end

function trialTitle = build_sensor_raster_title(sampleMDP, dataTrial, actions)
% Build a sensor raster title using only task letters and the actual trial dimensionality.

trialTitle = char(dataTrial.trialName);
if isempty(trialTitle)
    trialTitle = build_sequence_policy_title(sampleMDP, dataTrial);
end

validSymbols = [actions{:}];
isValid = ismember(trialTitle, validSymbols);
trialTitle = trialTitle(isValid);

nSteps = infer_sensor_sample_step_count(sampleMDP, dataTrial);
keepCount = min(nSteps, numel(trialTitle));
trialTitle = trialTitle(1:keepCount);
end

function nSteps = infer_sensor_sample_step_count(sampleMDP, dataTrial)
% Infer how many symbolic targets are actually present in this sensor trial.

nSteps = numel(char(dataTrial.trialName));

if iscell(sampleMDP) && ~isempty(sampleMDP)
    root = sampleMDP{1};
elseif isstruct(sampleMDP)
    root = sampleMDP;
else
    root = [];
end

if isstruct(root) && isfield(root, 'mdp') && ~isempty(root.mdp)
    nSteps = numel(root.mdp);
end
end

function suffix = build_optional_readout_suffix(appendReadoutSuffix, cosineFunctionName, percCenter, cap, th, Nnr)
if ~appendReadoutSuffix
    suffix = '';
    return;
end
suffix = sprintf('_%s_nnr%s_pc%s_cap%s_th%s', ...
    normalise_name_token(cosineFunctionName), ...
    normalise_numeric_token(Nnr), ...
    normalise_numeric_token(percCenter), ...
    normalise_numeric_token(cap), ...
    normalise_numeric_token(th));
end

function token = normalise_name_token(value)
token = regexprep(char(string(value)), '[^A-Za-z0-9]+', '');
if isempty(token)
    token = 'value';
end
end

function token = normalise_numeric_token(value)
token = regexprep(sprintf('%.6g', value), '[^0-9-]+', 'p');
token = regexprep(token, 'p+', 'p');
token = regexprep(token, '^p|p$', '');
if isempty(token)
    token = '0';
end
end

function visibleFlag = resolve_visible_flag(ifplot)
if ifplot
    visibleFlag = 'on';
else
    visibleFlag = 'off';
end
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

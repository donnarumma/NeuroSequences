%function MAIN_Chen01_S1S2S3_Backward_Exp
%MAIN_CHEN01_S1S2S3_BACKWARD_EXP Clean Chen01 backward main with generic plotting pipeline.

print_main_dependency_disclaimer(mfilename, {'HAI_LANGUAGE', 'TrialBox', 'SPM'});

%% Global settings
rng(3);
nReps                           = 1;
randsReps                       = randi(2^9, nReps, 1);
saveRootDir                     = '~/TESTS/HAI_SEQUENCES/Chen01/';
saveRootDir                     = '/TESTS/HAI_SEQUENCES/Chen01/';
appendReadoutSuffix             = false;
saveFigures                     = true;
nActions                        = 6;
%% Experiment parameters
experimentPms                   = run_sequenceParams();
experimentPms.experimentLabel   = 'Chen01';
experimentPms.minSeqLen         = 1;
experimentPms.include3D         = true;
experimentPms.include2D         = true;
experimentPms.include1D         = true;
experimentPms.typeMask3D        = logical([0 0 0 0 0 1]);
experimentPms.policyFamilyWeights = [1/3, 1/3, 1/3];

description                     = build_batch_description(experimentPms);
sequenceModel                   = build_sequence_model(experimentPms);
nTasks                          = sequenceModel.nTasks;
iTasks                          = 1:nTasks;
lastSaveDir                     = '';
hfgSample                       = struct();

%% Readout parameters
tunemode                        = 3; % 0=no tuning, 1=cosineTune, 2=cosineTuningStep, 3=cosineTuneCircularBlocks       
[cosineFunction, cosinepms, cosineFunctionName] = getCosineTuning(tunemode);


%% Run trials
for rep = 1:nReps
    rng(randsReps(rep));

    saveDir = [fullfile(saveRootDir, description, sprintf('Rep%02d', rep)) filesep];
    fprintf('Executing %s, Rep %g, save dir: %s\n', mfilename, rep, saveDir);
    if ~isfolder(saveDir)
        mkdir(saveDir);
    end

    experimentPms.saveDir = saveDir;
    lastSaveDir = saveDir;
    save_batch_metadata(saveDir, sequenceModel, experimentPms, description, rep);

    randsTrials = get_or_create_trial_seeds(saveDir, nTasks);

    for iTrial = iTasks
        experimentPms.iTrial = iTrial;
        experimentPms.irng = randsTrials(iTrial);
        experimentPms.trialDescription = build_sequence_trial_description(sequenceModel, experimentPms);

        existingTrialFile = find_existing_trial_file(saveDir, experimentPms, sequenceModel);
        if ~isempty(existingTrialFile)
            fprintf('Reusing existing trial %g from %s\n', iTrial, existingTrialFile);
            continue;
        end

        run_sequence(sequenceModel, experimentPms);
    end

    fprintf('Ended %s!\n', mfilename);
    Collect_Trial_Results(saveDir, description, experimentPms.namefor, nTasks);
end

%% Extract sequence trials parameters
extractPms                      = extract_sequence_data_trialsParams();
extractPms.Nev                  = ones(1, 9);
extractPms.Nnr                  = 4;
extractPms.dt                   = 1/64;
extractPms.cap                  = 0.5;
extractPms.th                   = 0.06;
extractPms.SpT                  = 1/16;
%extractPms.percCenter           = 0.75;
extractPms.nActions             = nActions;
extractPms.spikeNoise           = 0;
extractPms.cosineTuning         = cosineFunction;
extractPms.cosinepms            = cosinepms;
extractPms.spikeGenerationMode   = spikeMode;  


extractPms.spikeGenerationMode  = spikeMode;
sampleTrials                    = extract_sequence_trials(lastSaveDir, extractPms);
readoutSuffix                   = build_optional_readout_suffix( ...
    appendReadoutSuffix, cosineFunctionName, extractPms.percCenter, ...
    extractPms.cap, extractPms.th, extractPms.Nnr);

% sampleCmaps                      = lines(3); % default MATLAB-like colors for step-level BETA plots
sampleCmaps                      = lines(9);
sampleCmaps([1, 5:end], :)       = [];

%% Plot parameters
firingRatePms                        = plot_sequence_firing_rateParams();
firingRatePms.ifplot                 = false;
firingRatePms.saveFigures            = true;
firingRatePms.experimentLabel        = experimentPms.experimentLabel;
firingRatePms.figureTargetLabel      = 'ABCDEF';
firingRatePms.figureFamilyLabel      = 'S1S2S3';
firingRatePms.figureDirectionLabel   = 'Bwd';
firingRatePms.Nev                    = ones(1, 9);
firingRatePms.cmaps                  = sampleCmaps;
firingRatePms.firingRateSectorTime   = 1:0.01:6;
firingRatePms.firingRateXLim         = [-0.1, 5.15];
firingRatePms.offset                 = 0.001;

rasterPms                            = plot_sequence_rasterParams();
rasterPms.ifplot                     = false;
rasterPms.saveFigures                = true;
rasterPms.experimentLabel            = experimentPms.experimentLabel;
rasterPms.figureTargetLabel          = 'ABCDEF';
rasterPms.figureFamilyLabel          = 'S1S2S3';
rasterPms.figureDirectionLabel       = 'Bwd';
rasterPms.cmaps                      = sampleCmaps;
rasterPms.rasterSectorTime           = 0:0.01:5;
rasterPms.rasterXLim                 = [0, 5];
rasterPms.rasterYLim                 = [0.5, rasterPms.Nnr * (6 * 3) + 0.5];

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
typeFields = {'type1', 'type2', 'type3'};
polarPms = plotNeuronPolarByConditionParams();
polarPms.DataField = 'PopRates'; dx = 1;
% polarPms.DataField = 'Spikes'; dx = extractPms.Nnr;
polarPms.RLimits = [0 1];
polarPms.FigurePosition = [0, 0, 398, 900];
polarPms.TimeField = 'timeSpikes';
polarPms.TimeWindow = [4, 5];
polarPms.ErrorType = 'none';
polarPms.Visible = resolve_visible_flag(firingRatePms.ifplot);

rank1 = 1:dx:nActions * dx;
rank2 = (nActions * dx + 1):dx:2 * nActions * dx;
rank3 = (2 * nActions * dx + 1):dx:3 * nActions * dx;

hstruct = tileNeuronPolarByTypes(sampleTrials, rank1, typeFields, polarPms);
hfgSample.(['PolarPlotRank1_' summaryFigureTag]) = hstruct.fig;
hstruct = tileNeuronPolarByTypes(sampleTrials, rank2, typeFields, polarPms);
hfgSample.(['PolarPlotRank2_' summaryFigureTag]) = hstruct.fig;
hstruct = tileNeuronPolarByTypes(sampleTrials, rank3, typeFields, polarPms);
hfgSample.(['PolarPlotRank3_' summaryFigureTag]) = hstruct.fig;

%% BETA pca space plots
betaPms                             = BETA_pcaSpaceParams();
betaPms.ifplot                      = false;
betaPms.saveFiguresDir              = lastSaveDir;
betaPms.experimentLabel             = experimentPms.experimentLabel;
betaPms.figureTargetLabel           = 'ABCDEF';
betaPms.figureFamilyLabel           = 'S1S2S3';
betaPms.figureDirectionLabel        = 'Bwd';
betaPms.figureDescription           = 'BETA_pca';
betaPms.figureSuffixAppend          = readoutSuffix;
betaPms.cmaps                       = sampleCmaps;
betaPms.trialIndices                = 1:120;
betaPms.typeStepCount               = 3;
betaPms.Nev                         = ones(1, 9);
betaPms.pcaExplainedVarianceWindowIndex = 1;

betaPms.pcaTimeOffset               = 1.1;
betaPms.pcaTimeXLim                 = [0, 4.1];
betaPms.pcaTimeZLim                 = [-0.7,0.7];%[-0.5,0.5];
betaPms.pcaTimeYLim                 = [];%[-0.5,0.5];
betaPms.timeSmoothing               = 3;
betaPms.pcaTimeMaxTime              = 4.0;
betaPms.pcaTimeFigurePosition       = [0, 0, 800, 1000];
betaPms.prependPcaTimeAnchor        = true;
betaPms.pcaTimeTraceSeparationMode = 'noise';
betaPms.betaCompatibilityMode       = 'sequence_legacy';
%betaPms.pcaTimeYLim                 = [-1.5, 1.5];
%betaPms.pcaTimeZLim                 = [-1.5, 1.5];

% label positions
%betaPms.pcaTimeEpochLabels              = {'Pre', 'S1', 'S2', 'Delay', 'Cue', 'Delay2', ' ', ' '};
betaPms.pcaTimeEpochLabelXOffsets       = [0, 0, 0] + 0.22; % positive values move labels to the right, negative to the left
betaPms.pcaTimeEpochLabelYOffsets       = [0, 0, 0];        % positive values move labels up, negative down
betaPms.pcaTimeEpochLabelAxisTilt       = +0.017;            % rotate clockwise (negative) or counterclockwise (positive) to better align epoch labels with tilted time axes
betaPms.pcaTimeEpochLabelSpacingScale   = 0.83;             % increase to add more space between epoch labels, decrease to bring them closer together


% beta1
% betaPms.signalName                  = 'Spikes';       % pca on neuron spike not yet implemented  
% betaPms.signalName                  = 'firingRates';  % pca on neuronfiring rates not yet implemented
betaPms.signalName                  = 'PopRates';       % pca on population firing rates (trial-averaged)
betaPms.Wlength                     = 90;
betaPms.overlap                     = 4;
betaPms.plotPcaPolygons             = false;
betaPms.plotPcaTrajectories         = true;
betaPms.plotPcaTime                 = true;
betaPms.plotPcaExplainedVariance    = false;
betaPms.plotPcaManifoldAngles       = false;
betaPms.plotPopulationResponses     = true;

[hfgBeta1, betaResults]              = BETA_pcaSpace(sampleTrials, betaPms); %#ok<NASGU,ASGLU>
hfgSample = merge_struct_fields(hfgSample, hfgBeta1);

% beta2
betaPms.Wlength                     = [];
betaPms.overlap                     = 1;
betaPms.plotPcaPolygons             = true;
betaPms.plotPcaTrajectories         = false;
betaPms.plotPcaTime                 = false;
betaPms.plotPcaExplainedVariance    = true;
betaPms.plotPcaManifoldAngles       = true;
betaPms.plotPopulationResponses     = false;

[hfgBeta2, betaResults]             = BETA_pcaSpace(sampleTrials, betaPms); %#ok<NASGU,ASGLU>
hfgSample = merge_struct_fields(hfgSample, hfgBeta2);

%% save figures
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
sampleActions = extract_action_labels_from_mdp(sampleMDP);

localFRPms = firingRatePms;
localFRPms.actions = sampleActions;
localFRPms.sampleTrial = sampleIndex;

localRasterPms = rasterPms;
localRasterPms.actions = sampleActions;
localRasterPms.sampleTrial = sampleIndex;

[hfgOut, oldFRName] = plot_sequence_firing_rate(hfgOut, sampleTrials, sampleMDP, sampleIndex, localFRPms);
[hfgOut, oldRasterName] = plot_sequence_raster(hfgOut, sampleTrials, sampleMDP, sampleIndex, localRasterPms);
set_visible_axes_title(hfgOut.(oldRasterName), build_sequence_policy_title(sampleMDP, sampleTrials(sampleIndex)));

sampleFigureTag = sprintf('%s_%s_%s_%s_Trial%d%s', ...
    localFRPms.experimentLabel, localFRPms.figureTargetLabel, ...
    localFRPms.figureFamilyLabel, localFRPms.figureDirectionLabel, ...
    sampleTrialNumber, readoutSuffix);

hfgOut.(['FiringRate_' sampleFigureTag]) = hfgOut.(oldFRName);
hfgOut = rmfield(hfgOut, oldFRName);
hfgOut.(['Raster_' sampleFigureTag]) = hfgOut.(oldRasterName);
hfgOut = rmfield(hfgOut, oldRasterName);
end

function suffix = build_readout_suffix(cosineFunctionName, percCenter, cap, th, Nnr)
suffix = sprintf('_%s_nnr%s_pc%s_cap%s_th%s', ...
    normalise_name_token(cosineFunctionName), ...
    normalise_numeric_token(Nnr), ...
    normalise_numeric_token(percCenter), ...
    normalise_numeric_token(cap), ...
    normalise_numeric_token(th));
end

function suffix = build_optional_readout_suffix(appendReadoutSuffix, cosineFunctionName, percCenter, cap, th, Nnr)
if ~appendReadoutSuffix
    suffix = '';
    return;
end
suffix = build_readout_suffix(cosineFunctionName, percCenter, cap, th, Nnr);
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

function dNoise = directionNoise(vecsize)

rng(100); % fix the noise for the run
fact  = 10*10^-14*10^3;
dNoise  = ones(1, vecsize) + randn(1, vecsize) * fact; % 6*10^-14*10^3;
end

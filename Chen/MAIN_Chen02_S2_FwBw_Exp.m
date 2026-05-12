%function MAIN_Chen02_S2_FwBw_Exp
%MAIN_CHEN02_S2_FWBW_EXP Clean Chen02 S2 forward/backward main with generic plotting pipeline.

print_main_dependency_disclaimer(mfilename, {'HAI_LANGUAGE', 'TrialBox', 'SPM'});

%% Global settings
rng(3);
nReps                           = 1;
randsReps                       = randi(2^9, nReps, 1);
saveRootDir                     = '~/TESTS/HAI_SEQUENCES/Chen02/';
saveRootDir                     = '/TESTS/HAI_SEQUENCES/Chen02/';
appendReadoutSuffix             = false;
nActions                        = 6;   
%% Experiment parameters
experimentPms                   = run_sequenceParams();
experimentPms.experimentLabel   = 'Chen02';
experimentPms.mainProb          = [1.0, 1.0];
experimentPms.debugmode         = false;
experimentPms.include3D         = false;
experimentPms.include2D         = true;
experimentPms.include1D         = false;
experimentPms.only2D            = true;
experimentPms.minSeqLen         = 2;
experimentPms.sequence2DMaxLen  = 3;
experimentPms.typeMask3D        = logical([1 0 0 0 0 1]);
experimentPms.policyTypeWeights = [10, 1];

description                     = build_batch_description(experimentPms);
sequenceModel                   = build_sequence_model(experimentPms);
nTasks                          = sequenceModel.nTasks;
iTasks                          = 1:nTasks;
lastSaveDir                     = '';
hfgSample                       = struct();

%% Readout parameters
tunemode                        = 3; % 0=no tuning, 1=cosineTune, 2=cosineTuningStep, 3=cosineTuneCircularBlocks       
[cosineFunction, cosinepms, cosineFunctionName, spikeMode] = getCosineTuning(tunemode);

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
extractPms                       = extract_sequence_data_trialsParams();
extractPms.Nnr                   = 4;
extractPms.dt                    = 1/64;
extractPms.cap                   = 0.5;0.7;
extractPms.th                    = 0.06;0.1;
extractPms.SpT                   = 1/16;
%extractPms.percCenter            = 0.75;
extractPms.nActions              = nActions;
extractPms.spikeNoise            = 0;
extractPms.Nev                   = ones(1, extractPms.nLength);
extractPms.cosineTuning          = cosineFunction;
extractPms.cosinepms             = cosinepms;
extractPms.spikeGenerationMode   = spikeMode;  

% sampleCmaps                      = lines(3); % default MATLAB-like colors for step-level BETA plots
sampleCmaps                      = lines(4);
sampleCmaps(1, :)                = [];
sampleCmaps                      = sampleCmaps([1, 3, 2], :);
extractPms.cosinepms             = cosinepms;

readoutSuffix                    = build_optional_readout_suffix( ...
    appendReadoutSuffix, cosineFunctionName, extractPms.percCenter, ...
    extractPms.cap, extractPms.th, extractPms.Nnr);

%% Plot parameters
firingRatePms                        = plot_sequence_firing_rateParams();
firingRatePms.ifplot                 = false;
firingRatePms.saveFigures            = true;
firingRatePms.experimentLabel        = experimentPms.experimentLabel;
firingRatePms.figureTargetLabel      = 'ABCDEF';
firingRatePms.figureFamilyLabel      = 'S2';
firingRatePms.nActions               = nActions;
firingRatePms.cmaps                  = sampleCmaps;
firingRatePms.Nev                    = ones(1, firingRatePms.nLength);
firingRatePms.firingRateTimeOffset   = 0.17;
firingRatePms.thresh                 = eps;
firingRatePms.smooth                 = 15;%12;
firingRatePms.jitter                 = 0.003;
firingRatePms.offset                 = 0.0025;
firingRatePms.asim                   = false;%true;
firingRatePms.nPoints                = 12;
firingRatePms.epochLabels            = {'Pre', 'S1', 'S2', 'Delay', 'Cue', 'Delay2', ' ', ' '};
firingRatePms.epochFractions         = ones(1, 8) / 8;
firingRatePms.firingRateSectorTime   = 1:0.01:9;
firingRatePms.firingRateXLim         = [-0.1, 6.01];

rasterPms                            = plot_sequence_rasterParams();
rasterPms.ifplot                     = false;
rasterPms.saveFigures                = true;
rasterPms.experimentLabel            = experimentPms.experimentLabel;
rasterPms.figureTargetLabel          = 'ABCDEF';
rasterPms.figureFamilyLabel          = 'S2';
rasterPms.nActions                   = nActions;
rasterPms.cmaps                      = sampleCmaps;
rasterPms.Nnr                        = extractPms.Nnr;
rasterPms.epochLabels                = firingRatePms.epochLabels;
rasterPms.epochFractions             = firingRatePms.epochFractions;
rasterPms.rasterSectorTime           = 0:0.01:7.95;
rasterPms.rasterXLim                 = [-0.02, 6.03];
rasterPms.rasterYLim                 = [0.5, rasterPms.Nnr * (6 * 2) + 0.5];

summaryFigureTag = sprintf('%s_%s_%s_%s%s', ...
    firingRatePms.experimentLabel, firingRatePms.figureTargetLabel, ...
    firingRatePms.figureFamilyLabel, 'FwBw', readoutSuffix);

%% Forward subset
extractPms.trialIndices              = 1:30;
[forwardTrials, ~, ~]                = extract_sequence_trials(lastSaveDir, extractPms);
hfgSample = add_sample_trial_plots( ...
    hfgSample, forwardTrials, 1, 'Fwd', firingRatePms, rasterPms, lastSaveDir, readoutSuffix);

%% Backward subset
extractPms.trialIndices              = 31:60;
[backwardTrials, ~, ~]               = extract_sequence_trials(lastSaveDir, extractPms);
backwardSampleIndices                = [1, 6];
for iSample = 1:numel(backwardSampleIndices)
    hfgSample = add_sample_trial_plots( ...
        hfgSample, backwardTrials, backwardSampleIndices(iSample), 'Bwd', ...
        firingRatePms, rasterPms, lastSaveDir, readoutSuffix);
end

%% Polar plots
typeFields = {'type1', 'type2'};
polarPms = plotNeuronPolarByConditionParams();
polarPms.DataField = 'PopRates'; dx = 1;
% polarPms.DataField = 'Spikes'; dx = extractPms.Nnr;
polarPms.RLimits = [0 1];
polarPms.FigurePosition = [0, 0, 398, 900];
polarPms.TimeField = 'timeSpikes';
polarPms.TimeWindow = [4, 5];
polarPms.ErrorType = 'none';
polarPms.Visible = resolve_visible_flag(firingRatePms.ifplot);

forwardRank1 = 1:dx:nActions * dx;
forwardRank2 = (nActions * dx + 1):dx:2 * nActions * dx;

hstruct = tileNeuronPolarByTypes(forwardTrials, forwardRank1, typeFields, polarPms);
hfgSample.(['PolarPlotRank1_' build_direction_summary_tag(firingRatePms, 'Fwd', readoutSuffix)]) = hstruct.fig;
hstruct = tileNeuronPolarByTypes(forwardTrials, forwardRank2, typeFields, polarPms);
hfgSample.(['PolarPlotRank2_' build_direction_summary_tag(firingRatePms, 'Fwd', readoutSuffix)]) = hstruct.fig;

hstruct = tileNeuronPolarByTypes(backwardTrials, forwardRank1, typeFields, polarPms);
hfgSample.(['PolarPlotRank1_' build_direction_summary_tag(firingRatePms, 'Bwd', readoutSuffix)]) = hstruct.fig;
hstruct = tileNeuronPolarByTypes(backwardTrials, forwardRank2, typeFields, polarPms);
hfgSample.(['PolarPlotRank2_' build_direction_summary_tag(firingRatePms, 'Bwd', readoutSuffix)]) = hstruct.fig;

%% BETA pca space plots
betaPms                             = BETA_pcaSpaceParams();
betaPms.ifplot                      = false;
betaPms.saveFiguresDir              = lastSaveDir;
betaPms.experimentLabel             = experimentPms.experimentLabel;
betaPms.figureTargetLabel           = 'ABCDEF';
betaPms.figureFamilyLabel           = 'S2';
betaPms.figureDescription           = 'BETA_pca';
betaPms.figureSuffixAppend          = readoutSuffix;
betaPms.cmaps                       = sampleCmaps;
betaPms.typeStepCount               = 2;
betaPms.Nev                         = ones(1, betaPms.nLength);
betaPms.cap                         = 0.8;
betaPms.th                          = 0.1;
betaPms.pcaExplainedVarianceWindowIndex = 1;
betaPms.Wlength                     = 90;
betaPms.overlap                     = 4;
betaPms.plotPcaPolygons             = true;
betaPms.pcaPolygonFigurePosition    = [0, 0, 1400, 800];
betaPms.plotPcaTrajectories         = true;
betaPms.plotPcaTime                 = true;
betaPms.pcaPolygonShowDimInTitle    = true;

betaPms.timeSmoothing               = 6;
betaPms.pcaTimeMaxTime              = 5.1;
betaPms.pcaTimeOffset               = 1;%1.1;
betaPms.pcaTimeXLim                 = [0, 6.3];
betaPms.pcaTimeYLim                 = [];%[-1.5, 1.5];
betaPms.pcaTimeZLim                 = [];%[-1.5, 1.5];

betaPms.pcaTimeXTicks                   = 1:9;
betaPms.pcaTimeSectorPatchPositions     = 1:6;
% label positions
betaPms.pcaTimeEpochLabels              = {'Pre', 'S1', 'S2', 'Delay', 'Cue', 'Delay2', ' ', ' '};
betaPms.pcaTimeEpochLabelXOffsets       = [0, 0, 0] + 0.37; % positive values move labels to the right, negative to the left
betaPms.pcaTimeEpochLabelYOffsets       = [0, 0, 0] + 0.01; % positive values move labels up, negative down
betaPms.pcaTimeEpochLabelAxisTilt       = +0.01;            % rotate clockwise (negative) or counterclockwise (positive) to better align epoch labels with tilted time axes
betaPms.pcaTimeEpochLabelSpacingScale   = 0.83;             % increase to add more space between epoch labels, decrease to bring them closer together


betaPms.pcaTimeFigurePosition           = [0, 0, 800, 600];
betaPms.prependPcaTimeAnchor            = false;
betaPms.pcaTimeYLim                     = [-0.65,0.65];
betaPms.pcaTimeZLim                     = [-0.65,0.65];
betaPms.typeStepCount                   = 2;


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
betaPms.plotPopulationResponses     = false;
betaPms.pcaNeuronSelectionMode      = 'matched_step_blocks';
betaPms.prependPcaTimeAnchor        = true;
betaPms.pcaTimeTraceSeparationMode = 'noise';

% beta1 fwd
betaPms.figureSuffixAppend          = ['PCAForward' readoutSuffix];
[hfgBetaForward1, betaResultsForward] = BETA_pcaSpace(forwardTrials, betaPms); %#ok<NASGU,ASGLU>
hfgSample = merge_struct_fields(hfgSample, hfgBetaForward1);
% beta2 bwd
betaPms.figureSuffixAppend          = ['PCABackward' readoutSuffix];
[hfgBetaBackward1, betaResultsBackward] = BETA_pcaSpace(backwardTrials, betaPms); %#ok<NASGU,ASGLU>
hfgSample = merge_struct_fields(hfgSample, hfgBetaBackward1);

% [hfgBeta1, betaResults]              = BETA_pcaSpace(sampleTrials, betaPms); %#ok<NASGU,ASGLU>
% hfgSample = merge_struct_fields(hfgSample, hfgBeta1);

% beta2
betaPms.Wlength                     = [];
betaPms.overlap                     = 1.1;
betaPms.plotPcaPolygons             = true;
betaPms.plotPcaTrajectories         = false;
betaPms.plotPcaTime                 = false;
betaPms.plotPcaExplainedVariance    = true;
betaPms.plotPcaManifoldAngles       = true;
betaPms.plotPopulationResponses     = false;

% beta1 fwd
betaPms.figureSuffixAppend          = ['PCAForward' readoutSuffix];
[hfgBetaForward2, betaResultsForward] = BETA_pcaSpace(forwardTrials, betaPms); %#ok<NASGU,ASGLU>
hfgSample = merge_struct_fields(hfgSample, hfgBetaForward2);
% beta2 bwd
betaPms.figureSuffixAppend          = ['PCABackward' readoutSuffix];
[hfgBetaBackward2, betaResultsBackward] = BETA_pcaSpace(backwardTrials, betaPms); %#ok<NASGU,ASGLU>
hfgSample = merge_struct_fields(hfgSample, hfgBetaBackward2);

if firingRatePms.saveFigures
    save_sequence_figures(hfgSample, ...
        sprintf('SUMMARY_%s', summaryFigureTag), ...
        lastSaveDir);
    close all;
end

%% auxiliary functions
function hfgOut = add_sample_trial_plots(hfgIn, sampleTrials, sampleIndex, directionLabel, firingRatePms, rasterPms, lastSaveDir, readoutSuffix)
%ADD_SAMPLE_TRIAL_PLOTS Add one firing-rate/raster pair to the summary bundle.

hfgOut = hfgIn;

sampleTrialNumber = sampleTrials(sampleIndex).sourceTrialIndex;
[sampleMDP, mdpFile] = load_sequence_trial_mdp(lastSaveDir, sampleTrialNumber);
fprintf('Using sample MDP %s\n', mdpFile);
sampleActions = extract_action_labels_from_mdp(sampleMDP);

localFRPms = firingRatePms;
localFRPms.figureDirectionLabel = directionLabel;
localFRPms.actions = sampleActions;
localFRPms.sampleTrial = sampleIndex;

localRasterPms = rasterPms;
localRasterPms.figureDirectionLabel = directionLabel;
localRasterPms.actions = sampleActions;
localRasterPms.sampleTrial = sampleIndex;

[hfgOut, oldFRName] = plot_sequence_firing_rate( ...
    hfgOut, sampleTrials, sampleMDP, sampleIndex, localFRPms);
[hfgOut, oldRasterName] = plot_sequence_raster( ...
    hfgOut, sampleTrials, sampleMDP, sampleIndex, localRasterPms);

set_visible_axes_title(hfgOut.(oldRasterName), ...
    build_sequence_policy_title(sampleMDP, sampleTrials(sampleIndex)));

sampleFigureTag = sprintf('%s_%s_%s_%s_Trial%d%s', ...
    localFRPms.experimentLabel, localFRPms.figureTargetLabel, ...
    localFRPms.figureFamilyLabel, localFRPms.figureDirectionLabel, ...
    sampleTrialNumber, readoutSuffix);

hfgOut.(['FiringRate_' sampleFigureTag]) = hfgOut.(oldFRName);
hfgOut = rmfield(hfgOut, oldFRName);
hfgOut.(['Raster_' sampleFigureTag]) = hfgOut.(oldRasterName);
hfgOut = rmfield(hfgOut, oldRasterName);
end

function summaryTag = build_direction_summary_tag(firingRatePms, directionLabel, readoutSuffix)
%BUILD_DIRECTION_SUMMARY_TAG Build a direction-specific summary tag.

summaryTag = sprintf('%s_%s_%s_%s%s', ...
    firingRatePms.experimentLabel, firingRatePms.figureTargetLabel, ...
    firingRatePms.figureFamilyLabel, directionLabel, readoutSuffix);
end

function suffix = build_readout_suffix(cosineFunctionName, percCenter, cap, th, Nnr)
%BUILD_READOUT_SUFFIX Build a compact filename-safe suffix for saved figures.

suffix = sprintf('_%s_nnr%s_pc%s_cap%s_th%s', ...
    normalise_name_token(cosineFunctionName), ...
    normalise_numeric_token(Nnr), ...
    normalise_numeric_token(percCenter), ...
    normalise_numeric_token(cap), ...
    normalise_numeric_token(th));
end

function suffix = build_optional_readout_suffix(appendReadoutSuffix, cosineFunctionName, percCenter, cap, th, Nnr)
%BUILD_OPTIONAL_READOUT_SUFFIX Optionally add the readout suffix to figure names.

if ~appendReadoutSuffix
    suffix = '';
    return;
end

suffix = build_readout_suffix(cosineFunctionName, percCenter, cap, th, Nnr);
end

function token = normalise_name_token(value)
%NORMALISE_NAME_TOKEN Convert a label into a filename-safe token.

token = regexprep(char(string(value)), '[^A-Za-z0-9]+', '');
if isempty(token)
    token = 'value';
end
end

function token = normalise_numeric_token(value)
%NORMALISE_NUMERIC_TOKEN Convert numeric values into compact filename-safe tokens.

token = regexprep(sprintf('%.6g', value), '[^0-9-]+', 'p');
token = regexprep(token, 'p+', 'p');
token = regexprep(token, '^p|p$', '');
if isempty(token)
    token = '0';
end
end

function visibleFlag = resolve_visible_flag(ifplot)
%RESOLVE_VISIBLE_FLAG Convert boolean plotting flags into MATLAB figure visibility.

if ifplot
    visibleFlag = 'on';
else
    visibleFlag = 'off';
end
end

function merged = merge_struct_fields(baseStruct, extraStruct)
%MERGE_STRUCT_FIELDS Merge fields from extraStruct into baseStruct.

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

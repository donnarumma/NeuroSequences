%function MAIN_Xie_S3_Forward_Exp_Supp
%MAIN_XIE_S3_FORWARD_EXP SUPP Clean Xie S3 forward main with modular parameter blocks.

print_main_dependency_disclaimer(mfilename, {'HAI_LANGUAGE', 'TrialBox', 'SPM'});

%% Global settings
rng(3);
nReps                           = 1;
randsReps                       = randi(2^9, nReps, 1);
saveRootDir                     = '~/TESTS/HAI_SEQUENCES/Xie/';
saveRootDir                     = '/TESTS/HAI_SEQUENCES/Xie/';
appendReadoutSuffix             = false;

%% Experiment parameters
experimentPms                   = run_sequenceParams();
experimentPms.experimentLabel   = 'Xie';
experimentPms.mainProb          = [1.0, 1.0];
experimentPms.typeMask3D        = logical([1 0 0 0 0 0]);
experimentPms.nStayStates       = 7;

baseDescription                 = build_batch_description(experimentPms);
description                     = [baseDescription '_Supp'];
sequenceModel                   = build_sequence_model(experimentPms);
nTasks                          = sequenceModel.nTasks;
iTasks                          = 1:nTasks;
lastSaveDir                     = '';
hfgSample                       = struct();
nActions                        = 6;
saveFigures                     = true;

%% Readout parameters
% cosineFunctionName              = 'cosineTune';
% cosineFunction                  = str2func(cosineFunctionName);
tunemode                        = 3; % 0=no tuning, 1=cosineTune, 2=cosineTuningStep, 3=cosineTuneCircularBlocks       
[cosineFunction, cosinepms, cosineFunctionName, spikeMode] = getCosineTuning(tunemode);
cosinepms.kernelSharpness        = 10;    % 5     % 1
cosinepms.centerRetention        = 1.00;  % 0.95  % 0.60
cosineParamSuffix               = build_cosine_param_suffix(cosinepms);
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
extractPms.percCenter            = 0.75;
extractPms.nActions              = nActions;
extractPms.spikeNoise            = 0;
extractPms.cosineTuning          = cosineFunction;

% % % cosinepms                        = cosineTuneParams();

% rng(10); fact = 6*10^(-14); spreadGain = 4; %Giov1
%rng(100); fact = 10*10^-14*10^3; % spreadGain = 2.5; %Giov1.5

% rng(100); fact = 10*10^-14*10^3; spreadGain = 2; %Giov2

% rng(100); fact = 10*10^-14*10^3; spreadGain = 0.8; %Giov3

%cosinepms.directionBias          = ones(1, extractPms.nActions * 3) + randn(1, extractPms.nActions * 3) * 10*10^-14*10^3; % 6*10^(-14);
%cosinepms.directionBias          = ones(1, extractPms.nActions * 3) + randn(1, extractPms.nActions * 3) * fact; % 6*10^-14*10^3;


% cosinepms.directionBias          = directionNoise(extractPms.nActions*3);

% cosinepms.spreadGain             = spreadGain;
extractPms.cosinepms             = cosinepms;
extractPms.spikeGenerationMode   = spikeMode;

% sampleCmaps                      = lines(3); % default MATLAB-like colors for step-level BETA plots
sampleCmaps                      = lines(9);
sampleCmaps([1, 5:end], :)       = [];

[sampleTrials, ~, ~]             = extract_sequence_trials(lastSaveDir, extractPms);
readoutSuffix                    = build_optional_readout_suffix( ...
    appendReadoutSuffix, cosineFunctionName, extractPms.percCenter, ...
    extractPms.cap, extractPms.th, extractPms.Nnr);
readoutSuffix                    = [readoutSuffix cosineParamSuffix];

%% Sample selection
sampleIndex                         = 1;
sampleTrialNumber                   = sampleTrials(sampleIndex).sourceTrialIndex;
[sampleMDP, mdpFile]                = load_sequence_trial_mdp(lastSaveDir, sampleTrialNumber);
fprintf('Using sample MDP %s\n', mdpFile);
sampleActions                       = extract_action_labels_from_mdp(sampleMDP);

%% Firing-rate plot
firingRatePms                        = plot_sequence_firing_rateParams();
firingRatePms.ifplot                 = false;
firingRatePms.experimentLabel        = experimentPms.experimentLabel;
firingRatePms.figureTargetLabel      = 'ABCDEF';
firingRatePms.figureFamilyLabel      = 'S3';
firingRatePms.figureDirectionLabel   = 'Fwd';
firingRatePms.nActions               = nActions;
firingRatePms.cmaps                  = sampleCmaps;
firingRatePms.firingRateTimeOffset   = 0;
firingRatePms.epochLabels            = {'Pre', 'S1', 'S2', 'S3', 'Delay', 'No'};
firingRatePms.epochFractions         = [1, 1, 1, 1, 1, 4] / 9;
firingRatePms.thresh                 = 0.1;
firingRatePms.smooth                 = 8;
firingRatePms.noise                  = 0;
firingRatePms.jitter                 = 0;
firingRatePms.offset                 = 0;
firingRatePms.asim                   = false;
firingRatePms.jitterAmplitude        = 0;
firingRatePms.nPoints                = 10;
firingRatePms.dstFiringRate          = [0.2, 0.03];
firingRatePms.firingRateSectorTime   = 0:0.01:9;
firingRatePms.firingRateXLim         = [-0.1, 5.1];
firingRatePms.actions                = sampleActions;
firingRatePms.sampleTrial            = sampleIndex;

sampleFigureTag = sprintf('%s_%s_%s_%s_Trial%d%s', ...
    firingRatePms.experimentLabel, firingRatePms.figureTargetLabel, ...
    firingRatePms.figureFamilyLabel, firingRatePms.figureDirectionLabel, ...
    sampleTrialNumber, readoutSuffix);
summaryFigureTag = sprintf('%s_%s_%s_%s%s', ...
    firingRatePms.experimentLabel, firingRatePms.figureTargetLabel, ...
    firingRatePms.figureFamilyLabel, firingRatePms.figureDirectionLabel, ...
    readoutSuffix);

[hfgSample, oldFRName]               = plot_sequence_firing_rate( ...
    hfgSample, sampleTrials, sampleMDP, sampleIndex, firingRatePms);
hfgSample.(['FiringRate_' sampleFigureTag]) = hfgSample.(oldFRName);
hfgSample = rmfield(hfgSample, oldFRName);

%% Raster plot
rasterPms                            = plot_sequence_rasterParams();
rasterPms.ifplot                     = false;
rasterPms.experimentLabel            = experimentPms.experimentLabel;
rasterPms.figureTargetLabel          = 'ABCDEF';
rasterPms.figureFamilyLabel          = 'S3';
rasterPms.figureDirectionLabel       = 'Fwd';
rasterPms.Nnr                        = extractPms.Nnr;
rasterPms.nActions                   = nActions;
rasterPms.cmaps                      = sampleCmaps;
rasterPms.dstRaster                  = [0.15, 0.05];
rasterPms.nEpochsRaster              = 3;
rasterPms.reset                      = 0;
rasterPms.rasterUseDataTime          = true;
rasterPms.rasterDataTimeMax          = 5;
rasterPms.rasterYLabelPatterns       = {'\(1\)$', '\(2\)$', '\(3\)$'};
rasterPms.epochLabels                = firingRatePms.epochLabels;
rasterPms.epochFractions             = firingRatePms.epochFractions;
rasterPms.actions                    = sampleActions;
rasterPms.sampleTrial                = sampleIndex;

[hfgSample, oldRasterName]           = plot_sequence_raster( ...
    hfgSample, sampleTrials, sampleMDP, sampleIndex, rasterPms);
set_visible_axes_title(hfgSample.(oldRasterName), ...
    build_sequence_policy_title(sampleMDP, sampleTrials(sampleIndex)));
hfgSample.(['Raster_' sampleFigureTag]) = hfgSample.(oldRasterName);
hfgSample = rmfield(hfgSample, oldRasterName);

%% Polar plot
typeFields = {'type1', 'type2', 'type3'};
polarPms = plotNeuronPolarByConditionParams();
polarPms.DataField = 'PopRates'; dx = 1;
% polarPms.DataField = 'Spikes'; dx = extractPms.Nnr;
polarPms.RLimits = [0 1];
polarPms.FigurePosition = [0, 0, 398, 900];
polarPms.TimeField = 'timeSpikes';
polarPms.TimeWindow = [4 ,5];
polarPms.ErrorType = 'none';
polarPms.Visible = resolve_visible_flag(firingRatePms.ifplot);

neuronIdxList1 = 1:dx:nActions * dx;
hstruct = tileNeuronPolarByTypes(sampleTrials, neuronIdxList1, typeFields, polarPms);
hfgSample.(['PolarPlotRank1_' summaryFigureTag]) = hstruct.fig;

neuronIdxList2 = ((nActions * dx) + 1):dx:2 * nActions * dx;
hstruct = tileNeuronPolarByTypes(sampleTrials, neuronIdxList2, typeFields, polarPms);
hfgSample.(['PolarPlotRank2_' summaryFigureTag]) = hstruct.fig;

neuronIdxList3 = (2 * nActions * dx) + 1:dx:3 * nActions * dx;
hstruct = tileNeuronPolarByTypes(sampleTrials, neuronIdxList3, typeFields, polarPms);
hfgSample.(['PolarPlotRank3_' summaryFigureTag]) = hstruct.fig;

neuronIdxList123=[neuronIdxList1, neuronIdxList2, neuronIdxList3];
typeFields123=repelem(typeFields,nActions);
hstruct = tileNeuronPolars6x3(sampleTrials, neuronIdxList123, typeFields123, polarPms);
hfgSample.(['PolarPlotRank123_' summaryFigureTag]) = hstruct.fig;


%% BETA pca space plot
betaPms                             = BETA_pcaSpaceParams();
betaPms.ifplot                      = false;
%betaPms.saveFiguresDir              = lastSaveDir;
betaPms.experimentLabel             = experimentPms.experimentLabel;
betaPms.figureTargetLabel           = 'ABCDEF';
betaPms.figureFamilyLabel           = 'S3';
betaPms.figureDirectionLabel        = 'Fwd';
betaPms.figureDescription           = 'BETA_pca';
betaPms.figureSuffixAppend          = readoutSuffix;
betaPms.cmaps                       = sampleCmaps;
betaPms.trialIndices                = 1:120;
betaPms.Nnr                         = 1;
betaPms.dt                          = 1/64;
betaPms.Nev                         = ones(1, betaPms.nLength);
betaPms.cap                         = 0.8;
betaPms.th                          = 0.2;
betaPms.SpT                         = 1/16;
betaPms.pcaAutoFlip                 = true;
betaPms.pcaPolygonLegendXOffset     = 0.01;
betaPms.timeSmoothing               = 3;
betaPms.pcaTimeMaxTime              = 4.0;
betaPms.pcaTimeTraceSeparationMode = 'noise';
betaPms.pcaTimeOffset               = 1.1;
betaPms.Wlength                     = 90;
betaPms.overlap                     = 4;    
betaPms.typeStepCount               = 3;
betaPms.pcaTimeXLim                 = [0,4.1];%[0, 5.1];
betaPms.pcaTimeYLim                 = [];%[-0.4, 0.4];
betaPms.pcaTimeZLim                 = [];%[-0.4, 0.45];
betaPms.pcaTimeXTicks               = 1:9;
betaPms.pcaTimeSectorPatchPositions = 1:5;
% betaPms.pcaTimeEpochLabelYOffsets   = [0, 0, 0] + 0.15;    % negative down, positive up
% betaPms.pcaTimeEpochLabelXOffsets   = [0, 0, 0] - 0.08; % negative left, positive right
%betaPms.pcaTimeEpochLabelAxisTilt   = -0.02;
% betaPms.pcaTimeEpochLabelSpacingScale = 1.01;

% label positions
betaPms.pcaTimeEpochLabels              = {'Pre', 'S1', 'S2', 'S3', 'Delay'};
betaPms.pcaTimeEpochLabelXOffsets       = [0, 0, 0] + 0.13; % positive values move labels to the right, negative to the left
betaPms.pcaTimeEpochLabelYOffsets       = [0, 0, 0] + 0.01; % positive values move labels up, negative down
betaPms.pcaTimeEpochLabelAxisTilt       = +0.01;            % rotate clockwise (negative) or counterclockwise (positive) to better align epoch labels with tilted time axes
betaPms.pcaTimeEpochLabelSpacingScale   = 0.85;             % increase to add more space between epoch labels, decrease to bring them closer together


betaPms.pcaTimeFigurePosition       = [0, 0, 800, 1000];
betaPms.prependPcaTimeAnchor        = false;
betaPms.betaCompatibilityMode       = 'sequence_legacy';

% beta1
% betaPms.signalName                  = 'Spikes';       
% betaPms.signalName                  = 'firingRates';       
betaPms.signalName                  = 'PopRates';       
betaPms.Wlength                     = 90;
betaPms.overlap                     = 4;
betaPms.prependPcaTimeAnchor        = true;

betaPms.plotPcaPolygons             = false;
betaPms.plotPcaTrajectories         = true;
betaPms.plotPcaTime                 = true;
betaPms.plotPcaExplainedVariance    = false;
betaPms.plotPcaManifoldAngles       = false;
betaPms.plotPopulationResponses     = false;
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
if saveFigures
    save_sequence_figures(hfgSample, ...
        sprintf('SUMMARY_%s', summaryFigureTag), ...
        lastSaveDir);
    close all;
end

%% auxiliary functions
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

function suffix = build_cosine_param_suffix(cosinepms)
%BUILD_COSINE_PARAM_SUFFIX Add tuning-shape parameters to saved names.

kernelSharpness = get_struct_field_or_default(cosinepms, 'kernelSharpness', 'NA');
centerRetention = get_struct_field_or_default(cosinepms, 'centerRetention', 'NA');
suffix = sprintf('_ks%s_cr%s', ...
    normalise_value_token(kernelSharpness), ...
    normalise_value_token(centerRetention));
end

function value = get_struct_field_or_default(inputStruct, fieldName, defaultValue)
%GET_STRUCT_FIELD_OR_DEFAULT Read a field without assuming tuning is active.

if isstruct(inputStruct) && isfield(inputStruct, fieldName)
    value = inputStruct.(fieldName);
else
    value = defaultValue;
end
end

function token = normalise_name_token(value)
%NORMALISE_NAME_TOKEN Convert a label into a filename-safe token.

token = regexprep(char(string(value)), '[^A-Za-z0-9]+', '');
if isempty(token)
    token = 'value';
end
end

function token = normalise_value_token(value)
%NORMALISE_VALUE_TOKEN Convert numeric or text values into filename-safe tokens.

if isnumeric(value)
    token = normalise_numeric_token(value);
else
    token = normalise_name_token(value);
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
% rng( 10); fact = 6*10^(-14);     spreadGain  = 4;   %Giov1
% rng(100); fact = 10*10^-14*10^3; spreadGain  = 2.5; %Giov1.5
% rng(100); fact = 10*10^-14*10^3; spreadGain  = 2;   %Giov2
% rng(100); fact = 10*10^-14*10^3; spreadGain  = 0.8; %Giov3

rng(100); % fix the noise for the run
fact  = 10*10^-14*10^3;
dNoise  = ones(1, vecsize) + randn(1, vecsize) * fact; % 6*10^-14*10^3;
end

function pms = BETA_pcaSpaceParams(parSource)
%BETA_PCASPACEPARAMS Self-contained defaults for BETA_pcaSpace.
%
% This parameter set is intentionally autonomous: all defaults used by
% BETA_pcaSpace are defined here directly, so sequence mains do not need
% to inherit anything from BETA_pcaParams.

% -------------------------------------------------------------------------
% General execution and figure metadata
% -------------------------------------------------------------------------
pms.ifplot                      = false;       % Show PCA figures on screen.
pms.saveFiguresDir              = '';          % Reference directory used to derive figure labels/suffixes.
pms.experimentLabel             = '';          % Optional explicit experiment label.
pms.figureTargetLabel           = '';          % Optional target-set label for figure names.
pms.figureFamilyLabel           = '';          % Optional family label for figure names.
pms.figureDirectionLabel        = '';          % Optional direction label for figure names.
pms.figureDescription           = 'BETA_pca';  % Descriptive tag kept for downstream naming.
pms.figureSuffixAppend          = '';          % Optional extra suffix appended to figure names.

% -------------------------------------------------------------------------
% Trial selection and symbolic trial encoding
% -------------------------------------------------------------------------
pms.trialIndices                = [];          % Optional subset of trials to analyse.
pms.trialNameTailLength         = 3;           % Keep only the symbolic suffix of each trial name.
pms.typeStepCount               = [];          % Optional number of symbolic steps encoded into trial.type.
pms.catNames                    = {'A','B','C','D','E','F'}; % Symbolic target labels used in one-hot trial types.
pms.cmaps                       = [];          % Optional external colormap used by step-level BETA summary plots; [] -> fallback to MATLAB defaults.

% -------------------------------------------------------------------------
% Signal construction and firing-rate preprocessing
% -------------------------------------------------------------------------
pms.Nnr                         = 1;           % Number of duplicate neurons per population after extension.
pms.dt                          = 1/64;        % Duration of one DEM update.
pms.nLength                     = 9;           % Trial duration used to rescale time axes.
pms.Nev                         = [];          % Optional epoch-wise replication counts; empty -> ones(1,nLength).
pms.cap                         = 0.8;         % Spike saturation parameter for synthetic spike generation.
pms.th                          = 0.1;         % Spike-noise threshold.
pms.SpT                         = 1/16;        % Spike threshold.
pms.signalName                  = 'firingRates'; % Signal analysed by the beta/PCA pipeline.
pms.pcaNormalizeBetas           = 'none';      % Optional beta normalization before PCA: 'none' or 'zscore'.
pms.hm                          = 2;           % Number of principal components highlighted in polygon titles.
pms.percCenter                  = 0.75;        % Main center weight used by legacy cosine tuning.
pms.useLegacyCompatibility      = false;       % Deprecated compatibility flag; kept for older mains.

% -------------------------------------------------------------------------
% Windowing and temporal smoothing
% -------------------------------------------------------------------------
pms.Wlength                     = [];          % Regression window length; [] uses the full trial as one window.
pms.overlap                     = 1;           % Overlap between consecutive windows.
pms.trajectorySmoothing         = [];          % Optional smoothing for PCA trajectory plots ([] = MATLAB default).
pms.timeSmoothing               = 6;           % Smoothing used for time-resolved PCA trajectories.
pms.pcaExplainedVarianceWindowIndex = [];      % Optional window used for explained variance; [] -> final window.

% -------------------------------------------------------------------------
% PCA figure toggles
% -------------------------------------------------------------------------
pms.plotPcaPolygons             = true;        % Plot PCA polygons at the selected summary window.
pms.plotPcaTrajectories         = false;       % Plot PCA trajectories across windows.
pms.plotPcaTime                 = false;       % Plot time-resolved PCA trajectories.
pms.plotPcaExplainedVariance    = true;        % Plot cumulative explained variance.
pms.plotPcaManifoldAngles       = true;        % Plot principal angles between symbolic subspaces.
pms.plotPopulationResponses     = false;       % Plot beta population-response heatmaps.
pms.pcaAutoFlip                 = true;        % Keep PCA axes aligned across windows/steps.

% -------------------------------------------------------------------------
% PCA neuron selection
% -------------------------------------------------------------------------
pms.pcaNeuronSelectionMode      = 'all';       % Neuron subset used for PCA:
                                               %   'all'                 -> all neurons
                                               %   'matched_step_blocks' -> step1 uses block 1, step2 block 2, etc.
                                               %   'custom'              -> use pcaNeuronBlocks{iStep}
pms.pcaNeuronBlocks             = {1:6, 7:12, 13:18}; % Optional manual neuron blocks used by 'custom'.

% -------------------------------------------------------------------------
% PCA polygon plot appearance
% -------------------------------------------------------------------------
pms.pcaPolygonShowDimInTitle    = false;       % Append effective latent dimensionality to polygon titles.
pms.pcaPolygonLegendXOffset     = 0.01;        % Horizontal offset for the shared polygon legend axes.
pms.pcaPolygonLegendYOffset     = 0;           % Vertical offset for the shared polygon legend axes.
pms.pcaPolygonFigurePosition    = [0, 0, 2000, 800]; % Figure position for PcaPolygons.
pms.polygonTicks                = -0.6:0.1:0.6; % Tick grid used in polygon plots.

% -------------------------------------------------------------------------
% Time-resolved PCA plot appearance
% -------------------------------------------------------------------------
pms.pcaTimeMaxTime              = 5.1;         % Keep only PCA time points below this value before offset.
pms.pcaTimeOffset               = 1.1;         % Additive time offset applied before plotting.
pms.pcaTimeXLim                 = [0, 6.3];    % Optional X limits for PcaTime.
pms.pcaTimeYLim                 = [-0.4, 0.4]; % Optional Y limits for PcaTime.
pms.pcaTimeZLim                 = [-0.4, 0.45]; % Optional Z limits for PcaTime.
pms.pcaTimeXTicks               = 1:9;         % Optional X ticks for PcaTime.
pms.pcaTimeSectorPatchPositions = 1:5;         % X positions of the gray epoch panels in PcaTime.
pms.pcaTimeFigurePosition       = [0, 0, 800, 600]; % Figure position for PcaTime.
pms.prependPcaTimeAnchor        = false;       % Prepend a fixed anchor point before plotting PCA trajectories.
pms.pcaTimeHullAnchor           = 'end';       % Hull anchor: 'end' or 'highlight'.
pms.pcaTimeHighlightIndices     = [];          % Optional per-step PCA windows used when pcaTimeHullAnchor = 'highlight'; [] keeps the built-in fallback.
pms.pcaTimeTraceSeparationMode  = 'none';      % Optional visual separation for overlapping PcaTime traces: 'none', 'offset', 'jitter', or 'noise'.
pms.pcaTimeTraceOffset          = 0.03;        % Deterministic offset magnitude used by the 'offset' mode.
pms.pcaTimeTraceJitter          = 0.01;        % Deterministic step-dependent jitter amplitude used by the 'jitter' mode.
pms.pcaTimeTraceNoiseStd        = 0.02;       % Random perturbation standard deviation used by the 'noise' mode.
pms.pcaTimeTraceRandomSeed      = 1;           % Random seed used to keep 'noise' mode reproducible across runs.

% -------------------------------------------------------------------------
% Epoch-label placement in PcaTime
% -------------------------------------------------------------------------
pms.pcaTimeEpochLabels          = {'Pre', 'S1', 'S2', 'S3', 'Delay'}; % Epoch labels shown under PcaTime panels.
pms.pcaTimeEpochLabelPositions  = [];          % Optional explicit positions for epoch labels.
pms.pcaTimeEpochLabelSequenceBaseXShift = 0.6; % Default X shift for sequence-style epoch labels.
pms.pcaTimeEpochLabelSensorBaseXShift = 0.4;   % Default X shift for sensor-style epoch labels.
pms.pcaTimeEpochLabelSpacingScale = 1;         % Global spacing multiplier for epoch labels.
pms.pcaTimeEpochLabelSpacingScales = [];       % Optional per-subplot spacing multipliers.
pms.pcaTimeEpochLabelSequenceBaseY = 0.5;      % Base Y anchor for sequence-style epoch labels.
pms.pcaTimeEpochLabelSensorBaseY = 6.1;        % Base Y anchor for sensor-style epoch labels.
pms.pcaTimeEpochLabelOverlayBaseY = 0.08;      % Normalized base Y anchor for generic overlay labels.
pms.pcaTimeEpochLabelXOffsets   = [];          % Optional per-subplot X offsets for epoch labels.
pms.pcaTimeEpochLabelYOffsets   = [];          % Optional per-subplot Y offsets for epoch labels.
pms.pcaTimeEpochLabelAxisTilt   = 0;           % Baseline tilt of the epoch-label axis.
pms.pcaTimeEpochLabelAxisTilts  = [];          % Optional per-subplot epoch-label tilts.
pms.pcaTimeEpochLabelYOffset    = 0;           % Legacy scalar Y offset kept for backward compatibility.

% -------------------------------------firingRatesToSpikes------------------------------------
% Legacy compatibility / naming
% -------------------------------------------------------------------------
pms.betaCompatibilityMode       = 'sequence_legacy'; % Legacy preset: 'generic', 'sequence_legacy', 'sensor_legacy'.

if nargin < 1 || isempty(parSource)
    return;
end

fieldNames = fieldnames(parSource);
for fieldIndex = 1:numel(fieldNames)
    pms.(fieldNames{fieldIndex}) = parSource.(fieldNames{fieldIndex});
end
end

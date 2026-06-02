function pms = plot_sequence_firing_rateParams(parSource)
%PLOT_SEQUENCE_FIRING_RATEPARAMS Defaults for firing-rate sample plots.

pms.ifplot              = true;                 % Show figures on screen.
pms.saveFigures         = false;                % Save generated figures to disk.
pms.saveFiguresDir      = '';                   % Optional explicit directory for saved figures.
pms.imnm                = '_Sequence';          % Suffix used in figure names.
pms.figureDescription   = 'SequenceSample';     % Base name used when saving figures.
pms.experimentLabel     = '';                   % Optional external experiment label.
pms.figureTargetLabel   = '';                   % Optional explicit target-set label for saved figure names.
pms.figureFamilyLabel   = '';                   % Optional explicit family label for saved figure names.
pms.figureDirectionLabel = '';                  % Optional explicit direction label for saved figure names.

pms.sampleTrial         = 1;                    % Trial position to visualise in detail.
pms.scaleFiringRateTimeByEpochs = true;         % If true, expand tPopFR to the full trial timeline before plotting.
pms.firingRateTimeOffset = 0.45;                % Vertical time-axis offset applied before the firing-rate plot.
pms.epochLabels         = {'Pre','S1','S2','S3','Delay'}; % Labels used in sector overlays.
pms.epochFractions      = [];                   % Optional sector widths; empty uses equal fractions across epochLabels.
pms.actions             = {};                   % Optional explicit action labels used by plotting helpers.
pms.cmaps               = [];                   % Optional explicit colour map for the plotting helpers.
pms.firingRatePlotter   = 'HAI_ABC_XIE_FiringRate_Seq3_Fwd'; % Plotting function used for the firing-rate figure.
pms.firingRateColorMode = 'epoch';            % Colour grouping used by firing-rate plotters that support it: 'epoch' or 'action'.
pms.firingRateUseBrightnessScaling = true;    % If true, lighten/darken traces according to the final response strength when supported by the firing-rate plotter.
pms.firingRateAppendEpochIndex = false;         % If true, append the epoch index to each firing-rate legend label when supported by the selected plotter.
pms.firingRateKeepActions = {};                 % Optional subset of action labels kept in the firing-rate plot and legend when supported by the selected plotter.
pms.firingRateKeepEpochIndices = [];            % Optional subset of epoch indices kept in the firing-rate plot and legend when supported by the selected plotter.
pms.firingRateLegendUnique = false;             % If true, collapse duplicate firing-rate legend labels when supported by the selected plotter.
pms.firingRateLegendNumColumns = [];            % Optional explicit number of legend columns for the firing-rate plot; empty uses a compact automatic choice.
pms.firingRateFirstTimeOverride = [];           % Optional override applied to timePotentials(1) in firing-rate plotters that support it.
pms.firingRateKeepTimeMax = [];                 % Optional max tPopFR value kept before plotting.
pms.firingRateNormalizeTimeAfterCrop = false;   % If true, remap the kept tPopFR interval to [0, 1].

pms.iFactor             = 1;                    % Hidden factor used by plotting helpers.
pms.Nnr                 = 4;                    % Number of duplicate neurons per population.
pms.dt                  = 1/64;                 % Duration of one DEM update.
pms.Nev                 = [];                   % Optional epoch-wise bin replication.
pms.cap                 = 0.8;                  % Spike saturation parameter.
pms.th                  = 0.1;                  % Noise threshold for spike generation / legend pruning.
pms.SpT                 = 1/16;                 % Spike threshold.
pms.nActions            = 6;                    % Number of action/target categories.
pms.nLength             = 9;                    % Trial length used to rescale time axes.

pms.thresh              = 0;                    % Firing-rate threshold for legend pruning.
pms.smooth              = 18;                   % Smoothing window used in firing-rate plots.
pms.jitter              = 0;                    % Additive jitter for firing-rate traces.
pms.noise               = 0;                    % Additive noise for firing-rate traces.
pms.offset              = 0.005;                % Vertical offset per neuron in firing-rate plots.
pms.asim                = false;                % Optional asymmetric offset mode.
pms.jitterAmplitude     = 0;                    % Horizontal jitter amplitude.
pms.nPoints             = 13;                   % Number of marker points shown on traces.
pms.reset               = 0;                    % Epoch label offset in plotting helpers.
pms.reduce              = false;                % Whether to reduce populations before plotting.
pms.dstFiringRate       = [0.27, 0.1];          % Sector overlay offset for firing-rate plot.
pms.firingRateSectorTime = [];                  % Optional explicit X support used by firing-rate sector overlays.
pms.firingRateXLim      = [];                   % Optional explicit x-limits for the firing-rate plot.

if nargin < 1 || isempty(parSource)
    return;
end

fieldNames = fieldnames(parSource);
for fieldIndex = 1:numel(fieldNames)
    pms.(fieldNames{fieldIndex}) = parSource.(fieldNames{fieldIndex});
end
end

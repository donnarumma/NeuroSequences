function pms = plot_sequence_rasterParams(parSource)
%PLOT_SEQUENCE_RASTERPARAMS Defaults for raster sample plots.

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
pms.epochLabels         = {'Pre','S1','S2','S3','Delay'}; % Labels used in sector overlays.
pms.epochFractions      = [];                   % Optional sector widths; empty uses equal fractions across epochLabels.
pms.actions             = {};                   % Optional explicit action labels used by plotting helpers.
pms.nActions            = 6;                    % Number of action/target categories.
pms.Nnr                 = 4;                    % Number of duplicate neurons per population.
pms.iFactor             = 1;                    % Hidden factor used by plotting helpers.
pms.rasterPlotter       = 'HAI_ABCDEF_3LEV_SampleRaster'; % Plotting function used for the raster figure.
pms.dstRaster           = [0.15, 0.05];         % Sector overlay offset for raster plot.
pms.rasterSectorTime    = [];                   % Optional explicit X support used by raster sector overlays.
pms.rasterXLim          = [];                   % Optional explicit x-limits for the raster plot.
pms.reset               = 0;                    % Default epoch-index offset used by legacy raster plotters when building Y tick labels.
pms.rasterReset         = [];                   % Optional epoch-label offset applied only to the raster plotter.
pms.rasterUseDataTime   = false;                % If true, use the sample trial spike-time vector for raster sector overlays and optional auto x-limits.
pms.rasterDataTimeMax   = [];                   % Optional upper time bound used when rasterUseDataTime is true.
pms.rasterYLabelLevel   = 2;                    % Label set used when deriving rasterYLim from neuron-label regex matches.
pms.rasterYLabelPatterns = {};                  % Optional regex patterns used to crop rasterYLim from neuronLabels().
pms.nEpochsRaster       = 3;                    % Number of task epochs highlighted in raster.
pms.matchRasterYLimToPlotter = false;           % If true, preserve the raster y-limits implied by the raster plotter internals.
pms.rasterYLim          = [];                   % Optional explicit y-limits for the raster plot.
pms.rasterYTickLabels   = {};                   % Optional simplified raster y-axis labels repeated across all raster groups.
pms.rasterApplyGenericPostprocessing = true;    % If false, skip generic axis overrides, sector overlays, and x-limit post-processing after the custom raster plotter.

if nargin < 1 || isempty(parSource)
    return;
end

fieldNames = fieldnames(parSource);
for fieldIndex = 1:numel(fieldNames)
    pms.(fieldNames{fieldIndex}) = parSource.(fieldNames{fieldIndex});
end
end

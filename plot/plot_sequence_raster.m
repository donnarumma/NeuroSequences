function [hfg, figureName] = plot_sequence_raster(hfg, data_trials, MDP, sampleIndex, pms)
%PLOT_SEQUENCE_RASTER Render the raster panel for one sample trial.

if nargin < 5 || isempty(pms)
    pms = plot_sequence_rasterParams();
else
    pms = plot_sequence_rasterParams(pms);
end

data_plot = data_trials(sampleIndex);
pmsRaster = pms;
pmsRaster.trials = sampleIndex;
pmsRaster.reduce = false;
pmsRaster.dst = pms.dstRaster;
pmsRaster.nEpochs = pms.nEpochsRaster;
if ~isempty(pmsRaster.rasterReset)
    pmsRaster.reset = pmsRaster.rasterReset;
end

hfg = feval(pmsRaster.rasterPlotter, hfg, data_trials, MDP, pmsRaster);
figureName = ['RasterTrial' num2str(sampleIndex) pmsRaster.imnm];
if ~pmsRaster.rasterApplyGenericPostprocessing
    return;
end

apply_raster_axis_overrides(hfg, figureName, MDP, pmsRaster);

[rasterSectorTime, rasterXLim] = resolve_sequence_raster_time_config(data_plot, pmsRaster);
fractions = resolve_sequence_epoch_fractions(pmsRaster);
plot_sectors(rasterSectorTime, fractions, pmsRaster.epochLabels, pmsRaster.dst, false);
apply_sequence_figure_x_limits(hfg.(figureName), rasterXLim, [0, 5]);
end

function [rasterSectorTime, rasterXLim] = resolve_sequence_raster_time_config(data_plot, pms)
% Resolve raster-sector support and x-limits, optionally from the sample data.

rasterSectorTime = resolve_sequence_sector_time(pms.rasterSectorTime, 0:0.01:5);
rasterXLim = pms.rasterXLim;

if ~pms.rasterUseDataTime
    return;
end

rasterSectorTime = data_plot.timeSpikes;
if isempty(rasterSectorTime)
    return;
end

if ~isempty(pms.rasterDataTimeMax)
    validIndices = find(rasterSectorTime <= pms.rasterDataTimeMax);
    if ~isempty(validIndices)
        rasterXLim = [rasterSectorTime(validIndices(1)), rasterSectorTime(validIndices(end))];
        return;
    end
end

if isempty(rasterXLim)
    rasterXLim = [rasterSectorTime(1), rasterSectorTime(end)];
end
end

function fractions = resolve_sequence_epoch_fractions(pms)
% Resolve sector widths, defaulting to equal epoch fractions.

if isempty(pms.epochFractions)
    fractions = ones(1, numel(pms.epochLabels)) / numel(pms.epochLabels);
else
    fractions = pms.epochFractions;
end
end

function timeVector = resolve_sequence_sector_time(timeVectorIn, defaultTimeVector)
% Resolve the X support used by plot_sectors.

if isempty(timeVectorIn)
    timeVector = defaultTimeVector;
else
    timeVector = timeVectorIn;
end
end

function apply_sequence_figure_x_limits(hfig, customLimits, defaultLimits)
% Apply x-limits to every axes belonging to one sample figure.

axesHandles = findall(hfig, 'Type', 'axes');
for axisIndex = 1:numel(axesHandles)
    apply_sequence_axis_limits(axesHandles(axisIndex), customLimits, defaultLimits);
end
end

function apply_sequence_axis_limits(ax, customLimits, defaultLimits)
% Apply either custom or fallback x-limits to one axes.

if isempty(customLimits)
    xlim(ax, defaultLimits);
else
    xlim(ax, customLimits);
end
end

function apply_raster_axis_overrides(hfg, figureName, MDP, pms)
% Apply compatibility-mode raster axis tweaks when explicitly requested.

if ~isfield(hfg, figureName)
    return;
end

ax = find_primary_visible_axes(hfg.(figureName));
if isempty(ax)
    return;
end

if pms.matchRasterYLimToPlotter
    nRasterEpochs = infer_plotter_raster_epoch_count(MDP);
    ylim(ax, [0.5, pms.Nnr * (pms.nActions * nRasterEpochs) + 0.5]);
end
chil=get(hfg.(figureName),'Children');
neuLabels=get(chil(2),'Yticklabel');
neuLabels=repelem(neuLabels,pms.Nnr);

labelMatchedYLim = resolve_sequence_raster_y_limits_from_labels(pms,neuLabels);
if ~isempty(labelMatchedYLim)
    ylim(ax, labelMatchedYLim);
end

if ~isempty(pms.rasterYLim)
    ylim(ax, pms.rasterYLim);
end

if ~isempty(pms.rasterYTickLabels)
    tickPositions = get(ax, 'YTick');
    repeatedLabels = repeat_labels_to_length(pms.rasterYTickLabels, numel(tickPositions));
    yticklabels(ax, repeatedLabels);
end

legend(ax, 'off');
end

function ax = find_primary_visible_axes(hfig)
% Return the first visible axes in a figure.

ax = [];
axesHandles = findall(hfig, 'Type', 'axes');
bestScore = -inf;
for axisIndex = 1:numel(axesHandles)
    currentAx = axesHandles(axisIndex);
    if ~strcmp(get(currentAx, 'Visible'), 'on')
        continue;
    end

    score = 0;
    if ~isempty(findall(currentAx, 'Type', 'image'))
        score = score + 100;
    end
    if ~isempty(findall(currentAx, 'Type', 'line'))
        score = score + 10;
    end

    tag = '';
    try
        tag = get(currentAx, 'Tag');
    catch
    end
    if ischar(tag) || isstring(tag)
        if contains(char(tag), 'legend', 'IgnoreCase', true)
            score = score - 1000;
        end
    end

    if score > bestScore
        bestScore = score;
        ax = currentAx;
    end
end
end

function nRasterEpochs = infer_plotter_raster_epoch_count(MDP)
% Match the epoch count used internally by the raster plotter.

if iscell(MDP)
    root = MDP{1};
else
    root = MDP;
end

if isfield(root, 'mdp') && ~isempty(root.mdp) && isfield(root.mdp(1), 'T')
    nRasterEpochs = root.mdp(1).T;
else
    nRasterEpochs = infer_mdp_trial_length(MDP);
end
end

function nEpochs = infer_mdp_trial_length(MDP)
% Infer the number of task epochs from the MDP structure.

if iscell(MDP)
    root = MDP{1};
else
    root = MDP;
end

if isfield(root, 'mdp') && numel(root.mdp) > 1
    nEpochs = numel(root.mdp);
elseif isfield(root, 'mdp') && isfield(root.mdp, 'T')
    nEpochs = root.mdp.T;
elseif isfield(root, 'T')
    nEpochs = root.T;
else
    nEpochs = 3;
end
end

function rasterYLim = resolve_sequence_raster_y_limits_from_labels(pms,levelLabels)
% Reproduce legacy raster cropping by matching neuronLabels() with regexes.

rasterYLim = [];
if isempty(pms.rasterYLabelPatterns)
    return;
end

%labels = neuronLabels([pms.Nnr, pms.Nnr, pms.Nnr]);
%if pm%s.rasterYLabelLevel < 1 || pms.rasterYLabelLevel > numel(labels)
%    return;
%end

%levelLabels = labels{pms.rasterYLabelLevel};
%if ~isempty(pms.rasterReset)
%    levelLabels = apply_sequence_raster_label_reset(levelLabels, pms.rasterReset);
%end
matches = false(size(levelLabels));
for iPattern = 1:numel(pms.rasterYLabelPatterns)
    matches = matches | ~cellfun(@isempty, regexp(levelLabels, pms.rasterYLabelPatterns{iPattern}));
end

shows = find(matches);
if isempty(shows)
    return;
end

rasterYLim = [shows(1) - 0.5, shows(end) + 0.5];
end

function labelsOut = apply_sequence_raster_label_reset(labelsIn, rasterReset)
% Apply the same epoch-index shift used by the raster plotter to neuron labels.

labelsOut = labelsIn;

for iLabel = 1:numel(labelsIn)
    tokens = regexp(labelsIn{iLabel}, '^(.*\()(-?\d+)(\))$', 'tokens', 'once');
    if isempty(tokens)
        continue;
    end

    epochIndex = str2double(tokens{2});
    if isnan(epochIndex)
        continue;
    end

    labelsOut{iLabel} = [tokens{1} num2str(epochIndex + rasterReset) tokens{3}];
end
end

function labelsOut = repeat_labels_to_length(labelsIn, nLabels)
% Repeat a short label list until it matches the requested length.

if isempty(labelsIn) || nLabels <= 0
    labelsOut = {};
    return;
end

labelsIn = labelsIn(:);
repeatCount = ceil(nLabels / numel(labelsIn));
labelsOut = repmat(labelsIn, repeatCount, 1);
labelsOut = labelsOut(1:nLabels);
end

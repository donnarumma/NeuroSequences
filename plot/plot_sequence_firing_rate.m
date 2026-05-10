function [hfg, figureName] = plot_sequence_firing_rate(hfg, data_trials, MDP, sampleIndex, pms)
%PLOT_SEQUENCE_FIRING_RATE Render the firing-rate panel for one sample trial.

if nargin < 5 || isempty(pms)
    pms = plot_sequence_firing_rateParams();
else
    pms = plot_sequence_firing_rateParams(pms);
end

data_plot = data_trials(sampleIndex);

if pms.scaleFiringRateTimeByEpochs
    data_plot.tPopFR = data_plot.tPopFR * max(data_plot.extLabEpochs) + pms.firingRateTimeOffset;
else
    data_plot.tPopFR = data_plot.tPopFR + pms.firingRateTimeOffset;
end

pms.dst = pms.dstFiringRate;
pms.trials = sampleIndex;
pms.reduce = false;
if isempty(pms.cmaps)
    nEpochs = infer_mdp_trial_length(MDP);
    cmaps = lines(nEpochs);
    if size(cmaps, 1) >= 5
        cmaps([1, 5:end], :) = [];
    end
    pms.cmaps = cmaps;
end

data_plots = data_trials;
data_plots(sampleIndex) = data_plot;
hfg = feval(pms.firingRatePlotter, hfg, data_plots, MDP, pms);

Xtime = resolve_sequence_sector_time(pms.firingRateSectorTime, 1:0.01:6);
fractions = resolve_sequence_epoch_fractions(pms);
if ~isempty(pms.epochLabels)
    plot_sectors(Xtime, fractions, pms.epochLabels, pms.dst, true);
end
apply_sequence_axis_limits(gca, pms.firingRateXLim, [-0.1, 5.15]);
try 
    title (['Firing Rate: ' data_plot.trialLabel(1:end-1)]); 
catch 
end
figureName = ['FiringRate_Trial' num2str(sampleIndex) pms.imnm];
hLegend = findobj(hfg.(figureName), 'Type', 'Legend');
set(gca, 'fontsize', 24);
set(hfg.(figureName), 'OuterPosition', [0, 0, 1000, 950]);
if ~isempty(hLegend)
    set(hLegend, 'location', 'northoutside', 'Orientation', 'horizontal');
    hLegend.NumColumns = resolve_sequence_firing_rate_legend_columns(hLegend, pms);
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

function fractions = resolve_sequence_epoch_fractions(pms)
% Resolve sector widths, defaulting to equal epoch fractions.

if isempty(pms.epochFractions)
    fractions = ones(1, numel(pms.epochLabels)) / numel(pms.epochLabels);
else
    fractions = pms.epochFractions;
end
end

function apply_sequence_axis_limits(ax, customLimits, defaultLimits)
% Apply either custom or fallback x-limits to a sample subplot.

if isempty(customLimits)
    xlim(ax, defaultLimits);
else
    xlim(ax, customLimits);
end
end

function numColumns = resolve_sequence_firing_rate_legend_columns(hLegend, pms)
% Choose a compact legend layout while preserving the historical six-column default.

if ~isempty(pms.firingRateLegendNumColumns)
    numColumns = pms.firingRateLegendNumColumns;
    return;
end

legendEntries = hLegend.String;
if ischar(legendEntries)
    legendEntries = cellstr(legendEntries);
end

numColumns = min(6, numel(legendEntries));
if isempty(numColumns) || numColumns < 1
    numColumns = 1;
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

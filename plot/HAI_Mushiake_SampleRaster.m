function hfg = HAI_Mushiake_SampleRaster(hfg, data_trials, MDP, par)
%HAI_MUSHIAKE_SAMPLERASTER Reproduce the legacy Mushiake raster layout.

salpha      = 0.1;
nla         = 0.05;
trials      = par.trials;
ifplot      = par.ifplot;
actions     = par.actions;
iFactor     = par.iFactor;

if ~isfield(par, 'imnm') || isempty(par.imnm)
    par.imnm = '';
end

sampleTrial = trials(1);
if isfield(par, 'Nnr') && ~isempty(par.Nnr)
    Nnr = par.Nnr;
else
    Nnr = size(data_trials(sampleTrial).Spikes, 1) / size(data_trials(sampleTrial).popFR, 1);
end

for iTrial = trials
    if iscell(MDP)
        root = MDP{1};
    else
        root = MDP;
    end

    MDP_Low = root.mdp;
    nSymbols = length(MDP_Low.D{iFactor});
    Xtime = data_trials(iTrial).timeSpikes;
    SpvalRaw = ~data_trials(iTrial).Spikes;
    SpikesRaw = data_trials(iTrial).Spikes;
    [Xtime, SpvalRaw, SpikesRaw, rasterEpochs] = crop_initial_raster_epochs(Xtime, SpvalRaw, SpikesRaw, data_trials(iTrial), par);
    nPopsRaw = size(SpvalRaw, 1) / Nnr;
    populationActionIds     = mod(0:nPopsRaw - 1, nSymbols) + 1;
    populationEpochIndices  = floor((0:nPopsRaw - 1) / nSymbols) + 1;
    populationActionLabels  = actions(populationActionIds);
    if isfield(par, 'rasterMuteActions') && ~isempty(par.rasterMuteActions)
        mutePopulationMask = ismember(populationActionLabels, par.rasterMuteActions);
        muteNeuronMask = kron(mutePopulationMask, ones(1, Nnr)) > 0;
        muteTimeMask = true(1, size(SpikesRaw, 2));
        if isfield(par, 'rasterMuteEpochIndices') && ~isempty(par.rasterMuteEpochIndices) && ...
                ~isempty(rasterEpochs) && numel(rasterEpochs) == size(SpikesRaw, 2)
            muteTimeMask = ismember(rasterEpochs, par.rasterMuteEpochIndices);
        end
        if any(muteTimeMask) && any(~muteTimeMask)
            targetTimes = find(muteTimeMask);
            sourceTimes = find(~muteTimeMask);
            sourceTimes = sourceTimes(mod(0:numel(targetTimes) - 1, numel(sourceTimes)) + 1);
            SpikesRaw(muteNeuronMask, targetTimes) = SpikesRaw(muteNeuronMask, sourceTimes);
            SpvalRaw(muteNeuronMask, targetTimes) = ~SpikesRaw(muteNeuronMask, targetTimes);
        else
            SpikesRaw(muteNeuronMask, muteTimeMask) = false;
            SpvalRaw(muteNeuronMask, muteTimeMask) = true;
        end
    end
    keepPopulationMask      = ismember(populationActionLabels, par.rasterKeepActions);
    populationEpochIndices  = populationEpochIndices + par.reset;
    keepPopulationMask      = keepPopulationMask & ismember(populationEpochIndices, par.rasterKeepEpochIndices);
    keepNeuronMask          = kron(keepPopulationMask, ones(1, Nnr)) > 0;
    Spval                   = SpvalRaw(keepNeuronMask, :);
    Spvls                   = SpikesRaw(keepNeuronMask, :);
    nPops                   = size(Spval, 1) / Nnr;
    YNlab                   = 1:nPops * Nnr;
    shownActionLabels       = populationActionLabels(keepPopulationMask);
    shownEpochIndices       = populationEpochIndices(keepPopulationMask);
    shownSymbols            = numel(unique(par.rasterKeepActions));
    shownEpochs             = unique(shownEpochIndices, 'stable');
    % plot raster
    imnm                    = ['RasterTrial' num2str(iTrial) par.imnm];
    hfg.(imnm)              = figure('Visible', ifplot);
    if isempty(Xtime) || isempty(Spval) || isempty(YNlab) || isempty(shownEpochs)
        warning('HAI_Mushiake_SampleRaster:EmptyRasterPayload', ...
            ['Skipping raster drawing for trial %d because no valid time bins or ' ...
             'populations remain after filtering/cropping.'], iTrial);
        axis off;
        text(0.5, 0.5, sprintf('No raster data available for trial %d', iTrial), ...
            'Units', 'normalized', ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', 16, ...
            'Interpreter', 'none');
        continue;
    end
    hold on; imagesc(Xtime, YNlab, Spval); colormap gray;

    if isfield(par, 'rasterTitle') && ~isempty(par.rasterTitle)
        titleInterpreter = 'none';
        if isfield(par, 'rasterTitleInterpreter') && ~isempty(par.rasterTitleInterpreter)
            titleInterpreter = par.rasterTitleInterpreter;
        end
        title(par.rasterTitle, 'FontSize', 16, 'Interpreter', titleInterpreter);
    else
        title(['Unit firing ' resolve_raster_policy_string(MDP_Low, actions, par)], 'FontSize', 16);
    end
    xlabel('time [s]', 'FontSize', 12);
    ylabel('Population Coding');
    grid on;

    allyticks               = YNlab((1:Nnr:end)) + (Nnr - 1) / 2;
    set(gca, 'YTick', allyticks);
    if ~isempty(allyticks)
        HN = yline(allyticks);
        set(HN, 'alpha', nla);
    end

    nEpochs = numel(shownEpochs);
    rowsPerEpoch = shownSymbols * Nnr;
    rowEdges = (0:rowsPerEpoch:nEpochs * rowsPerEpoch) + 0.5;

    set(gca, 'YDir', 'reverse');
    ylim([YNlab(1) - 0.5, YNlab(end) + 0.5]);

    set(gca, 'FontSize', 16);
    set(hfg.(imnm), 'PaperPositionMode', 'auto');
    set(hfg.(imnm), 'Position', [0, 0, 1200, 1200]);

    istart = rowEdges(1);
    nLegends = nEpochs;
    stepcmaps = lines(length(rowEdges));
    stepcmaps =stepcmaps(-par.reset+1:end, :);
    stepcmaps = resolve_mushiake_raster_step_colors(stepcmaps, par);
    for iy = 1:nLegends
        iend = rowEdges(iy + 1);
        draw_mushiake_raster_background( ...
            Xtime, istart, iend, iy, shownSymbols, Nnr, shownActionLabels, ...
            actions, stepcmaps(iy, :), salpha, par);
        wdwNeu = ceil(istart:iend - 1);
        wdwNeu = wdwNeu(wdwNeu >= 1 & wdwNeu <= size(Spvls, 1));
        for iNeuron = 1:length(wdwNeu)
            spikeColor = resolve_mushiake_raster_spike_color( ...
                wdwNeu(iNeuron), Nnr, shownActionLabels, actions, stepcmaps(iy, :), par);
            neuSpkTimes = Xtime(logical(Spvls(wdwNeu(iNeuron), :)));
            for iTime = 1:length(neuSpkTimes)
                plot([neuSpkTimes(iTime), neuSpkTimes(iTime)], ...
                    [wdwNeu(iNeuron) - 0.4, wdwNeu(iNeuron) + 0.4], ...
                    'Color', spikeColor, 'LineWidth', 1.5);
            end
        end
        istart = iend;
    end

    nActionsRep = numel(shownActionLabels);
    yticks((0.5 + (Nnr / 2)):Nnr:nActionsRep * Nnr);
    labneurons = shownActionLabels;
    appendEpochIndex = ~isfield(par, 'rasterAppendEpochIndex') || par.rasterAppendEpochIndex;
    if appendEpochIndex
        icounter = 0;
        startEpochIndex = 1;
        if isfield(par, 'rasterStartEpochIndex') && ~isempty(par.rasterStartEpochIndex)
            startEpochIndex = par.rasterStartEpochIndex;
        end
        for iLabel = 1:numel(labneurons)
            icounter = icounter + 1;
            epochPosition = floor((iLabel - 1) / shownSymbols) + 1;
            if isfield(par, 'rasterUseOrdinalEpochLabels') && par.rasterUseOrdinalEpochLabels
                epochIndex = startEpochIndex + epochPosition - 1;
            else
                epochIndex = shownEpochs(min(epochPosition, numel(shownEpochs)));
            end
            if isfield(par, 'rasterOmitZeroEpochSuffix') && par.rasterOmitZeroEpochSuffix && epochIndex == 0
                continue;
            end
            labneurons{icounter} = [labneurons{icounter} '(' num2str(epochIndex) ')'];
        end
    end
    yticklabels(labneurons);

    xlim([floor(Xtime(1)), Xtime(end)]);
    ylim([YNlab(1) - 0.5, YNlab(end) + 0.5]);
    if isfield(par, 'rasterVisibleEpochCount') && ~isempty(par.rasterVisibleEpochCount)
        visibleStart = 1;
        if isfield(par, 'rasterVisibleEpochStart') && ~isempty(par.rasterVisibleEpochStart)
            visibleStart = max(1, round(par.rasterVisibleEpochStart));
        end
        visibleStart = min(visibleStart, max(1, nEpochs));
        visibleEpochs = max(1, min(nEpochs, round(par.rasterVisibleEpochCount)));
        visibleEnd = min(nEpochs, visibleStart + visibleEpochs - 1);
        ylim([(visibleStart - 1) * rowsPerEpoch + 0.5, visibleEnd * rowsPerEpoch + 0.5]);
    end
    legend off;
    set(gca, 'FontSize', 30);
    if isfield(par, 'rasterYTickFontSize') && ~isempty(par.rasterYTickFontSize)
        ax = gca;
        ax.YAxis.FontSize = par.rasterYTickFontSize;
    end
    set(hfg.(imnm), 'PaperPositionMode', 'auto');
    if isfield(par, 'rasterFigurePosition') && ~isempty(par.rasterFigurePosition)
        set(hfg.(imnm), 'Position', par.rasterFigurePosition);
    else
        set(hfg.(imnm), 'Position', [0, 0, 1000, 1000]);
    end
end
end

function [Xtime, SpvalRaw, SpikesRaw, rasterEpochs] = crop_initial_raster_epochs(Xtime, SpvalRaw, SpikesRaw, data_trial, par)
% Optionally crop a number of initial epochs from the raster time axis only.

rasterEpochs = [];
if ~isfield(data_trial, 'extLabEpochs') || isempty(data_trial.extLabEpochs)
    return;
end

extLabEpochs = data_trial.extLabEpochs;
if numel(extLabEpochs) ~= numel(Xtime)
    return;
end
rasterEpochs = extLabEpochs;

keepMask = true(size(extLabEpochs));

if isfield(par, 'rasterSkipInitialEpochs') && ~isempty(par.rasterSkipInitialEpochs) && ...
        par.rasterSkipInitialEpochs > 0
    keepMask = keepMask & extLabEpochs >= par.rasterSkipInitialEpochs;
end

if isfield(par, 'rasterDropEpochIndices') && ~isempty(par.rasterDropEpochIndices)
    keepMask = keepMask & ~ismember(extLabEpochs, par.rasterDropEpochIndices);
end

if ~any(keepMask)
    return;
end

Xtime = Xtime(keepMask);
SpvalRaw = SpvalRaw(:, keepMask);
SpikesRaw = SpikesRaw(:, keepMask);
rasterEpochs = rasterEpochs(keepMask);
end

function stepcmaps = resolve_mushiake_raster_step_colors(stepcmaps, par)
% Optionally remap the displayed sector colors for zero-indexed Mushiake rasters.

if ~isfield(par, 'rasterZeroIndexedStepColors') || ~par.rasterZeroIndexedStepColors
    return;
end

if size(stepcmaps, 1) >= 5
    stepcmaps(1:5, :) = stepcmaps([4, 1, 2, 3, 5], :);
elseif size(stepcmaps, 1) >= 4
    stepcmaps(1:4, :) = stepcmaps([4, 1, 2, 3], :);
end
end

function draw_mushiake_raster_background(Xtime, yStart, yEnd, iEpoch, shownSymbols, Nnr, shownActionLabels, actions, defaultColor, salpha, par)
% Draw either one epoch block or per-population background strips.

if ~isfield(par, 'rasterColorMode') || ~strcmpi(par.rasterColorMode, 'action')
    hBg = fill([Xtime(1), Xtime(1), Xtime(end), Xtime(end)], ...
        [yStart, yEnd, yEnd, yStart], defaultColor);
    set(hBg, 'facealpha', salpha);
    return;
end

epochLabelStart = (iEpoch - 1) * shownSymbols + 1;
epochLabelEnd = min(iEpoch * shownSymbols, numel(shownActionLabels));
for iLabel = epochLabelStart:epochLabelEnd
    rowOffset = iLabel - epochLabelStart;
    stripStart = yStart + rowOffset * Nnr;
    stripEnd = min(stripStart + Nnr, yEnd);
    bgColor = resolve_mushiake_label_color(shownActionLabels{iLabel}, actions, defaultColor, par);
    hBg = fill([Xtime(1), Xtime(1), Xtime(end), Xtime(end)], ...
        [stripStart, stripEnd, stripEnd, stripStart], bgColor, ...
        'EdgeColor', 'none');
    set(hBg, 'facealpha', salpha);
end
end

function spikeColor = resolve_mushiake_raster_spike_color(rowIndex, Nnr, shownActionLabels, actions, defaultColor, par)
% Resolve per-population spike colours while keeping epoch backgrounds intact.

spikeColor = defaultColor;
if ~isfield(par, 'rasterColorMode') || ~strcmpi(par.rasterColorMode, 'action')
    return;
end

populationIndex = ceil(rowIndex / Nnr);
if populationIndex < 1 || populationIndex > numel(shownActionLabels)
    return;
end

actionIndex = find(strcmp(actions, shownActionLabels{populationIndex}), 1, 'first');
if isempty(actionIndex)
    return;
end

spikeColor = resolve_mushiake_label_color(shownActionLabels{populationIndex}, actions, defaultColor, par);
end

function labelColor = resolve_mushiake_label_color(label, actions, defaultColor, par)
% Resolve the colour associated with one displayed population/action label.

labelColor = defaultColor;
actionIndex = find(strcmp(actions, label), 1, 'first');
if isempty(actionIndex)
    return;
end

if isfield(par, 'rasterCmaps') && ~isempty(par.rasterCmaps)
    cmaps = par.rasterCmaps;
else
    cmaps = lines(numel(actions));
end
labelColor = cmaps(min(actionIndex, size(cmaps, 1)), :);
end

function policyString = resolve_raster_policy_string(MDP_Low, actions, par)
% Build the raster policy title with optional stay suppression.

if isfield(par, 'policyActions') && ~isempty(par.policyActions)
    policySource = par.policyActions;
else
    policySource = actions;
end

policyActions = policySource(MDP_Low.s(2, 2:end));
showStay = isfield(par, 'rasterShowStayInTitle') && par.rasterShowStayInTitle;
if ~showStay
    policyActions = policyActions(~strcmp(policyActions, 'S'));
end
policyString = strjoin(policyActions, '');
end

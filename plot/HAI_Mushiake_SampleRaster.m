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
    nPopsRaw = size(SpvalRaw, 1) / Nnr;
    populationActionIds     = mod(0:nPopsRaw - 1, nSymbols) + 1;
    populationEpochIndices  = floor((0:nPopsRaw - 1) / nSymbols) + 1;
    populationActionLabels  = actions(populationActionIds);
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
    hold on; imagesc(Xtime, YNlab, Spval); colormap gray;

    title(['Unit firing ' resolve_raster_policy_string(MDP_Low, actions, par)], 'FontSize', 16);
    xlabel('time [s]', 'FontSize', 12);
    ylabel('Population Coding');
    grid on;

    allyticks               = YNlab((1:Nnr:end)) + (Nnr - 1) / 2;
    set(gca, 'YTick', allyticks);
    HN                      = yline(allyticks);
    set(HN, 'alpha', nla);

    nEpochs = numel(shownEpochs);
    nBins = sum(data_trials(iTrial).labEpochs == 1);
    tlines = (0:shownSymbols * Nnr:nEpochs * shownSymbols * Nnr) + 0.5;
    ylines = (0:shownSymbols * nBins:nEpochs * shownSymbols * nBins) + 0.5;

    set(gca, 'YDir', 'reverse');
    ylim([YNlab(1) - 0.5, YNlab(end) + 0.5]);

    set(gca, 'FontSize', 16);
    set(hfg.(imnm), 'PaperPositionMode', 'auto');
    set(hfg.(imnm), 'Position', [0, 0, 1200, 1200]);

    istart = ylines(1);
    nLegends = nEpochs;
    H = gobjects(nLegends, 1);
    stepcmaps = lines(length(ylines));
    stepcmaps =stepcmaps(-par.reset+1:end, :);
    for iy = 1:nLegends
        iend = tlines(iy + 1);
        H(iy) = fill([Xtime(1), Xtime(1), Xtime(end), Xtime(end)], ...
            [istart, iend, iend, istart], stepcmaps(iy, :));
        wdwNeu = ceil(istart:iend - 1);
        for iNeuron = 1:length(wdwNeu)
            neuSpkTimes = Xtime(logical(Spvls(wdwNeu(iNeuron), :)));
            for iTime = 1:length(neuSpkTimes)
                plot([neuSpkTimes(iTime), neuSpkTimes(iTime)], ...
                    [wdwNeu(iNeuron) - 0.4, wdwNeu(iNeuron) + 0.4], ...
                    'Color', stepcmaps(iy, :), 'LineWidth', 1.5);
            end
        end
        istart = iend;
        set(H(iy), 'facealpha', salpha);
    end

    nActionsRep = numel(shownActionLabels);
    yticks((0.5 + (Nnr / 2)):Nnr:nActionsRep * Nnr);
    labneurons = shownActionLabels;
    icounter = 0;
    for iLabel = 1:numel(labneurons)
        icounter = icounter + 1;
        epochPosition = floor((iLabel - 1) / shownSymbols) + 1;
        epochIndex = shownEpochs(min(epochPosition, numel(shownEpochs)));
        labneurons{icounter} = [labneurons{icounter} '(' num2str(epochIndex) ')'];
    end
    yticklabels(labneurons);

    xlim([floor(Xtime(1)), Xtime(end)]);
    ylim([YNlab(1) - 0.5, YNlab(end) + 0.5]);
    legend off;
    set(gca, 'FontSize', 30);
    set(hfg.(imnm), 'PaperPositionMode', 'auto');
    set(hfg.(imnm), 'Position', [0, 0, 1000, 1000]);
end
end

function policyString = resolve_raster_policy_string(MDP_Low, actions, par)
% Build the raster policy title with optional stay suppression.

policyActions = actions(MDP_Low.s(2, 2:end));
showStay = isfield(par, 'rasterShowStayInTitle') && par.rasterShowStayInTitle;
if ~showStay
    policyActions = policyActions(~strcmp(policyActions, 'S'));
end
policyString = strjoin(policyActions, '');
end

function [hfg, results] = BETA_pcaSpace(data_trials, pms)
%BETA_PCASPACE Generic PCA analysis for collected sequence experiments.
%
% INPUTS
%   sourcePath   path to either:
%                - a collected MAT file containing data_trials, or
%                - an experiment directory containing a Collect_* file
%   pms          optional analysis parameters; defaults come from
%                BETA_pcaSpaceParams
%
% OUTPUTS
%   hfg          struct containing figure handles created by the analysis
%   results      struct containing beta weights, PCA projections and
%                intermediate tensors

if nargin < 2 || isempty(pms)
    pms = BETA_pcaSpaceParams();
else
    pms = BETA_pcaSpaceParams(pms);
end

hfg = struct();
results = struct();

if isempty(data_trials)
    error('%s:NoTrialsLoaded', mfilename, ...
        'No trial data could be loaded from %s.', sourcePath);
end

if ~isempty(pms.trialIndices)
    data_trials = data_trials(pms.trialIndices);
end

%rng(10);

%data_trials             = build_beta_spikes(data_trials, pms);
[windows, timeVector]   = build_beta_windows(data_trials, pms);
data_trials             = add_beta_window_means(data_trials, windows, pms);

[types, sps]            = build_beta_tensors(data_trials, pms);
[betaWeights, resCorr]  = regress_and_project_beta(sps, types, pms);

testDir                 = pms.saveFiguresDir;
figureSuffix            = build_beta_figure_suffix(testDir, data_trials, pms);
hfg                     = plot_beta_spaces(hfg, betaWeights, resCorr, data_trials, timeVector, pms, figureSuffix);

results.data_trials = data_trials;
results.Windows = windows;
results.Time = timeVector;
results.types = types;
results.sps = sps;
results.beta = betaWeights;
results.resCorr = resCorr;
end

function [testDir, collectedFile] = resolve_beta_source(sourcePath)
% Resolve input into a directory plus an optional collected MAT file.

if isfolder(sourcePath)
    testDir = ensure_trailing_filesep(sourcePath);
    collectedFile = find_latest_collected_file(testDir);
    return;
end

if isfile(sourcePath)
    testDir = ensure_trailing_filesep(fileparts(sourcePath));
    collectedFile = sourcePath;
    return;
end

error('%s:InvalidSource', mfilename, ...
    'Input must be an existing directory or file: %s', sourcePath);
end

function collectedFile = find_latest_collected_file(testDir)
% Prefer collected data_trials files.

patterns = {'Collect_Sensor_Results*.mat', 'Collect_Trial_Results*.mat', 'Collect_SEQUENCES_RESULTS*.mat', 'Collect*.mat'};

for patternIndex = 1:numel(patterns)
    matches = dir(fullfile(testDir, patterns{patternIndex}));
    if ~isempty(matches)
        [~, latestIndex] = max([matches.datenum]);
        collectedFile = fullfile(matches(latestIndex).folder, matches(latestIndex).name);
        return;
    end
end

collectedFile = '';
end

function data_trials = load_beta_trials(testDir, collectedFile, pms)
% Load trials from a collected file.

data_trials = struct([]);

if isempty(collectedFile)
    error('%s:MissingCollectFile', mfilename, ...
        'No Collect_* file found in %s.', testDir);
end

Res = load(collectedFile);
fprintf('Loading PCA data in %s...\n', collectedFile);

if ~isfield(Res, 'data_trials')
    error('%s:InvalidCollectFile', mfilename, ...
        'Collect file %s does not contain data_trials.', collectedFile);
end

data_trials = Res.data_trials;
for iTrial = 1:numel(data_trials)
    data_trials(iTrial).sourceTrialIndex = iTrial;
end
end

function data_trials = normalise_trial_names(data_trials, pms)
% Trim trial names to the symbolic sequence suffix used in analysis.

for iTrial = 1:numel(data_trials)
    trialName = data_trials(iTrial).trialName;
    keepCount = min(numel(trialName), pms.trialNameTailLength);
    data_trials(iTrial).trialName = trialName(end - keepCount + 1:end);
end
end

function data_trials = extend_beta_firing_rates(data_trials, pms)
% Extend firing rates to the requested neuron multiplicity.

labEpochs = data_trials(1).labEpochs;
nBins = sum(labEpochs == 1);
    Nev = pms.Nev;
    if isempty(Nev)
        Nev = ones(1, pms.nLength);
    end

for iTrial = 1:numel(data_trials)
    FR = data_trials(iTrial).popFR;
    [FR, tFR, extLabEpochs] = HAI_extendFiringRates(FR, nBins, pms.Nnr, Nev, pms.dt);
    data_trials(iTrial).firingRates = FR;
    data_trials(iTrial).timeFiringRates = pms.nLength * tFR / tFR(end);
    data_trials(iTrial).extLabEpochs = extLabEpochs;
end
end

function data_trials = add_beta_trial_types(data_trials, pms)
% Build one-hot encodings for the symbolic trial labels.

cats = 1:numel(pms.catNames);
tbasis = onehotencode(categorical(cats)', 2);
nSteps = resolve_beta_type_step_count(data_trials, pms);

for iTrial = 1:numel(data_trials)
    ctbasis = [];
    for indLab = 1:nSteps
        tname = data_trials(iTrial).trialName(indLab);
        ind = find(ismember(pms.catNames, tname), 1);
        data_trials(iTrial).(['type' num2str(indLab)]) = tbasis(ind, :);
        ctbasis = [ctbasis, tbasis(ind, :)]; %#ok<AGROW>
    end
    data_trials(iTrial).type = ctbasis;
end
end

function data_trials = build_beta_spikes(data_trials, pms)
% Convert extended firing rates into cosine-tuned spike trains.

for iTrial = 1:numel(data_trials)
    labs = neuronLabels([pms.Nnr, pms.Nnr, pms.Nnr]);
    matches = false(size(labs{2}));
    matches = matches | ~cellfun(@isempty, regexp(labs{2}, '\(1\)$'));
    matches = matches | ~cellfun(@isempty, regexp(labs{2}, '\(2\)$'));
    matches = matches | ~cellfun(@isempty, regexp(labs{2}, '\(3\)$'));

    labsPopFR = neuronLabels([1, 1, 1]);
    matchesPopFR = false(size(labsPopFR{2}));
    matchesPopFR = matchesPopFR | ~cellfun(@isempty, regexp(labsPopFR{2}, '\(1\)$'));
    matchesPopFR = matchesPopFR | ~cellfun(@isempty, regexp(labsPopFR{2}, '\(2\)$'));
    matchesPopFR = matchesPopFR | ~cellfun(@isempty, regexp(labsPopFR{2}, '\(3\)$'));

    data_trials(iTrial).popFR = data_trials(iTrial).popFR(matchesPopFR, :);
    data_trials(iTrial).firingRates = data_trials(iTrial).firingRates(matches, :);
    data_trials(iTrial).neuronLabels = labs{2}(matches);
    data_trials(iTrial).neuronLabelsFR = labsPopFR{2}(matchesPopFR);

    FR = data_trials(iTrial).firingRates;
    [~, nTimes] = size(FR);
    popFRcosine = nan(size(FR));
    percSide = (1 - pms.percCenter) / 2;

    for iTime = 1:nTimes
        popFRcosine(:, iTime) = cosineTuning(FR(:, iTime), ...
            data_trials(iTrial).type, pms.percCenter, percSide);
    end

    data_trials(iTrial).popFRcosine = popFRcosine;
    data_trials(iTrial).timepopFRcosine = data_trials(iTrial).timeFiringRates;
    data_trials(iTrial).Spikes = HAI_fireToSpikes(popFRcosine, ...
        pms.cap, pms.th, pms.SpT);
    data_trials(iTrial).timeSpikes = data_trials(iTrial).timeFiringRates;
end
end

function [windows, timeVector] = build_beta_windows(data_trials, pms)
% Build sliding windows over the chosen signal timeline.

timeVector = 1:length(data_trials(1).timeFiringRates);
windowLength = pms.Wlength;
if isempty(windowLength) || ~isfinite(windowLength)
    windowLength = length(timeVector);
end
windowLength = min(windowLength, length(timeVector));
if windowLength < 1
    error('%s:InvalidWindowLength', mfilename, ...
        'Wlength must be at least 1.');
end

step = max(1, windowLength - pms.overlap);
startIndices = 1:step:(length(timeVector) - windowLength + 1);
nWindows = length(startIndices);
windows = zeros(nWindows, windowLength);

for iWindow = 1:nWindows
    windows(iWindow, :) = timeVector(startIndices(iWindow):startIndices(iWindow) + windowLength - 1);
end
end

function data_trials = add_beta_window_means(data_trials, windows, pms)
% Compute trial-window averages for the chosen signal.

signalField = pms.signalName;
nCats = numel(pms.catNames);
cats = 1:nCats;
tbasis = onehotencode(categorical(cats)', 2);
nSteps = resolve_beta_type_step_count(data_trials, pms);

for iTrial = 1:numel(data_trials)
    signalTime = resolve_beta_signal_time(data_trials(iTrial), signalField);
    for iWindow = 1:size(windows, 1)
        data_trials(iTrial).(['m' signalField])(:, iWindow) = ...
            mean(data_trials(iTrial).(signalField)(:, windows(iWindow, :)), 2);
        data_trials(iTrial).(['timem' signalField])(:, iWindow) = ...
            mean(signalTime(:, windows(iWindow, :)), 2);
    end
    ctbasis = [];
    for indLab = 1:nSteps
        tname = data_trials(iTrial).trialName(indLab);
        ind = find(ismember(pms.catNames, tname), 1);
        data_trials(iTrial).(['type' num2str(indLab)]) = tbasis(ind, :);
        ctbasis = [ctbasis, tbasis(ind, :)]; %#ok<AGROW>
    end
    data_trials(iTrial).type = ctbasis;
end
end

function signalTime = resolve_beta_signal_time(data_trial, signalField)
% Resolve the time vector associated with one analysis signal.

requestedField = ['time' signalField];
if isfield(data_trial, requestedField) && ~isempty(data_trial.(requestedField))
    signalTime = data_trial.(requestedField);
    return;
end

if any(strcmp(signalField, {'firingRates', 'popFRcosine'})) && ...
        isfield(data_trial, 'timeFiringRates') && ~isempty(data_trial.timeFiringRates)
    signalTime = data_trial.timeFiringRates;
    return;
end

if strcmp(signalField, 'Spikes') && ...
        isfield(data_trial, 'timeSpikes') && ~isempty(data_trial.timeSpikes)
    signalTime = data_trial.timeSpikes;
    return;
end

candidateFields = {'timeFiringRates', 'timeSpikes'};
signalLength = size(data_trial.(signalField), 2);

for iField = 1:numel(candidateFields)
    candidate = candidateFields{iField};
    if ~isfield(data_trial, candidate) || isempty(data_trial.(candidate))
        continue;
    end

    candidateTime = data_trial.(candidate);
    if size(candidateTime, 2) == signalLength
        signalTime = candidateTime;
        return;
    end
end

error('%s:MissingSignalTime', mfilename, ...
    'No time field found for signal %s.', signalField);
end

function [types, sps] = build_beta_tensors(data_trials, pms)
% Assemble regression tensors across trials, neurons and windows.

types = cat(3, data_trials.type);
types = permute(types, [3, 2, 1]);

nTrials = numel(data_trials);
nNeurons = size(data_trials(1).(['m' pms.signalName]), 1);
nWindows = size(data_trials(1).(['m' pms.signalName]), 2);
sps = nan(nTrials, nNeurons, nWindows);

for iTrial = 1:nTrials
    data_trials(iTrial).sps = data_trials(iTrial).(['m' pms.signalName]);
    sps(iTrial, :, :) = data_trials(iTrial).sps;
end
end

function [betaWeights, resCorr] = regress_and_project_beta(sps, types, pms)
% Regress category encodings and run PCA on each time-step subspace.

nTrials = size(sps, 1);
nNeurons = size(sps, 2);
nWindows = size(sps, 3);
nCats = numel(pms.catNames);
nSteps = size(types, 2) / nCats;

betaWeights = nan(nNeurons, nCats * nSteps, nWindows);
for iNeuron = 1:nNeurons
    fprintf('Regress neuron %g/%g\n', iNeuron, nNeurons);
    for iWindow = 1:nWindows
        betaWeights(iNeuron, :, iWindow) = regress(sps(:, iNeuron, iWindow), types);
    end
end

resCorr = cell(nSteps, nWindows);
for iStep = 1:nSteps
    indCorr = (1:nCats) + nCats * (iStep - 1);
    neuronIndices = resolve_beta_pca_neuron_indices(iStep, nSteps, nCats, nNeurons, pms);
    for iWindow = 1:nWindows
        Beta = betaWeights(neuronIndices, indCorr, iWindow)';
        Beta = normalize_beta_matrix_for_pca(Beta, pms);
        [Wpca, Zpca, latent, ~, expl] = pca(Beta);
        resCorr{iStep, iWindow}.Wpca = Wpca;
        resCorr{iStep, iWindow}.expl = expl;
        resCorr{iStep, iWindow}.Zpca = Zpca;
        resCorr{iStep, iWindow}.latent = latent;
        resCorr{iStep, iWindow}.flipSigns = ones(1, size(Zpca, 2));
        resCorr{iStep, iWindow}.neuronIndices = neuronIndices;
        resCorr{iStep, iWindow}.fullNeuronCount = nNeurons;
    end
end

if pms.pcaAutoFlip
    resCorr = auto_flip_beta_pca_results(resCorr);
end

fprintf('Regression/PCA completed for %d trials.\n', nTrials);
end

function neuronIndices = resolve_beta_pca_neuron_indices(iStep, nSteps, nCats, nNeurons, pms)
% Resolve the neuron subset used for PCA at each symbolic step.

mode = 'all';
if isfield(pms, 'pcaNeuronSelectionMode') && ~isempty(pms.pcaNeuronSelectionMode)
    mode = lower(strtrim(char(pms.pcaNeuronSelectionMode)));
end

switch mode
    case 'all'
        neuronIndices = 1:nNeurons;

    case 'matched_step_blocks'
        startIndex = (iStep - 1) * nCats + 1;
        endIndex = iStep * nCats;
        if endIndex > nNeurons
            error('%s:InvalidMatchedStepBlocks', mfilename, ...
                ['matched_step_blocks requires at least %d neurons for %d steps ' ...
                 'with %d categories, but only %d are available.'], ...
                nSteps * nCats, nSteps, nCats, nNeurons);
        end
        neuronIndices = startIndex:endIndex;

    case 'custom'
        if ~isfield(pms, 'pcaNeuronBlocks') || isempty(pms.pcaNeuronBlocks)
            error('%s:MissingPcaNeuronBlocks', mfilename, ...
                'pcaNeuronBlocks must be provided when pcaNeuronSelectionMode is ''custom''.');
        end
        if ~iscell(pms.pcaNeuronBlocks)
            error('%s:InvalidPcaNeuronBlocks', mfilename, ...
                'pcaNeuronBlocks must be a cell array, with one neuron-index vector per step.');
        end
        if iStep > numel(pms.pcaNeuronBlocks)
            error('%s:MissingPcaNeuronBlockStep', mfilename, ...
                'No custom neuron block defined for step %d.', iStep);
        end
        neuronIndices = pms.pcaNeuronBlocks{iStep};

    otherwise
        error('%s:InvalidPcaNeuronSelectionMode', mfilename, ...
            ['pcaNeuronSelectionMode must be ''all'', ''matched_step_blocks'', ' ...
             'or ''custom''.']);
end

neuronIndices = unique(neuronIndices(:)', 'stable');
neuronIndices = neuronIndices(neuronIndices >= 1 & neuronIndices <= nNeurons);

if isempty(neuronIndices)
    error('%s:EmptyPcaNeuronSelection', mfilename, ...
        'Neuron selection for step %d is empty.', iStep);
end
end

function BetaOut = normalize_beta_matrix_for_pca(BetaIn, pms)
% Optionally normalize beta coefficients before PCA.

mode = 'none';
if isfield(pms, 'pcaNormalizeBetas') && ~isempty(pms.pcaNormalizeBetas)
    mode = lower(strtrim(char(pms.pcaNormalizeBetas)));
end

switch mode
    case 'none'
        BetaOut = BetaIn;

    case 'zscore'
        sd = std(BetaIn, 0, 1);
        keep = sd > 1e-8;

        if ~any(keep)
            BetaOut = BetaIn;
            return;
        end

        BetaOut = zscore(BetaIn(:, keep), 0, 1);

    otherwise
        error('%s:InvalidPcaNormalizeBetas', mfilename, ...
            'pcaNormalizeBetas must be ''none'' or ''zscore''.');
end
end

function cmaps = resolve_beta_external_cmaps(pms, nColors)
% Resolve external step colors with a safe fallback to MATLAB defaults.

cmaps = [];
if isfield(pms, 'cmaps') && ~isempty(pms.cmaps)
    cmaps = pms.cmaps;
end

if isempty(cmaps)
    cmaps = lines(nColors);
    return;
end

if size(cmaps, 1) < nColors
    fallback = lines(nColors);
    fallback(1:size(cmaps, 1), :) = cmaps;
    cmaps = fallback;
else
    cmaps = cmaps(1:nColors, :);
end
end

function resCorr = auto_flip_beta_pca_results(resCorr)
% Align PCA component signs so symbolic steps share a stable visual orientation.

nSteps = size(resCorr, 1);
nWindows = size(resCorr, 2);

if nSteps < 1 || nWindows < 1
    return;
end

for iWindow = 2:nWindows
    resCorr{1, iWindow} = align_beta_pca_entry_signs( ...
        resCorr{1, iWindow}, resCorr{1, iWindow - 1}, 1, iWindow);
end

for iWindow = 1:nWindows
    referenceEntry = resCorr{1, iWindow};
    for iStep = 2:nSteps
        resCorr{iStep, iWindow} = align_beta_pca_entry_signs( ...
            resCorr{iStep, iWindow}, referenceEntry, iStep, iWindow);
    end
end
end

function resEntry = align_beta_pca_entry_signs(resEntry, referenceEntry, iStep, iWindow)
% Flip PCA signs when they oppose a reference projection.

if ~isfield(resEntry, 'Zpca') || ~isfield(referenceEntry, 'Zpca')
    return;
end

nComponents = min(size(resEntry.Zpca, 2), size(referenceEntry.Zpca, 2));
if nComponents < 1
    return;
end

if ~isfield(resEntry, 'flipSigns') || isempty(resEntry.flipSigns)
    resEntry.flipSigns = ones(1, size(resEntry.Zpca, 2));
end

[resEntry, didRotateSwap] = align_beta_pca_component_order(resEntry, referenceEntry, nComponents);
if didRotateSwap
    fprintf('[BETA auto-flip] rotation swap applied at step %d, window %d\n', iStep, iWindow);
end

for iComponent = 1:nComponents
    alignment = referenceEntry.Zpca(:, iComponent)' * resEntry.Zpca(:, iComponent);
    if alignment < 0
        if size(resEntry.Zpca, 2) >= iComponent
            resEntry.Zpca(:, iComponent) = -resEntry.Zpca(:, iComponent);
        end
        if isfield(resEntry, 'Wpca') && size(resEntry.Wpca, 2) >= iComponent
            resEntry.Wpca(:, iComponent) = -resEntry.Wpca(:, iComponent);
        end
        resEntry.flipSigns(iComponent) = -resEntry.flipSigns(iComponent);
        fprintf('[BETA auto-flip] sign flip applied at step %d, window %d, component %d\n', ...
            iStep, iWindow, iComponent);
    end
end
end

function [resEntry, didRotateSwap] = align_beta_pca_component_order(resEntry, referenceEntry, nComponents)
% Swap the first two PCA axes when the entry is better aligned after a 90-degree rotation.

didRotateSwap = false;

if nComponents < 2
    return;
end

referencePlane = referenceEntry.Zpca(:, 1:2);
entryPlane = resEntry.Zpca(:, 1:2);

directScore = abs(referencePlane(:, 1)' * entryPlane(:, 1)) + ...
    abs(referencePlane(:, 2)' * entryPlane(:, 2));
swappedScore = abs(referencePlane(:, 1)' * entryPlane(:, 2)) + ...
    abs(referencePlane(:, 2)' * entryPlane(:, 1));

if swappedScore <= directScore
    return;
end

swapOrder = [2, 1];
didRotateSwap = true;
resEntry.Zpca(:, 1:2) = resEntry.Zpca(:, swapOrder);
if isfield(resEntry, 'Wpca') && size(resEntry.Wpca, 2) >= 2
    resEntry.Wpca(:, 1:2) = resEntry.Wpca(:, swapOrder);
end
if isfield(resEntry, 'latent') && numel(resEntry.latent) >= 2
    resEntry.latent(1:2) = resEntry.latent(swapOrder);
end
if isfield(resEntry, 'expl') && numel(resEntry.expl) >= 2
    resEntry.expl(1:2) = resEntry.expl(swapOrder);
end
if numel(resEntry.flipSigns) >= 2
    resEntry.flipSigns(1:2) = resEntry.flipSigns(swapOrder);
end
end

function hfg = plot_beta_spaces(hfg, betaWeights, resCorr, data_trials, timeVector, pms, figureSuffix)
% Create the PCA summary figures.

nCats = numel(pms.catNames);
cats = 1:nCats;
nSteps = size(resCorr, 1);
nWindows = size(resCorr, 2);
catNames = pms.catNames;
hm = pms.hm;

ms = 25;
cmaps = linspecer(nCats);

if pms.plotPcaPolygons
    hfg.(['PcaPolygons' figureSuffix]) = figure('Visible', pms.ifplot); hold on; box on; grid on;
    set(hfg.(['PcaPolygons' figureSuffix]), 'Position', pms.pcaPolygonFigurePosition);
    polygonAxes = gobjects(nSteps, 1);
    for iStep = 1:nSteps
        Proj = resCorr{iStep, end}.Zpca;
        polygonAxes(iStep) = subplot(1, nSteps, iStep); hold on; box on; grid on;
        for iCond = cats
            if hm == 3
                plot3(Proj(iCond, 1), Proj(iCond, 2), Proj(iCond, 3), ...
                    'o', 'markersize', ms, 'MarkerEdgeColor', 'k', ...
                    'MarkerFaceColor', cmaps(iCond, :));
            else
                plot(Proj(iCond, 1), Proj(iCond, 2), ...
                    'o', 'markersize', ms, 'MarkerEdgeColor', 'k', ...
                    'MarkerFaceColor', cmaps(iCond, :));
            end
        end
        if hm == 3
            hp = plot3([Proj(:, 1); Proj(1, 1)], [Proj(:, 2); Proj(1, 2)], ...
                [Proj(:, 3); Proj(1, 3)], 'k', 'linewidth', 2);
            view(3);
            zlabel('rPC3');
        else
            hp = plot([Proj(:, 1); Proj(1, 1)], [Proj(:, 2); Proj(1, 2)], ...
                'k', 'linewidth', 2);
        end
        uistack(hp, 'bottom');
        ev = get_beta_title_explained_variance_string(resCorr, iStep, hm);
        polygonTitle = ['pca t' num2str(iStep) ' (' ev '%)'];
        if pms.pcaPolygonShowDimInTitle
            latent = get_beta_latent(resCorr, iStep, pms);
            effectiveDimension = compute_beta_effective_dimension(latent);
            if ~isnan(effectiveDimension)
                polygonTitle = sprintf('%s - Dim=%.2f', polygonTitle, effectiveDimension);
            end
        end
        title(polygonTitle, 'FontSize', 18);
        xlabel('rPC1', 'FontSize', 16);
        ylabel('rPC2', 'FontSize', 16);
        if ~isempty(pms.polygonTicks)
            polygonTicks = pms.polygonTicks;
            xlim([min(polygonTicks),max(polygonTicks)]);
            ylim([min(polygonTicks),max(polygonTicks)]);
            xticks(polygonTicks);
            yticks(polygonTicks);
        end
        axis square;
        set(gca, 'FontSize', 16);
    end

    if nCats > 0
        plotPositions = zeros(numel(polygonAxes), 4);
        for iAx = 1:numel(polygonAxes)
            pos = get(polygonAxes(iAx), 'Position');
            pos(2) = 0.28;
            pos(4) = 0.56;
            set(polygonAxes(iAx), 'Position', pos);
            plotPositions(iAx, :) = pos;
        end

        legendLeft = min(plotPositions(:, 1));
        legendRight = max(plotPositions(:, 1) + plotPositions(:, 3));
        legendBottom = 0.11 + pms.pcaPolygonLegendYOffset;
        legendLeft = legendLeft + pms.pcaPolygonLegendXOffset;
        legendAx = axes('Parent', hfg.(['PcaPolygons' figureSuffix]), ...
            'Units', 'normalized', ...
            'Position', [legendLeft, legendBottom, legendRight - legendLeft, 0.08], ...
            'Visible', 'off', ...
            'HitTest', 'off', ...
            'HandleVisibility', 'off');
        hold(legendAx, 'on');
        legendHandles = gobjects(nCats, 1);
        for iCond = cats
            legendHandles(iCond) = plot(legendAx, NaN, NaN, 'o', ...
                'markersize', ms, ...
                'MarkerEdgeColor', 'k', ...
                'MarkerFaceColor', cmaps(iCond, :), ...
                'LineStyle', 'none');
        end

        hLegend = legend(legendAx, legendHandles, catNames, ...
            'Orientation', 'horizontal', ...
            'AutoUpdate', 'off', ...
            'Location', 'north');
        hLegend.NumColumns = numel(catNames);
        hLegend.Box = 'off';
        hLegend.FontSize = 14;
    end
end

if pms.plotPcaTrajectories
    hfg.(['PcaTrajectories' figureSuffix]) = figure('Visible', pms.ifplot); hold on; box on; grid on;
    set(hfg.(['PcaTrajectories' figureSuffix]), 'Position', pms.pcaPolygonFigurePosition);
    trajectoryAxes = gobjects(nSteps, 1);
    for iStep = 1:nSteps
        trajectoryAxes(iStep) = subplot(1, nSteps, iStep); hold on; box on; grid on;
        ev = get_beta_title_explained_variance_string(resCorr, iStep, hm);
        title(['pca t' num2str(iStep) ' (' ev '%)']);

        Proj = cell(nWindows, 1);
        for iW = 1:nWindows
            Proj{iW} = resCorr{iStep, iW}.Zpca;
        end

        Conds = cell(nCats, 1);
        for iW = 1:nWindows
            for iCond = cats
                Conds{iCond}(iW, :) = Proj{iW}(iCond, :);
            end
        end

        for iCond = cats
            Xsq = apply_optional_smoothing(Conds{iCond}(:, 1), pms.trajectorySmoothing);
            Ysq = apply_optional_smoothing(Conds{iCond}(:, 2), pms.trajectorySmoothing);
            plot(Xsq, Ysq, 'linewidth', 3, 'Color', cmaps(iCond, :));
        end

        for iCond = cats
            Xsq = apply_optional_smoothing(Conds{iCond}(:, 1), pms.trajectorySmoothing);
            Ysq = apply_optional_smoothing(Conds{iCond}(:, 2), pms.trajectorySmoothing);
            plot(Xsq(1), Ysq(1), 'o', ...
                'markersize', ms - 4, 'MarkerEdgeColor', 'k', ...
                'MarkerFaceColor', 0.5 * ones(3, 1));
            plot(Xsq(end), Ysq(end), 's', ...
                'markersize', ms - 4, 'MarkerEdgeColor', 'k', ...
                'MarkerFaceColor', 0.5 * ones(3, 1));
        end
        axis equal;
        axis square;
        xlabel('rPC1');
        ylabel('rPC2');
    end

    sharedXLim = resolve_beta_shared_axis_limits(trajectoryAxes, 'XLim');
    sharedYLim = resolve_beta_shared_axis_limits(trajectoryAxes, 'YLim');
    for iAx = 1:numel(trajectoryAxes)
        set(trajectoryAxes(iAx), ...
            'XLim', sharedXLim, ...
            'YLim', sharedYLim);
    end

    sharedXTicks = resolve_beta_shared_tick_values(trajectoryAxes, 'XTick');
    sharedYTicks = resolve_beta_shared_tick_values(trajectoryAxes, 'YTick');
    for iAx = 1:numel(trajectoryAxes)
        set(trajectoryAxes(iAx), ...
            'XTick', sharedXTicks, ...
            'YTick', sharedYTicks);
    end

    if nCats > 0
        plotPositions = zeros(numel(trajectoryAxes), 4);
        for iAx = 1:numel(trajectoryAxes)
            pos = get(trajectoryAxes(iAx), 'Position');
            pos(2) = 0.28;
            pos(4) = 0.56;
            set(trajectoryAxes(iAx), 'Position', pos);
            plotPositions(iAx, :) = pos;
        end

        legendLeft = min(plotPositions(:, 1));
        legendRight = max(plotPositions(:, 1) + plotPositions(:, 3));
        legendBottom = 0.11 + pms.pcaPolygonLegendYOffset;
        legendLeft = legendLeft + pms.pcaPolygonLegendXOffset;
        legendAx = axes('Parent', hfg.(['PcaTrajectories' figureSuffix]), ...
            'Units', 'normalized', ...
            'Position', [legendLeft, legendBottom, legendRight - legendLeft, 0.08], ...
            'Visible', 'off', ...
            'HitTest', 'off', ...
            'HandleVisibility', 'off');
        hold(legendAx, 'on');

        legendHandles = gobjects(nCats + 2, 1);
        for iCond = cats
            legendHandles(iCond) = plot(legendAx, NaN, NaN, '-', ...
                'LineWidth', 3, ...
                'Color', cmaps(iCond, :));
        end
        legendHandles(nCats + 1) = plot(legendAx, NaN, NaN, 'o', ...
            'markersize', ms - 4, ...
            'MarkerEdgeColor', 'k', ...
            'MarkerFaceColor', 0.5 * ones(3, 1), ...
            'LineStyle', 'none');
        legendHandles(nCats + 2) = plot(legendAx, NaN, NaN, 's', ...
            'markersize', ms - 4, ...
            'MarkerEdgeColor', 'k', ...
            'MarkerFaceColor', 0.5 * ones(3, 1), ...
            'LineStyle', 'none');

        hLegend = legend(legendAx, legendHandles, [catNames(:)', {'start'}, {'end'}], ...
            'Orientation', 'horizontal', ...
            'AutoUpdate', 'off', ...
            'Location', 'north');
        hLegend.NumColumns = nCats + 2;
        hLegend.Box = 'off';
        hLegend.FontSize = 14;
    end
end

if pms.plotPcaExplainedVariance
    figname = ['PcaExplainedVariance' figureSuffix];
    hfg.(figname) = figure('Visible', pms.ifplot); hold on; box on; grid on;
    cmapsExplained = resolve_beta_external_cmaps(pms, nSteps);
    gobs = gobjects(nSteps, 1);
    dx = resolve_beta_explained_variance_offsets(nSteps, 0.25);
    msExplained = 8;
    lwExplained = 2;
    legendLabels = cell(1, nSteps);
    maxComponentCount = 1;

    for iStep = 1:nSteps
        expl = get_beta_explained_variance(resCorr, iStep, pms);
        latent = get_beta_latent(resCorr, iStep, pms);
        cumulativeExplained = cumsum(expl) / 100;
        gobs(iStep) = plot(dx(iStep) + (1:numel(cumulativeExplained)), ...
            cumulativeExplained, 'o', ...
            'markersize', msExplained, ...
            'LineStyle', '-', ...
            'LineWidth', lwExplained, ...
            'color', cmapsExplained(iStep, :));
        maxComponentCount = max(maxComponentCount, numel(cumulativeExplained));
        legendLabels{iStep} = format_beta_rank_legend_label(iStep, latent);
    end

    ylabel('Cumulative EV');
    xlabel('Number of PCs');
    legend(gobs, legendLabels, 'Location', 'southeast');
    ylim([0, 1.1]);
    xlim([1 - 0.4, maxComponentCount + 0.4]);
    set(gca, 'FontSize', 16);
end

if pms.plotPcaManifoldAngles && nSteps >= 2
    figname = ['PcaManifoldAngles' figureSuffix];
    hfg.(figname) = figure('Visible', pms.ifplot); hold on; box on; grid on;

    stepPairs = nchoosek(1:nSteps, 2);
    angles = nan(size(stepPairs, 1), 1);
    angleLabels = cell(size(stepPairs, 1), 1);
    cmapsAngles = resolve_beta_external_cmaps(pms, size(stepPairs, 1));

    for iPair = 1:size(stepPairs, 1)
        stepA = stepPairs(iPair, 1);
        stepB = stepPairs(iPair, 2);
        basisA = get_beta_pca_basis(resCorr, stepA, pms, hm);
        basisB = get_beta_pca_basis(resCorr, stepB, pms, hm);
        angles(iPair) = rad2deg(subspace(basisA, basisB));
        angleLabels{iPair} = sprintf('%d-%d', stepA, stepB);
        bar(iPair, angles(iPair), ...
            'FaceColor', cmapsAngles(iPair, :), ...
            'BarWidth', 0.5);
    end

    plot(1:numel(angles), angles, 'ok', 'Markersize', 8, 'LineWidth', 3);
    xticks(1:numel(angles));
    xticklabels(angleLabels);
    ylabel('Principal angle (deg)');
    set(gca, 'FontSize', 14);
    xlim([0.5, numel(angles) + 0.5]);
    ylim([70, 93]);
    yticks(70:5:90);
end

if pms.plotPopulationResponses
    figname = ['PopulationResponses' figureSuffix];
    hfg.(figname) = figure('Visible', pms.ifplot, ...
        'Name', 'Population response matrices', ...
        'Color', 'w');
    betaSlice = get_beta_response_matrix(betaWeights, resCorr, pms);
    imagesc(betaSlice');
    colorbar;
    xlabel('Neuron');
    ylabel('Condition');
    set(gca, 'FontSize', 14);

    conditionLabels = build_beta_condition_labels(pms, size(betaSlice, 2));
    if ~isempty(conditionLabels)
        yticks(1:numel(conditionLabels));
        yticklabels(conditionLabels);
    end

    responseDim = compute_beta_response_matrix_dimension(betaSlice);
    if isnan(responseDim)
        title('Population response matrix');
    else
        title(sprintf('Population response matrix (D=%.2f)', responseDim));
    end
end

if pms.plotPcaTime
    figname = ['PcaTime' figureSuffix];
    hfg.(figname) = figure('Visible', pms.ifplot); hold on; box on; grid on;
    cmapsTimes = lines(pms.nLength);
    cmapsTimes = cmapsTimes(2:4, :);
    Timepca = data_trials(1).(['timem' pms.signalName]);
    inds = Timepca < pms.pcaTimeMaxTime;
    Timepca = Timepca + pms.pcaTimeOffset;
    if pms.prependPcaTimeAnchor
        Timepca = [0.8, Timepca];
        inds = [inds(1), inds];
    end
    iend = find(inds, 1, 'last');
    maxVisibleTime = max(Timepca(inds));
    [sharedYLim, sharedZLim] = resolve_beta_time_axes_limits(resCorr, cats, nSteps, nWindows, iend, inds, pms);
    [labelYLim, labelZLim] = resolve_beta_time_label_limits(resCorr, cats, nSteps, nWindows, iend, inds, pms);
    axTime = gobjects(nSteps, 1);
    epochLabelSpecs = cell(nSteps, 1);
    tiledlayout(nSteps, 1);

    for iStep = 1:nSteps
        hobs = gobjects(nCats, 1);
        Pvals = nan(nCats, 3);
        nexttile; hold on; box on; grid on;
        axTime(iStep) = gca;
        set(gca, 'SortMethod', 'childorder');
        ev = get_beta_time_title_explained_variance_string(resCorr, iStep, hm, iend, pms);
        title(['pca t' num2str(iStep) ' (' ev '%)']);

        Proj = cell(nWindows, 1);
        for iW = 1:nWindows
            Proj{iW} = resCorr{iStep, iW}.Zpca;
        end

        Conds = cell(nCats, 1);
        for iW = 1:nWindows
            for iCond = cats
                Conds{iCond}(iW, :) = Proj{iW}(iCond, :);
            end
        end

        for iCond = cats
            [Xsq, Ysq, highlightIndex] = build_pca_time_trace(Conds{iCond}, iStep, iend, pms);
            [Xsq, Ysq] = apply_pca_time_trace_separation(Xsq, Ysq, iCond, iStep, pms);
            hobs(iCond) = plot3(Timepca(inds), Xsq(inds), Ysq(inds), ...
                'linewidth', 3, ...
                'Color', cmaps(iCond, :)); %#ok<AGROW>
        end

        for iCond = cats
            [Xsq, Ysq, highlightIndex] = build_pca_time_trace(Conds{iCond}, iStep, iend, pms);
            [Xsq, Ysq] = apply_pca_time_trace_separation(Xsq, Ysq, iCond, iStep, pms);
            hullIndex = resolve_beta_hull_anchor_index(iend, highlightIndex, pms);
            Pvals(iCond, :) = [Timepca(hullIndex), Xsq(hullIndex), Ysq(hullIndex)];
            hobs(end + 1) = plot3(Timepca(1), Xsq(1), Ysq(1), 'o', ... %#ok<AGROW>
                'markersize', ms - 10, 'MarkerEdgeColor', 'k', ...
                'MarkerFaceColor', 0.5 * ones(3, 1));
            if is_beta_sensor_legacy_mode(pms)
                hobs(end + 1) = plot3(Timepca(highlightIndex), Xsq(highlightIndex), Ysq(highlightIndex), 'd', ... %#ok<AGROW>
                    'markersize', ms - 10, 'MarkerEdgeColor', 'k', ...
                    'MarkerFaceColor', 0.5 * ones(3, 1));
            end
            hobs(end + 1) = plot3(Timepca(iend), Xsq(iend), Ysq(iend), 's', ... %#ok<AGROW>
                'markersize', ms - 10, 'MarkerEdgeColor', 'k', ...
                'MarkerFaceColor', 0.5 * ones(3, 1));
        end

        Point = Pvals(cats, :);
        timePoint = Point(1, 1);
        XPoint = Point(:, 2);
        YPoint = Point(:, 3);
        korder = convhull(XPoint, YPoint);

        fill3(timePoint * ones(size(XPoint(korder))), XPoint(korder), YPoint(korder), ...
            cmapsTimes(min(iStep, size(cmapsTimes, 1)), :), ...
            'FaceAlpha', 0.5, 'EdgeColor', 'k');

        Pvals = [Pvals; Pvals(1, :)];
        plot3(Pvals(:, 1), Pvals(:, 2), Pvals(:, 3), ...
            'color', 0.3 * ones(3, 1), 'linewidth', 3);

        if ~isempty(pms.pcaTimeXLim)
            apply_beta_time_xlim(pms.pcaTimeXLim, maxVisibleTime);
        elseif ~is_beta_sensor_legacy_mode(pms)
            xlim([0, 5.9]);
        end
        if ~isempty(pms.pcaTimeYLim)
            ylim(pms.pcaTimeYLim);
        elseif ~isempty(sharedYLim)
            ylim(sharedYLim);
        end
        if ~isempty(pms.pcaTimeZLim)
            zlim(pms.pcaTimeZLim);
        elseif ~isempty(sharedZLim)
            zlim(sharedZLim);
        end
        view([11, -30]);
        set(gca, 'fontsize', 14);

        yt = ylim;
        zt = zlim;
        sectorPatchPositions = resolve_beta_sector_patch_positions(pms);
        hSectorPatches = gobjects(numel(sectorPatchPositions), 1);
        for iPatch = 1:numel(sectorPatchPositions)
            tsq = sectorPatchPositions(iPatch);
            Xsq = [tsq tsq tsq tsq];
            Ysq = [yt(1) yt(2) yt(2) yt(1)];
            Zsq = [zt(1) zt(1) zt(2) zt(2)];
            hSectorPatches(iPatch) = patch(Xsq, Ysq, Zsq, [0.7 0.7 0.7], ...
                'FaceAlpha', 0.3, 'EdgeColor', 'none');
        end
        for iPatch = 1:numel(hSectorPatches)
            uistack(hSectorPatches(iPatch), 'bottom');
        end

        if ~isempty(pms.pcaTimeXTicks)
            xticks(pms.pcaTimeXTicks);
        else
            xticks(1:5);
        end
        epochLabelSpecs{iStep} = resolve_beta_epoch_label_spec(gca, pms, iStep, labelYLim, labelZLim);
    end

    if is_beta_sensor_legacy_mode(pms)
        legendLabels = [catNames(:)', {'start'}, {'max'}, {'end'}];
        legendHandles = hobs(1:nCats + 3);
    else
        legendLabels = [catNames(:)', {'start'}, {'end'}];
        legendHandles = hobs(1:nCats + 2);
    end
    hlg = legend(legendHandles, legendLabels, 'AutoUpdate', 'off');
    hlg.Layout.Tile = 'east';
    xlabel('time (s)');
    set(hfg.(figname), 'Position', pms.pcaTimeFigurePosition);
    drawnow;
    place_beta_epoch_label_overlays(axTime, epochLabelSpecs, pms);
end
end

function apply_beta_time_xlim(xLimits, timePoints)
% Apply an explicit x-limits request while keeping the PCA hull visible.

xLimitsOut = xLimits;

if ~isempty(timePoints)
    maxTimePoint = max(timePoints);
    if xLimitsOut(2) < maxTimePoint
        xLimitsOut(2) = maxTimePoint + 0.05;
    end
end

xlim(xLimitsOut);
end

function hullIndex = resolve_beta_hull_anchor_index(endIndex, highlightIndex, pms)
% Choose which temporal marker should anchor the convex hull plane.

anchorMode = lower(strtrim(char(pms.pcaTimeHullAnchor)));

switch anchorMode
    case 'highlight'
        hullIndex = highlightIndex;
    case 'end'
        hullIndex = endIndex;
    otherwise
        error('%s:InvalidPcaTimeHullAnchor', mfilename, ...
            'pcaTimeHullAnchor must be ''end'' or ''highlight''.');
end
end

function expl = get_beta_explained_variance(resCorr, iStep, pms)
% Match either the generic or the compatibility-mode choice of explained-variance window.

windowIndex = resolve_beta_summary_window_index(resCorr, pms);
expl = resCorr{iStep, windowIndex}.expl;
end

function ev = get_beta_title_explained_variance_string(resCorr, iStep, hm)
% Use the final PCA summary window for title EV, matching polygon-style summaries.

expl = resCorr{iStep, end}.expl;
componentCount = min(hm, numel(expl));
ev = sprintf('%.2f', sum(expl(1:componentCount)));
end

function ev = get_beta_time_title_explained_variance_string(resCorr, iStep, hm, iend, pms)
% Use the PCA window associated with the displayed PcaTime hull anchor.

windowIndex = resolve_beta_time_title_window_index(resCorr, iStep, iend, pms);
expl = resCorr{iStep, windowIndex}.expl;
componentCount = min(hm, numel(expl));
ev = sprintf('%.2f', sum(expl(1:componentCount)));
end

function latent = get_beta_latent(resCorr, iStep, pms)
% Return the latent spectrum associated with the chosen PCA summary window.

windowIndex = resolve_beta_summary_window_index(resCorr, pms);
latent = resCorr{iStep, windowIndex}.latent;
end

function windowIndex = resolve_beta_summary_window_index(resCorr, pms)
% Resolve which PCA window should be used by summary plots and legends.

nWindows = size(resCorr, 2);

if ~isempty(pms.pcaExplainedVarianceWindowIndex)
    windowIndex = pms.pcaExplainedVarianceWindowIndex;
    if windowIndex < 1 || windowIndex > nWindows
        error('%s:InvalidExplainedVarianceWindowIndex', mfilename, ...
            'pcaExplainedVarianceWindowIndex=%d is outside [1,%d].', ...
            windowIndex, nWindows);
    end
    return;
end

if is_beta_any_legacy_mode(pms)
    windowIndex = 1;
else
    windowIndex = nWindows;
end
end

function windowIndex = resolve_beta_time_title_window_index(resCorr, iStep, iend, pms)
% Resolve the PCA window used by the PcaTime title from the displayed hull anchor.

nWindows = size(resCorr, 2);
visibleWindowEnd = iend;
if pms.prependPcaTimeAnchor
    visibleWindowEnd = visibleWindowEnd - 1;
end
visibleWindowEnd = min(max(visibleWindowEnd, 1), nWindows);

highlightWindowIndex = resolve_beta_time_highlight_window_index(iStep, visibleWindowEnd, pms);

anchorMode = lower(strtrim(char(pms.pcaTimeHullAnchor)));
switch anchorMode
    case 'end'
        windowIndex = visibleWindowEnd;
    case 'highlight'
        windowIndex = highlightWindowIndex;
    otherwise
        error('%s:InvalidPcaTimeHullAnchor', mfilename, ...
            'pcaTimeHullAnchor must be ''end'' or ''highlight''.');
end
end

function label = format_beta_rank_legend_label(stepIndex, latent)
% Build the explained-variance legend label for one symbolic rank.

effectiveDimension = compute_beta_effective_dimension(latent);

if isnan(effectiveDimension)
    label = sprintf('Rank%d', stepIndex);
else
    label = sprintf('Rank%d (dim=%.2f)', stepIndex, effectiveDimension);
end
end

function effectiveDimension = compute_beta_effective_dimension(latent)
% Convert a latent spectrum into a single effective-dimensionality score.

latent = latent(:);
latent = latent(isfinite(latent) & latent > 0);

if isempty(latent)
    effectiveDimension = NaN;
    return;
end

denominator = sum(latent .^ 2);
if denominator <= 0
    effectiveDimension = NaN;
    return;
end

effectiveDimension = (sum(latent) ^ 2) / denominator;
end

function dx = resolve_beta_explained_variance_offsets(nSteps, maxAbsOffset)
% Spread explained-variance markers slightly to keep step-wise curves readable.

if nSteps <= 1
    dx = 0;
else
    dx = linspace(-maxAbsOffset, maxAbsOffset, nSteps);
end
end

function tickValues = resolve_beta_shared_tick_values(axArray, tickProperty)
% Pick one shared tick vector for all trajectory subplots.

tickValues = [];
bestCount = -1;

for iAx = 1:numel(axArray)
    currentTicks = get(axArray(iAx), tickProperty);
    currentTicks = currentTicks(:)';
    if numel(currentTicks) > bestCount
        bestCount = numel(currentTicks);
        tickValues = currentTicks;
    end
end
end

function axisLimits = resolve_beta_shared_axis_limits(axArray, axisProperty)
% Use one common axis range across trajectory subplots.

lowerBounds = nan(1, numel(axArray));
upperBounds = nan(1, numel(axArray));

for iAx = 1:numel(axArray)
    currentLimits = get(axArray(iAx), axisProperty);
    lowerBounds(iAx) = currentLimits(1);
    upperBounds(iAx) = currentLimits(2);
end

axisLimits = [min(lowerBounds), max(upperBounds)];
end

function basis = get_beta_pca_basis(resCorr, iStep, pms, hm)
% Return the principal-component basis used for angle comparisons.

windowIndex = resolve_beta_summary_window_index(resCorr, pms);
resEntry = resCorr{iStep, windowIndex};
Wpca = resEntry.Wpca;
nComponents = min(hm, size(Wpca, 2));
basis = Wpca(:, 1:nComponents);

if ~isfield(resEntry, 'neuronIndices') || isempty(resEntry.neuronIndices) || ...
        ~isfield(resEntry, 'fullNeuronCount') || isempty(resEntry.fullNeuronCount)
    return;
end

fullNeuronCount = resEntry.fullNeuronCount;
neuronIndices = resEntry.neuronIndices(:)';

if size(basis, 1) == fullNeuronCount && isequal(neuronIndices, 1:fullNeuronCount)
    return;
end

if numel(neuronIndices) ~= size(basis, 1)
    error('%s:InconsistentPcaBasis', mfilename, ...
        ['The stored neuronIndices for step %d do not match the PCA basis size ' ...
         '(%d indices vs %d rows).'], ...
        iStep, numel(neuronIndices), size(basis, 1));
end

expandedBasis = zeros(fullNeuronCount, nComponents);
expandedBasis(neuronIndices, :) = basis;
basis = expandedBasis;
end

function angleLimits = resolve_beta_angle_limits(angles)
% Build comfortable axis limits for the manifold-angle summary.

angles = angles(isfinite(angles));

if isempty(angles)
    angleLimits = [0, 90];
    return;
end

minAngle = min(angles);
maxAngle = max(angles);

if minAngle == maxAngle
    pad = max(5, 0.1 * maxAngle);
else
    pad = 0.1 * (maxAngle - minAngle);
end

lowerBound = max(0, minAngle - pad);
upperBound = min(90, maxAngle + pad);

if upperBound <= lowerBound
    upperBound = min(90, lowerBound + 5);
end

angleLimits = [lowerBound, upperBound];
end

function betaSlice = get_beta_response_matrix(betaWeights, resCorr, pms)
% Return the beta matrix associated with the selected summary window.

windowIndex = resolve_beta_summary_window_index(resCorr, pms);
betaSlice = betaWeights(:, :, windowIndex);
end

function conditionLabels = build_beta_condition_labels(pms, nConditions)
% Build row labels for the population-response heatmap.

nCats = numel(pms.catNames);
if nCats < 1
    conditionLabels = {};
    return;
end

nSteps = floor(nConditions / nCats);
if nSteps < 1 || nSteps * nCats ~= nConditions
    conditionLabels = {};
    return;
end

conditionLabels = cell(1, nConditions);
labelIndex = 0;
for iStep = 1:nSteps
    for iCat = 1:nCats
        labelIndex = labelIndex + 1;
        conditionLabels{labelIndex} = sprintf('%s%d', pms.catNames{iCat}, iStep);
    end
end
end

function effectiveDimension = compute_beta_response_matrix_dimension(betaSlice)
% Estimate an effective dimensionality for the population-response heatmap.

try
    [~, ~, latent] = pca(betaSlice');
catch
    effectiveDimension = NaN;
    return;
end

effectiveDimension = compute_beta_effective_dimension(latent);
end

function nSteps = resolve_beta_type_step_count(data_trials, pms)
% Resolve how many symbolic steps should be encoded from trialName.

if isempty(pms.typeStepCount)
    nSteps = length(data_trials(1).trialName);
else
    nSteps = pms.typeStepCount;
end
end

function [Xsq, Ysq, highlightIndex] = build_pca_time_trace(condValues, iStep, iend, pms)
% Build one PCA time trace, optionally reproducing the compatibility-mode sensor smoothing.

Xsq = smooth(condValues(:, 1), pms.timeSmoothing);
Ysq = smooth(condValues(:, 2), pms.timeSmoothing);

visibleWindowEnd = iend;
if pms.prependPcaTimeAnchor
    visibleWindowEnd = iend - 1;
end
visibleWindowEnd = max(1, visibleWindowEnd);

highlightIndex = resolve_beta_time_highlight_window_index(iStep, visibleWindowEnd, pms);
if is_beta_sensor_legacy_mode(pms)
    Xsq = apply_segment_smoothing(Xsq, iStep, highlightIndex, pms.timeSmoothing + 7);
    Ysq = apply_segment_smoothing(Ysq, iStep, highlightIndex, pms.timeSmoothing + 7);
end

if pms.prependPcaTimeAnchor
    Xsq = [Xsq(1, :); Xsq];
    Ysq = [Ysq(1, :); Ysq];
    highlightIndex = highlightIndex + 1;
end
end

function highlightWindowIndex = resolve_beta_time_highlight_window_index(iStep, visibleWindowEnd, pms)
% Resolve the PCA window used by the PcaTime highlight anchor.

highlightWindowIndex = visibleWindowEnd;

if isfield(pms, 'pcaTimeHighlightIndices') && ~isempty(pms.pcaTimeHighlightIndices)
    customIndices = pms.pcaTimeHighlightIndices;
    if iStep <= numel(customIndices)
        candidateIndex = customIndices(iStep);
        if isfinite(candidateIndex)
            highlightWindowIndex = min(visibleWindowEnd, max(1, round(candidateIndex)));
            return;
        end
    end
end

if is_beta_sensor_legacy_mode(pms)
    compatibilityIndices = [5, 8, 10];
    if iStep <= numel(compatibilityIndices)
        highlightWindowIndex = min(visibleWindowEnd, compatibilityIndices(iStep));
    end
end
end

function [XsqOut, YsqOut] = apply_pca_time_trace_separation(XsqIn, YsqIn, iCond, iStep, pms)
% Optionally add a purely visual separation to overlapping PcaTime traces.

XsqOut = XsqIn;
YsqOut = YsqIn;

mode = 'none';
if isfield(pms, 'pcaTimeTraceSeparationMode') && ~isempty(pms.pcaTimeTraceSeparationMode)
    mode = lower(strtrim(char(pms.pcaTimeTraceSeparationMode)));
end

switch mode
    case 'none'
        return;

    case 'offset'
        offsetVector = compute_pca_time_trace_offset_vector(iCond, iStep, pms.pcaTimeTraceOffset);
        XsqOut = XsqOut + offsetVector(1);
        YsqOut = YsqOut + offsetVector(2);

    case 'jitter'
        offsetVector = compute_pca_time_trace_offset_vector(iCond, iStep, pms.pcaTimeTraceJitter);
        XsqOut = XsqOut + offsetVector(1);
        YsqOut = YsqOut + offsetVector(2);

    case 'noise'
        randState = rng;
        rng(pms.pcaTimeTraceRandomSeed + 100 * iStep + iCond);
        XsqOut = XsqOut + pms.pcaTimeTraceNoiseStd * randn(size(XsqOut));
        YsqOut = YsqOut + pms.pcaTimeTraceNoiseStd * randn(size(YsqOut));
        rng(randState);

    otherwise
        error('%s:InvalidPcaTimeTraceSeparationMode', mfilename, ...
            ['pcaTimeTraceSeparationMode must be ''none'', ''offset'', ' ...
             '''jitter'', or ''noise''.']);
end
end

function offsetVector = compute_pca_time_trace_offset_vector(iCond, iStep, magnitude)
% Build a small deterministic 2D offset for visual trace separation.

nDirections = 6;
angle = 2 * pi * (iCond - 1) / nDirections + (iStep - 1) * pi / 18;
offsetVector = magnitude * [cos(angle), sin(angle)];
end

function [sharedYLim, sharedZLim] = resolve_beta_time_axes_limits(resCorr, cats, nSteps, nWindows, iend, inds, pms)
% Keep the PCA-time panels on the same Y/Z frame so epoch sectors stay aligned.

sharedYLim = [];
sharedZLim = [];

if is_beta_any_legacy_mode(pms) || (~isempty(pms.pcaTimeYLim) && ~isempty(pms.pcaTimeZLim))
    return;
end

allY = [];
allZ = [];
for iStep = 1:nSteps
    Proj = cell(nWindows, 1);
    for iW = 1:nWindows
        Proj{iW} = resCorr{iStep, iW}.Zpca;
    end

    for iCond = cats
        condValues = nan(nWindows, size(Proj{1}, 2));
        for iW = 1:nWindows
            condValues(iW, :) = Proj{iW}(iCond, :);
        end
        [Ytrace, Ztrace] = build_pca_time_trace(condValues, iStep, iend, pms);
        allY = [allY; Ytrace(inds)]; %#ok<AGROW>
        allZ = [allZ; Ztrace(inds)]; %#ok<AGROW>
    end
end

if isempty(pms.pcaTimeYLim) && ~isempty(allY)
    sharedYLim = expand_beta_axis_limits([min(allY), max(allY)]);
end
if isempty(pms.pcaTimeZLim) && ~isempty(allZ)
    sharedZLim = expand_beta_axis_limits([min(allZ), max(allZ)]);
end
end

function [labelYLim, labelZLim] = resolve_beta_time_label_limits(resCorr, cats, nSteps, nWindows, iend, inds, pms)
% Build a stable Y/Z frame for legacy epoch labels without forcing subplot limits.

labelYLim = [];
labelZLim = [];

if ~is_beta_sequence_legacy_mode(pms)
    return;
end

if ~isempty(pms.pcaTimeYLim)
    labelYLim = pms.pcaTimeYLim;
end
if ~isempty(pms.pcaTimeZLim)
    labelZLim = pms.pcaTimeZLim;
end

if ~isempty(labelYLim) && ~isempty(labelZLim)
    return;
end

allY = [];
allZ = [];
for iStep = 1:nSteps
    Proj = cell(nWindows, 1);
    for iW = 1:nWindows
        Proj{iW} = resCorr{iStep, iW}.Zpca;
    end

    for iCond = cats
        condValues = nan(nWindows, size(Proj{1}, 2));
        for iW = 1:nWindows
            condValues(iW, :) = Proj{iW}(iCond, :);
        end
        [Ytrace, Ztrace] = build_pca_time_trace(condValues, iStep, iend, pms);
        allY = [allY; Ytrace(inds)]; %#ok<AGROW>
        allZ = [allZ; Ztrace(inds)]; %#ok<AGROW>
    end
end

if isempty(labelYLim) && ~isempty(allY)
    labelYLim = expand_beta_axis_limits([min(allY), max(allY)]);
end
if isempty(labelZLim) && ~isempty(allZ)
    labelZLim = expand_beta_axis_limits([min(allZ), max(allZ)]);
end
end

function limitsOut = expand_beta_axis_limits(limitsIn)
% Add a small padding so shared plot limits do not clip the trajectories.

rangeIn = diff(limitsIn);
if rangeIn <= 0
    pad = max(abs(limitsIn(1)) * 0.05, 0.05);
else
    pad = 0.05 * rangeIn;
end

limitsOut = [limitsIn(1) - pad, limitsIn(2) + pad];
end

function labelSpec = resolve_beta_epoch_label_spec(ax, pms, iStep, labelYLim, labelZLim)
% Build the full label-placement specification for one PcaTime subplot.

[labelXOffset, labelYOffset] = resolve_beta_epoch_label_offsets(pms, iStep);
labelAxisTilt = resolve_beta_epoch_label_offset_value( ...
    pms.pcaTimeEpochLabelAxisTilts, ...
    iStep, ...
    pms.pcaTimeEpochLabelAxisTilt);

if isempty(pms.pcaTimeEpochLabels)
    labelSpec = [];
    return;
end

if isempty(pms.pcaTimeEpochLabels)
    labelSpec = [];
    return;
end


labelSpec = struct();
labelSpec.labels = pms.pcaTimeEpochLabels;
labelSpec.extraPos = resolve_beta_epoch_label_positions(pms, labelSpec.labels, labelXOffset, iStep);
labelSpec.xLimits = xlim(ax);
baseY = pms.pcaTimeEpochLabelOverlayBaseY + labelYOffset;
labelSpec.yPos = apply_beta_epoch_label_axis_tilt(baseY, labelSpec.extraPos, labelAxisTilt);
end

function sectorPatchPositions = resolve_beta_sector_patch_positions(pms)
% Resolve the X positions of the gray sector patches in the PcaTime panels.

sectorPatchPositions = pms.pcaTimeSectorPatchPositions;
if isempty(sectorPatchPositions)
    sectorPatchPositions = 1:5;
end
sectorPatchPositions = sectorPatchPositions(:)';
end

function extraPos = resolve_beta_epoch_label_positions(pms, labels, labelXOffset, iStep)
% Resolve the x-positions of the epoch labels, including default compatibility shifts.

if isempty(pms.pcaTimeEpochLabelPositions)
    basePos = 0.5:1:(numel(labels) - 0.5);
    if is_beta_sensor_legacy_mode(pms)
        basePos = basePos + pms.pcaTimeEpochLabelSensorBaseXShift;
    else
        basePos = basePos + pms.pcaTimeEpochLabelSequenceBaseXShift;
    end
else
    basePos = pms.pcaTimeEpochLabelPositions;
end

spacingScale = resolve_beta_epoch_label_offset_value( ...
    pms.pcaTimeEpochLabelSpacingScales, ...
    iStep, ...
    pms.pcaTimeEpochLabelSpacingScale);
basePos = apply_beta_epoch_label_spacing(basePos, spacingScale);

extraPos = basePos + labelXOffset;
end

function positionsOut = apply_beta_epoch_label_spacing(positionsIn, spacingScale)
% Scale the spacing between consecutive epoch labels while keeping the first label anchored.

positionsOut = positionsIn;
if numel(positionsIn) < 2 || isempty(spacingScale) || spacingScale == 1
    return;
end

anchorPos = positionsIn(1);
positionsOut = anchorPos + (positionsIn - anchorPos) * spacingScale;
end

function yPos = apply_beta_epoch_label_axis_tilt(baseY, extraPos, axisTilt)
% Tilt the label baseline by adding a Y increment proportional to x-distance from the first label.

yPos = baseY + (extraPos - extraPos(1)) * axisTilt;
end

function valuesOut = expand_beta_epoch_label_coordinate(valuesIn, targetLength)
% Expand a scalar label coordinate to one value per label when needed.

if isscalar(valuesIn)
    valuesOut = repmat(valuesIn, 1, targetLength);
else
    valuesOut = valuesIn;
end
end


function mode = resolve_beta_compatibility_mode(pms)
% Resolve which legacy preset, if any, should be applied to BETA plots.

mode = 'generic';
if isfield(pms, 'betaCompatibilityMode') && ~isempty(pms.betaCompatibilityMode)
    mode = lower(strtrim(char(pms.betaCompatibilityMode)));
elseif isfield(pms, 'useLegacyCompatibility') && pms.useLegacyCompatibility
    mode = 'sensor_legacy';
end

validModes = {'generic', 'sequence_legacy', 'sensor_legacy'};
if ~ismember(mode, validModes)
    error('%s:InvalidBetaCompatibilityMode', mfilename, ...
        'betaCompatibilityMode must be ''generic'', ''sequence_legacy'', or ''sensor_legacy''.');
end
end

function tf = is_beta_any_legacy_mode(pms)
% True when either sequence or sensor legacy behaviour is requested.

tf = ~strcmp(resolve_beta_compatibility_mode(pms), 'generic');
end

function tf = is_beta_sequence_legacy_mode(pms)
% True when the sequence legacy flow should be preserved.

tf = strcmp(resolve_beta_compatibility_mode(pms), 'sequence_legacy');
end

function tf = is_beta_sensor_legacy_mode(pms)
% True when the sensor legacy flow should be preserved.

tf = strcmp(resolve_beta_compatibility_mode(pms), 'sensor_legacy');
end

function place_beta_epoch_label_overlays(axHandles, epochLabelSpecs, pms)
% Place epoch labels on transparent 2D overlay axes aligned to each tile plot-box.

for iAx = 1:numel(axHandles)
    ax = axHandles(iAx);
    if ~isgraphics(ax)
        continue;
    end

    spec = epochLabelSpecs{iAx};
    if isempty(spec)
        continue;
    end

    overlayAx = axes('Parent', ancestor(ax, 'figure'), ...
        'Position', ax.InnerPosition, ...
        'Color', 'none', ...
        'XLim', spec.xLimits, ...
        'YLim', [0, 1], ...
        'XTick', [], ...
        'YTick', [], ...
        'Box', 'off', ...
        'Visible', 'off', ...
        'HandleVisibility', 'off', ...
        'HitTest', 'off', ...
        'PickableParts', 'none');

    yPos = expand_beta_epoch_label_coordinate(spec.yPos, numel(spec.extraPos));
    for iPos = 1:numel(spec.extraPos)
        text(overlayAx, spec.extraPos(iPos), yPos(iPos), spec.labels{iPos}, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', ...
            'fontsize', 20, ...
            'Clipping', 'off');
    end
end
end

function [xOffset, yOffset] = resolve_beta_epoch_label_offsets(pms, iStep)
% Resolve optional per-subplot X/Y offsets for the PcaTime epoch labels.

xOffset = resolve_beta_epoch_label_offset_value(pms.pcaTimeEpochLabelXOffsets, iStep, 0);
yOffset = resolve_beta_epoch_label_offset_value(pms.pcaTimeEpochLabelYOffsets, iStep, pms.pcaTimeEpochLabelYOffset);
end

function offsetValue = resolve_beta_epoch_label_offset_value(offsetSpec, iStep, fallbackValue)
% Resolve one scalar offset from a per-subplot vector, repeating the last value when needed.

if isempty(offsetSpec)
    offsetValue = fallbackValue;
    return;
end

offsetSpec = offsetSpec(:)';
offsetIndex = min(iStep, numel(offsetSpec));
offsetValue = offsetSpec(offsetIndex);
end

function valuesOut = apply_segment_smoothing(valuesIn, iStep, highlightIndex, smoothingSpan)
% Reproduce the local post-smoothing windows used by the compatibility-mode sensor PCA plots.

valuesOut = valuesIn;

switch iStep
    case 1
        valuesOut = smooth_value_segment(valuesOut, highlightIndex - 2, highlightIndex, smoothingSpan);
        valuesOut = smooth_value_segment(valuesOut, highlightIndex, highlightIndex + 3, smoothingSpan);
    case 2
        valuesOut = smooth_value_segment(valuesOut, highlightIndex - 4, highlightIndex, smoothingSpan);
        valuesOut = smooth_value_segment(valuesOut, highlightIndex, highlightIndex + 3, smoothingSpan);
    case 3
        valuesOut = smooth_value_segment(valuesOut, highlightIndex - 3, highlightIndex, smoothingSpan);
        valuesOut = smooth_value_segment(valuesOut, highlightIndex, highlightIndex + 2, smoothingSpan);
    otherwise
        % No extra step-specific smoothing.
end
end

function valuesOut = smooth_value_segment(valuesIn, startIndex, endIndex, smoothingSpan)
% Smooth only one bounded segment of a vector.

valuesOut = valuesIn;
startIndex = max(1, startIndex);
endIndex = min(numel(valuesIn), endIndex);
if endIndex <= startIndex
    return;
end

valuesOut(startIndex:endIndex) = smooth(valuesOut(startIndex:endIndex), smoothingSpan);
end

function valuesOut = apply_optional_smoothing(valuesIn, smoothingParam)
% Apply MATLAB smooth either with its default behaviour or with an explicit span.

if isempty(smoothingParam)
    valuesOut = smooth(valuesIn);
else
    valuesOut = smooth(valuesIn, smoothingParam);
end
end

function figureSuffix = build_beta_figure_suffix(testDir, data_trials, pms)
% Build the compact experiment suffix such as _Chen01_ABCDEF_S1S2S3_Bwd.

[experimentLabel, targetLabel, familyLabel, directionLabel] = ...
    parse_experiment_name_from_dir(testDir);

if isempty(experimentLabel)
    experimentLabel = pms.experimentLabel;
end

if isempty(experimentLabel)
    experimentLabel = 'Sequence';
end

if isempty(targetLabel)
    targetLabel = pms.figureTargetLabel;
end

if isempty(targetLabel)
    targetLabel = infer_target_label(data_trials, pms);
end

if isempty(targetLabel)
    targetLabel = 'Targets';
end

if isempty(familyLabel)
    familyLabel = pms.figureFamilyLabel;
end

if isempty(familyLabel)
    familyLabel = 'Seq';
end

if isempty(directionLabel)
    directionLabel = pms.figureDirectionLabel;
end

if isempty(directionLabel)
    directionLabel = infer_direction_label(data_trials);
end

figureSuffix = sprintf('_%s_%s_%s_%s', ...
    experimentLabel, targetLabel, familyLabel, directionLabel);

if ~isempty(pms.figureSuffixAppend)
    figureSuffix = [figureSuffix normalise_beta_suffix_append(pms.figureSuffixAppend)];
end
end

function suffixOut = normalise_beta_suffix_append(suffixIn)
% Normalise an optional extra suffix so it always starts with one underscore.

suffixOut = char(suffixIn);
suffixOut = strtrim(suffixOut);

if isempty(suffixOut)
    return;
end

if suffixOut(1) ~= '_'
    suffixOut = ['_' suffixOut];
end
end

function [experimentLabel, targetLabel, familyLabel, directionLabel] = parse_experiment_name_from_dir(testDir)
% Parse the compact experiment label from the enclosing experiment folder.

experimentLabel = '';
targetLabel = '';
familyLabel = '';
directionLabel = '';

testDir = regexprep(testDir, [filesep '+$'], '');
[parentDir, folderName] = fileparts(testDir);
if startsWith(folderName, 'Rep', 'IgnoreCase', true)
    [~, folderName] = fileparts(parentDir);
end

tokens = regexp(folderName, ...
    '^(?<exp>[^_]+)_SEQUENCES_(?<targets>[A-Z]+)_(?<family>[^_]+)_(?<dir>FwdBwd|Fwd|Bwd|Ord)', ...
    'names', 'once');

if isempty(tokens)
    return;
end

experimentLabel = tokens.exp;
targetLabel = tokens.targets;
familyLabel = tokens.family;
directionLabel = tokens.dir;
end

function targetLabel = infer_target_label(data_trials, pms)
% Infer the active target set from the observed symbolic trial names.

symbols = '';
for iTrial = 1:numel(data_trials)
    trialName = data_trials(iTrial).trialName;
    for iChar = 1:numel(trialName)
        if any(strcmp(pms.catNames, trialName(iChar))) && ~any(symbols == trialName(iChar))
            symbols(end + 1) = trialName(iChar); %#ok<AGROW>
        end
    end
end

targetLabel = symbols;
end

function directionLabel = infer_direction_label(data_trials)
% Infer the experiment direction label from trial labels when available.

directionLabel = 'Ord';

for iTrial = 1:numel(data_trials)
    if ~isfield(data_trials(iTrial), 'trialLabel') || isempty(data_trials(iTrial).trialLabel)
        continue;
    end
    if endsWith(data_trials(iTrial).trialLabel, 'bw')
        directionLabel = 'Bwd';
        return;
    end
    if endsWith(data_trials(iTrial).trialLabel, 'fw')
        directionLabel = 'Fwd';
        return;
    end
end
end

function pathOut = ensure_trailing_filesep(pathIn)
% Ensure directory paths end with a file separator.

if isempty(pathIn)
    pathOut = filesep;
elseif pathIn(end) == filesep
    pathOut = pathIn;
else
    pathOut = [pathIn filesep];
end
end

function data_trials = extend_preprocessed_beta_trials(data_trials, pms)
% Extend already-processed population firing rates and generate spikes.

labEpochs = data_trials(1).labEpochs;
nBins = sum(labEpochs == 1);
Nev = pms.Nev;
if isempty(Nev)
    Nev = ones(1, pms.nLength);
end

for iTrial = 1:numel(data_trials)
    FR = data_trials(iTrial).popFR;
    [FR, tFR, extLabEpochs] = HAI_extendFiringRates(FR, nBins, pms.Nnr, Nev, pms.dt);
    data_trials(iTrial).firingRates = FR;
    data_trials(iTrial).timeFiringRates = pms.nLength * tFR / tFR(end);
    data_trials(iTrial).extLabEpochs = extLabEpochs;
    data_trials(iTrial).Spikes = HAI_fireToSpikes(FR, pms.cap, pms.th, pms.SpT);
    data_trials(iTrial).timeSpikes = data_trials(iTrial).timeFiringRates;
    data_trials(iTrial).popFRcosine = FR;
    data_trials(iTrial).timepopFRcosine = data_trials(iTrial).timeFiringRates;
end
end

function h = plotNeuronPolarByCondition(sampleTrials, neuronIdx, pms, varargin)
% h = plotNeuronPolarByCondition(sampleTrials, neuronIdx, pms, varargin)
%
% Plot polar tuning of one neuron across trial conditions.
%
% PARAMETERS
%   Use plotNeuronPolarByConditionParams for defaults.
%   Precedence:
%       defaults < pms struct < name-value pairs

if nargin < 3
    pms = struct();
end

pms = plotNeuronPolarByConditionParams(pms);

% Optional name-value overrides
for i = 1:2:numel(varargin)
    pms.(varargin{i}) = varargin{i+1};
end

opt = pms;

nTrials = numel(sampleTrials);
nCond   = numel(sampleTrials(1).(opt.TypeField));

responses = nan(nTrials, 1);
condIdx   = nan(nTrials, 1);

for iTr = 1:nTrials

    X = sampleTrials(iTr).(opt.DataField);   % NN x T

    if neuronIdx > size(X, 1)
        error('neuronIdx exceeds number of neurons in %s.', opt.DataField);
    end

    % ----- temporal selection -----
    if ~isempty(opt.TimeField) && ~isempty(opt.TimeWindow) && ...
            isfield(sampleTrials(iTr), opt.TimeField)

        t = sampleTrials(iTr).(opt.TimeField);
        mask = (t >= opt.TimeWindow(1)) & (t <= opt.TimeWindow(2));

        if any(mask)
            responses(iTr) = mean(X(neuronIdx, mask), 'omitnan');
        else
            responses(iTr) = NaN;
        end

    else
        responses(iTr) = mean(X(neuronIdx, :), 'omitnan');
    end

    % ----- condition -----
    thisType = sampleTrials(iTr).(opt.TypeField);
    c = find(thisType == 1, 1);

    if ~isempty(c)
        condIdx(iTr) = c;
    end
end

% ----- stats by condition -----
meanResp = nan(nCond, 1);
errResp  = nan(nCond, 1);
nPerCond = nan(nCond, 1);

for c = 1:nCond
    vals = responses(condIdx == c);
    vals = vals(~isnan(vals));

    nPerCond(c) = numel(vals);

    if isempty(vals)
        continue;
    end

    meanResp(c) = mean(vals);

    switch lower(opt.ErrorType)
        case 'sem'
            errResp(c) = std(vals) ./ sqrt(numel(vals));
        case 'std'
            errResp(c) = std(vals);
        case 'none'
            errResp(c) = 0;
        otherwise
            error('Unknown ErrorType: %s', opt.ErrorType);
    end
end

% ----- optional normalization -----
if opt.Normalize
    m = max(meanResp, [], 'omitnan');
    if m > 0
        meanResp = meanResp ./ m;
        errResp  = errResp  ./ m;
    end
end

% ----- axes -----
if isempty(opt.Ax)
    h.fig = figure('Color','w', ...
        'Visible', opt.Visible, ...
        'Position', opt.FigurePosition);
    ax = polaraxes(h.fig);
else
    ax = opt.Ax;
    h.fig = ancestor(ax, 'figure');
end

hold(ax, 'on');

theta = linspace(0, 2*pi, nCond + 1);
r     = [meanResp; meanResp(1)];

h.line = polarplot(ax, theta, r, '-o', ...
    'LineWidth', opt.LineWidth, ...
    'MarkerSize', opt.MarkerSize);

% ----- error bars -----
if ~strcmpi(opt.ErrorType, 'none')
    for c = 1:nCond
        th = theta(c);
        r0 = meanResp(c);
        e  = errResp(c);

        polarplot(ax, [th th], [r0-e r0+e], 'k', ...
            'LineWidth', 1);
    end
end

% ----- axis style -----
if ~isempty(opt.RLimits)
    ax.RLim = opt.RLimits;
end

ax.ThetaTick = rad2deg(theta(1:end-1));

if isempty(opt.ConditionLabels)
    ax.ThetaTickLabel = compose('%d', 1:nCond);
else
    ax.ThetaTickLabel = opt.ConditionLabels;
end

ax.RGrid = matlab.lang.OnOffSwitchState(opt.ShowGrid);
ax.ThetaGrid = matlab.lang.OnOffSwitchState(opt.ShowGrid);
ax.FontSize = opt.FontSize;

% ----- title -----
if isfield(sampleTrials, 'neuronLabels') && ...
        numel(sampleTrials(1).neuronLabels) >= neuronIdx
    neuronName = sampleTrials(1).neuronLabels{neuronIdx};
else
    neuronName = sprintf('Neuron %d', neuronIdx);
end

if isempty(opt.TimeWindow)
    timeStr = 'all T';
else
    timeStr = sprintf('[%.3g %.3g]', opt.TimeWindow(1), opt.TimeWindow(2));
end

if opt.ShowTitle
    % title(ax, sprintf('%s | %s | %s | %s', ...
    %     neuronName, opt.TypeField, timeStr, upper(opt.ErrorType)), ...
    %     'Interpreter','none', ...
    %     'FontSize', opt.FontSize);
    title(ax, sprintf('%s | rank%c ', ...
        neuronName, opt.TypeField(end)), ...
        'Interpreter','none', ...
        'FontSize', opt.FontSize);
end

% ----- save -----
h.files = {};

if opt.DoSave
    if isempty(opt.SaveDir)
        opt.SaveDir = pwd;
    end
    if ~exist(opt.SaveDir, 'dir')
        mkdir(opt.SaveDir);
    end

    safeNeuronName = regexprep(neuronName, '[^\w\d]', '_');

    fname = fullfile(opt.SaveDir, sprintf('%s_%s_%s.png', ...
        opt.FigurePrefix, safeNeuronName, opt.TypeField));

    exportgraphics(h.fig, fname, 'Resolution', 300);
    h.files{1} = fname;
end

% ----- outputs -----
h.ax        = ax;
h.meanResp  = meanResp;
h.errResp   = errResp;
h.responses = responses;
h.condIdx   = condIdx;
h.nPerCond  = nPerCond;
h.neuronName = neuronName;
h.pms       = opt;
end
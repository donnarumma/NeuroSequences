function h = plotPopulationCircle(FR, groupSize, plotTitle)
%PLOTPOPULATIONCIRCLE Polar plots of mean firing in circular groups.
%
% h = plotPopulationCircle(FR, groupSize, plotTitle)
%
% INPUT
%   FR         : can be
%                [N x 1]
%                [nTrials x N]
%                [nTrials x T x N]
%   groupSize  : default = 8
%   plotTitle  : optional title string
%
% OUTPUT
%   h          : struct with figure/axes handles

    if nargin < 2 || isempty(groupSize)
        groupSize = 8;
    end
    if nargin < 3
        plotTitle = 'Population circle plot';
    end

    sz = size(FR);

    if isvector(FR)
        meanFR = FR(:);

    elseif ndims(FR) == 2
        % [nTrials x N]
        meanFR = squeeze(mean(FR, 1))';
        meanFR = meanFR(:);

    elseif ndims(FR) == 3
        % [nTrials x T x N]
        meanFR = squeeze(mean(mean(FR, 2), 1))';
        meanFR = meanFR(:);

    else
        error('FR must be [N x 1], [nTrials x N], or [nTrials x T x N].');
    end

    N = numel(meanFR);

    if mod(N, groupSize) ~= 0
        error('Number of neurons/pops must be a multiple of groupSize.');
    end

    nGroups = N / groupSize;

    theta = linspace(0, 2*pi, groupSize + 1); % closed circle

    h.fig = figure('Color', 'w', 'Name', plotTitle);
    tl = tiledlayout(1, nGroups, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(tl, plotTitle);

    h.ax = gobjects(nGroups,1);

    for g = 1:nGroups
        idx = (g-1)*groupSize + (1:groupSize);
        r = meanFR(idx);
        r = [r; r(1)];  % close curve

        h.ax(g) = nexttile;
        polarplot(theta, r, '-o', 'LineWidth', 1.8, 'MarkerSize', 4);
        title(sprintf('Group %d', g));
    end
end
function hfg = Chen02_Exp(pathDir, ifplot)
%CHEN02_EXP Recreate the mixed target/cue panel shown in Fig05 panel B.
%
% hfg = Chen02_Exp(pathDir, ifplot)
% hfg = Chen02_Exp(ifplot)
%
% The figure follows the same spirit as Xie_Exp / Chen01_Exp, but renders
% a single mixed sequence row with panels S1, S2, Delay 1, Cue, Delay 2,
% plus the saccade instruction block on the right.
%
% INPUT
%   pathDir : output directory used when ifplot is false.
%             Default = /TESTS/HAI_SEQUENCES/Chen02/
%   ifplot  : when true, keep the figure visible and skip saving.
%             Default = true
%
% OUTPUT
%   hfg     : struct containing the figure handle in hfg.Chen02_Exp

if nargin < 1
    pathDir = [];
end
if nargin < 2
    ifplot = [];
end

if islogical(pathDir) || (isnumeric(pathDir) && isscalar(pathDir))
    ifplot = pathDir;
    pathDir = [];
end

if isempty(pathDir)
    pathDir = '/TESTS/HAI_SEQUENCES/Chen02/';
end
if isempty(ifplot)
    ifplot = true;
end

labels = {'$\uparrow$', '$\nearrow$', '$\searrow$', '$\downarrow$', '$\swarrow$', '$\nwarrow$'};
panelTitles = {'', '', '', '', ''};
stepLabels = {'S1', 'S2', 'Delay 1', 'Cue', 'Delay 2'};

style = build_style();

visibleFlag = 'off';
if ifplot
    visibleFlag = 'on';
end

hfg = struct();
hfg.Chen02_Exp = figure( ...
    'Visible', visibleFlag, ...
    'Color', 'w', ...
    'Name', 'Chen02_Exp', ...
    'Position', [80, 80, 2600, 560]);

layout = tiledlayout(hfg.Chen02_Exp, 1, 7, ...
    'TileSpacing', 'compact', ...
    'Padding', 'compact');
layout.Units = 'normalized';
layout.Position = [0.08, 0.18, 0.90, 0.68];

axS1 = nexttile(layout, 1);
draw_target_panel(axS1, labels, 1, 0, style.centerGreen, style, panelTitles{1});
add_step_label_below_axis(axS1, stepLabels{1}, style.stepFontSize);
add_mixed_label(axS1, style.mixedFontSize);

axS2 = nexttile(layout, 2);
draw_target_panel(axS2, labels, 2, 1, style.centerGreen, style, panelTitles{2});
add_step_label_below_axis(axS2, stepLabels{2}, style.stepFontSize);

axDelay1 = nexttile(layout, 3);
draw_target_panel(axDelay1, labels, 0, 1, style.centerGray, style, panelTitles{3});
add_step_label_below_axis(axDelay1, stepLabels{3}, style.stepFontSize);

axCue = nexttile(layout, 4);
draw_cue_panel(axCue, style);
add_step_label_below_axis(axCue, stepLabels{4}, style.stepFontSize);

axDelay2 = nexttile(layout, 5);
draw_target_panel(axDelay2, labels, 0, 1, style.centerGray, style, panelTitles{5});
add_step_label_below_axis(axDelay2, stepLabels{5}, style.stepFontSize);

axText = nexttile(layout, 6, [1 2]);
draw_saccades_panel(axText, style);

if ~ifplot
    assert_hfigprint_dependency();
    pathDir = expanduser_local(pathDir);
    if ~endsWith(pathDir, filesep)
        pathDir = [pathDir filesep];
    end
    if ~isfolder(pathDir)
        mkdir(pathDir);
    end

    printPms = hfigPrintParams();
    printPms.pdf_file = fullfile(pathDir, 'Chen02_Exp.pdf');
    printPms.save_dir = pathDir;
    hfigPrint(hfg, printPms);
end
end

function style = build_style()
style.peripheralGray = 0.86 * ones(1, 3);
style.highlightGray = 0.70 * ones(1, 3);
style.centerGray = 0.72 * ones(1, 3);
style.centerGreen = [0.00, 0.90, 0.10];
style.targetRed = [1.00, 0.05, 0.05];
style.edgeColor = [0, 0, 0];
style.edgeWidth = 3;
style.axisWidth = 4;
style.titleFontSize = 12;
style.stepFontSize = 34;
style.cueFontSize = 30;
style.mixedFontSize = 36;
style.saccadeFontSize = 28;
style.labelFontSize = 16;
end

function draw_target_panel(ax, labels, redTarget, grayTarget, centerColor, style, panelTitle)
cla(ax);
hold(ax, 'on');
box(ax, 'on');
axis(ax, 'equal');

nCircles = numel(labels);
theta = linspace(0, 2 * pi, nCircles + 1) + pi / 2;
theta = theta(end:-1:1);
theta(end) = [];

radius = 1;
circleRadius = 0.2;
points = nan(nCircles, 2);
faceColors = repmat(style.peripheralGray, nCircles, 1);

if grayTarget >= 1 && grayTarget <= nCircles
    faceColors(grayTarget, :) = style.highlightGray;
end
if redTarget >= 1 && redTarget <= nCircles
    faceColors(redTarget, :) = style.targetRed;
end

rectangle(ax, ...
    'Position', [-circleRadius, -circleRadius, 2 * circleRadius, 2 * circleRadius], ...
    'Curvature', [1, 1], ...
    'EdgeColor', style.edgeColor, ...
    'LineWidth', style.edgeWidth, ...
    'FaceColor', centerColor);

for iCircle = 1:nCircles
    x = radius * cos(theta(iCircle));
    y = radius * sin(theta(iCircle));
    points(iCircle, :) = [x, y];

    rectangle(ax, ...
        'Position', [x - circleRadius, y - circleRadius, 2 * circleRadius, 2 * circleRadius], ...
        'Curvature', [1, 1], ...
        'EdgeColor', style.edgeColor, ...
        'LineWidth', style.edgeWidth, ...
        'FaceColor', faceColors(iCircle, :));

    text(ax, x, y, labels{iCircle}, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', ...
        'Interpreter', 'latex', ...
        'FontSize', style.labelFontSize, ...
        'Color', [0.30, 0.30, 0.30]);
end

limits = build_square_limits(points, circleRadius);
xlim(ax, limits);
ylim(ax, limits);
xticks(ax, []);
yticks(ax, []);
grid(ax, 'off');
set(ax, ...
    'LineWidth', style.axisWidth, ...
    'XColor', style.edgeColor, ...
    'YColor', style.edgeColor);

if ~isempty(panelTitle)
    title(ax, panelTitle, ...
        'FontSize', style.titleFontSize, ...
        'FontWeight', 'bold', ...
        'Interpreter', 'none');
end

hold(ax, 'off');
end

function limits = build_square_limits(points, circleRadius)
xLimits = [min(points(:, 1)) - 2 * circleRadius, max(points(:, 1)) + 2 * circleRadius];
yLimits = [min(points(:, 2)) - 2 * circleRadius, max(points(:, 2)) + 2 * circleRadius];
limits = [min([xLimits, yLimits]), max([xLimits, yLimits])];
end

function draw_cue_panel(ax, style)
cla(ax);
axis(ax, 'equal');
box(ax, 'on');
xlim(ax, [0, 1]);
ylim(ax, [0, 1]);
xticks(ax, []);
yticks(ax, []);
grid(ax, 'off');
set(ax, ...
    'LineWidth', style.axisWidth, ...
    'XColor', style.edgeColor, ...
    'YColor', style.edgeColor);

text(ax, 0.5, 0.77, 'FORW.', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'FontSize', style.cueFontSize, ...
    'FontWeight', 'bold');
text(ax, 0.5, 0.49, 'or', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'FontSize', style.cueFontSize - 4, ...
    'FontWeight', 'bold');
text(ax, 0.5, 0.20, 'BACKW.', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'FontSize', style.cueFontSize, ...
    'FontWeight', 'bold');
end

function draw_saccades_panel(ax, style)
axis(ax, 'off');
xlim(ax, [0, 1]);
ylim(ax, [0, 1]);

text(ax, 0.02, 0.74, 'Saccades to targets', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'middle', ...
    'FontSize', style.saccadeFontSize, ...
    'FontWeight', 'bold');
text(ax, 0.02, 0.51, 'A, B (if forward) or', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'middle', ...
    'FontSize', style.saccadeFontSize, ...
    'FontWeight', 'bold');
text(ax, 0.02, 0.28, 'B, A (if backward)', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'middle', ...
    'FontSize', style.saccadeFontSize, ...
    'FontWeight', 'bold');
end

function add_mixed_label(ax, fontSize)
xLimits = xlim(ax);
yLimits = ylim(ax);
xLeft = xLimits(1) - 0.38 * range(xLimits);
yCenter = mean(yLimits);

text(ax, xLeft, yCenter, 'MIXED', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'Rotation', 90, ...
    'FontSize', fontSize, ...
    'FontWeight', 'bold', ...
    'Clipping', 'off');
end

function add_step_label_below_axis(ax, labelText, fontSize)
xLimits = xlim(ax);
yLimits = ylim(ax);
xCenter = mean(xLimits);
yBelow = yLimits(1) - 0.17 * range(yLimits);

text(ax, xCenter, yBelow, labelText, ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'top', ...
    'FontSize', fontSize, ...
    'FontWeight', 'bold', ...
    'Clipping', 'off');
end

function assert_hfigprint_dependency()
if exist('hfigPrint', 'file') ~= 2 || exist('hfigPrintParams', 'file') ~= 2
    error('Chen02_Exp:MissingDependency', ...
        ['hfigPrint and hfigPrintParams are required on the MATLAB path. ' ...
         'Run setup_HAI_DEV or add the relevant utilities folder first.']);
end
end

function pathStr = expanduser_local(pathStr)
if startsWith(pathStr, '~')
    homeDir = getenv('HOME');
    if isempty(homeDir)
        homeDir = char(java.lang.System.getProperty('user.home'));
    end
    pathStr = fullfile(homeDir, pathStr(2:end));
end
end

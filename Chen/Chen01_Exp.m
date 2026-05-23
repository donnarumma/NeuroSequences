function hfg = Chen01_Exp(targetGrid, pathDir, ifplot)
%CHEN_EXP Generate a two-row target-sequence figure in the Xie_Exp style.
%
% hfg = Chen01_Exp(targetGrid, pathDir, ifplot)
% hfg = Chen01_Exp(pathDir, ifplot)
%
% The figure is arranged as a simple 2x5 grid. Each row contains S1, S2,
% S3, Delay, and a text panel rendered in the Xie_Exp style. Direction
% labels are added separately beside the first target panel.
%
% INPUT
%   targetGrid : 2x4 matrix of target indices. Use 0 for Delay panels with
%                all circles gray. Default = [1 2 3 0; 3 2 1 0]
%   pathDir    : output directory used when ifplot is false.
%                Default = /TESTS/HAI_SEQUENCES/Chen01/
%   ifplot     : when true, keep the figure visible and skip saving.
%                Default = true
%
% OUTPUT
%   hfg        : struct containing the figure handle in hfg.Chen_Exp
% EXAMPLE
%   hfg = Chen01_Exp([1 2 3 0; 3 2 1 0]); % ABC in forward and backward order, then Delay panel
%   hfg = Chen01_Exp([1 2 0 0; 2 1 0 0]); % AB in forward and backward order, with no target panel in S3, then Delay panel
if nargin < 1
    targetGrid = [];
end
if nargin < 2
    pathDir = [];
end
if nargin < 3
    ifplot = [];
end

% Backward-compatible calls:
%   Chen_Exp(pathDir, ifplot)
if ischar(targetGrid) || isstring(targetGrid)
    ifplot = pathDir;
    pathDir = targetGrid;
    targetGrid = [];
elseif (islogical(pathDir) || (isnumeric(pathDir) && isscalar(pathDir)))
    ifplot = pathDir;
    pathDir = [];
end

if isempty(targetGrid)
    targetGrid = [1 2 3 0; 3 2 1 0];
end
if isempty(pathDir)
    pathDir = '/TESTS/HAI_SEQUENCES/Chen01/';
end
if isempty(ifplot)
    ifplot = true;
end

labels = {'$\uparrow$', '$\nearrow$', '$\searrow$', '$\downarrow$', '$\swarrow$', '$\nwarrow$'};
stepLabels = {'S1', 'S2', 'S3', 'Delay'};
directionFontSize = 54;
stepFontSize = 50;
saccadeFontSize = 50;

validate_target_grid(targetGrid, numel(labels));

visibleFlag = 'off';
if ifplot
    visibleFlag = 'on';
end

hfg = struct();

ChenFig = figure( ...
    'Visible', visibleFlag, ...
    'Color', 'w', ...
    'Name', 'Chen_Exp_Targets', ...
    'Position', [80, 50, 2500, 980]);

layout = tiledlayout(ChenFig, 2, 5, ...
    'TileSpacing', 'loose', ...
    'Padding', 'compact');
% hfg.layout = layout;
layout.Units = 'normalized';
layout.Position = [0.15, 0.06, 0.83, 0.88];

for iRow = 1:2
    for iCol = 1:4
        ax = nexttile(layout, (iRow - 1) * 5 + iCol);
        set(ChenFig, 'CurrentAxes', ax);

        par = struct();
        par.hfig = ChenFig;
        par.labels = labels;
        par.target = targetGrid(iRow, iCol);
        plotCircles(par);

        add_step_label_below_axis(ax, stepLabels{iCol}, stepFontSize);

        if iCol == 1
            if iRow == 1
                add_row_direction_label(ax, 'FORWARD.', directionFontSize);
            else
                add_row_direction_label(ax, 'BACKWARD', directionFontSize);
            end
        end
    end

    axText = nexttile(layout, iRow * 5);
    add_saccades_to_panel(axText, build_target_text(targetGrid(iRow, :)), saccadeFontSize);
end
hfg.Chen01_Exp = ChenFig;
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
    % printPms.pdf_file = fullfile(pathDir, 'Chen01_Exp.pdf');
    printPms.save_dir = pathDir;
    hfigPrint(hfg, printPms);
end
end

function validate_target_grid(targetGrid, nTargets)
if ~isnumeric(targetGrid) || ~isequal(size(targetGrid), [2, 4])
    error('Chen_Exp:InvalidTargetGridSize', ...
        'targetGrid must be a numeric 2x4 matrix.');
end

if any(targetGrid(:) < 0) || any(targetGrid(:) > nTargets) || any(targetGrid(:) ~= floor(targetGrid(:)))
    error('Chen_Exp:InvalidTargetIds', ...
        'targetGrid values must be integers between 0 and %d.', nTargets);
end
end

function targetText = build_target_text(targetIds)
targetIds = targetIds(targetIds > 0);
targetLetters = arrayfun(@target_id_to_letter, targetIds, 'UniformOutput', false);
targetText = ['targets ' strjoin(targetLetters, ', ')];
end

function targetLetter = target_id_to_letter(targetId)
targetLetter = char('A' + targetId - 1);
end

function add_saccades_to_panel(ax, targetText, fontSize)
axis(ax, 'off');
xlim(ax, [0, 1]);
ylim(ax, [0, 1]);

text(ax, 0.58, 0.5, {'Saccades to', targetText}, ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'FontSize', fontSize, ...
    'FontWeight', 'bold');
end

function add_row_direction_label(ax, labelText, fontSize)
xLimits = xlim(ax);
yLimits = ylim(ax);
xLeft = xLimits(1) - 0.35 * range(xLimits);
yCenter = mean(yLimits);

text(ax, xLeft, yCenter, labelText, ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'Rotation', 90, ...
    'FontSize', fontSize, ...
    'FontWeight', 'bold', ...
    'Interpreter', 'none', ...
    'Clipping', 'off');
end

function add_step_label_below_axis(ax, labelText, fontSize)
xLimits = xlim(ax);
yLimits = ylim(ax);
xCenter = mean(xLimits);
yBelow = yLimits(1) - 0.05 * range(yLimits);

text(ax, xCenter, yBelow, labelText, ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'top', ...
    'FontSize', fontSize, ...
    'FontWeight', 'bold', ...
    'Clipping', 'off');
end

function assert_hfigprint_dependency()
if exist('hfigPrint', 'file') ~= 2 || exist('hfigPrintParams', 'file') ~= 2
    error('Chen_Exp:MissingDependency', ...
        ['hfigPrint and hfigPrintParams are required on the MATLAB path. ' ...
         'add HAI_LANGUAGE git or add the relevant utilities folder first.']);
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

function hfg = Xie_Exp(targetIds, pathDir, ifplot)
%XIE_EXP Generate the Xie target-sequence figure.
%
% hfg = Xie_Exp(targetIds, pathDir, ifplot)
% hfg = Xie_Exp(pathDir, ifplot)
%
% The figure shows the requested targets side-by-side plus Target0, where
% all circles are gray. Sequence labels are shown below the target panels.
%
% INPUT
%   targetIds : target sequence to render. Target 1 maps to A, target 2 to B,
%               etc. Default = 1:3.
%   pathDir : output directory used when ifplot is false.
%             Default = /TESTS/HAI_SEQUENCES/Xie/
%   ifplot  : when true, keep the figure visible and skip saving.
%             Default = true
%
% OUTPUT
%   hfg     : struct containing the figure handle in hfg.Xie_Exp
% EXAMPLE
%   hfg = Xie_Exp(1:3);
if nargin < 1
    targetIds = [];
end
if nargin < 2
    pathDir = [];
end
if nargin < 3
    ifplot = [];
end

% Backward-compatible calls:
%   Xie_Exp(pathDir, ifplot)
%   Xie_Exp(targetIds, ifplot)
if ischar(targetIds) || isstring(targetIds)
    ifplot = pathDir;
    pathDir = targetIds;
    targetIds = [];
elseif (islogical(pathDir) || (isnumeric(pathDir) && isscalar(pathDir)))
    ifplot = pathDir;
    pathDir = [];
end

if isempty(pathDir)
    pathDir = '/TESTS/HAI_SEQUENCES/Xie/';
end
if isempty(ifplot)
    ifplot = true;
end

labels = {'$\uparrow$', '$\nearrow$', '$\searrow$', '$\downarrow$', '$\swarrow$', '$\nwarrow$'};
if isempty(targetIds)
    targetIds = 1:3;
end
targetIds = targetIds(:).';
validate_target_ids(targetIds, numel(labels));

panelTargetIds = [targetIds, 0];
stepLabels = arrayfun(@(iStep) sprintf('S%d', iStep), 1:numel(targetIds), 'UniformOutput', false);
stepLabels{end + 1} = 'Delay';
targetText = build_target_text(targetIds);

visibleFlag = 'off';
if ifplot
    visibleFlag = 'on';
end

hfg = struct();
hfg.Xie_Exp = figure( ...
    'Visible', visibleFlag, ...
    'Color', 'w', ...
    'Name', 'Xie_Exp_Targets', ...
    'Position', [80, 50, 2200, 560]);

layout = tiledlayout(hfg.Xie_Exp, 1, numel(panelTargetIds) + 1, ...
    'TileSpacing', 'compact', ...
    'Padding', 'loose');

for iPanel = 1:numel(panelTargetIds)
    iTarget = panelTargetIds(iPanel);
    ax = nexttile(layout);
    set(hfg.Xie_Exp, 'CurrentAxes', ax);

    par = struct();
    par.hfig = hfg.Xie_Exp;
    par.labels = labels;
    par.target = iTarget;
    plotCircles(par);

    if ~isempty(stepLabels{iPanel})
        add_step_label_below_axis(ax, stepLabels{iPanel});
    end
end

axText = nexttile(layout);
add_saccades_to_panel(axText, targetText);

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
    printPms.pdf_file = [pathDir 'Xie_Exp.pdf'];
    printPms.save_dir = pathDir;
    hfigPrint(hfg, printPms);
end
end

function validate_target_ids(targetIds, nTargets)
if any(targetIds < 1) || any(targetIds > nTargets) || any(targetIds ~= floor(targetIds))
    error('Xie_Exp:InvalidTargetIds', ...
        'targetIds must contain integer values between 1 and %d.', nTargets);
end
end

function targetText = build_target_text(targetIds)
targetLetters = arrayfun(@target_id_to_letter, targetIds, 'UniformOutput', false);
targetText = ['targets ' strjoin(targetLetters, ', ')];
end

function targetLetter = target_id_to_letter(targetId)
targetLetter = char('A' + targetId - 1);
end

function add_saccades_to_panel(ax, targetText)
axis(ax, 'off');
xlim(ax, [0, 1]);
ylim(ax, [0, 1]);

text(ax, 0.58, 0.5, {'Saccades to', targetText}, ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'FontSize', 42, ...
    'FontWeight', 'bold');
end

function add_step_label_below_axis(ax, labelText)
% Place large bold labels below the axes without changing the target scale.

xLimits = xlim(ax);
yLimits = ylim(ax);
xCenter = mean(xLimits);
yBelow = yLimits(1) - 0.16 * range(yLimits);

text(ax, xCenter, yBelow, labelText, ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'top', ...
    'FontSize', 48, ...
    'FontWeight', 'bold', ...
    'Clipping', 'off');
end

function assert_hfigprint_dependency()
if exist('hfigPrint', 'file') ~= 2 || exist('hfigPrintParams', 'file') ~= 2
    error('Xie_Exp:MissingDependency', ...
        ['hfigPrint and hfigPrintParams are required on the MATLAB path ' ...
         'when ifplot is false. Run setup_HAI_DEV or add the relevant ' ...
         'utilities folder first.']);
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

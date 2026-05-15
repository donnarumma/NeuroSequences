function hfg = Chen02_FwdBwd(pathDir, ifplot)
%CHEN02_FWDBWD Recreate Chen02 panel with save/plot options.

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

% Replicate memory decoding panel with:
% - initial pre-delay/training part always green until the vertical dashed line
% - row-dependent Training/Test background after the dashed line
% - black axes/ticks
% - moving decoding curves mostly between 0.1 and 0.5
% - horizontal state line at y=0.55 only where a curve exceeds 0.4
% - dominant curves ending above 0.4 so that a state line is active at the end
% - richer/noisier trajectories

rng(7); % reproducible noise

% -----------------------------
% Parameters
% -----------------------------
x = linspace(0, 1, 180);

% Match the first two Chen02 simulation colors used in MAIN_Chen02_S2_FwBw_Exp:
% A(1) ~= orange-red, B(2) ~= purple.
green = [0.8500 0.3250 0.0980];
red   = [0.4940 0.1840 0.5560];

bgTraining = [0.95 0.985 0.95];   % light green
bgTest     = [0.995 0.955 0.94];  % light red

lineW = 3.2;
stateLineW = 1.0;

thresholdY = 0.40;
stateY     = 0.55;

preDelayEnd = 0.22;

% Rows:
% 1 = AB Forward   Training
% 2 = BA Backward  Test
% 3 = BA Backward  Training
% 4 = AB Forward   Test
rowNames = {'AB', 'BA', 'BA', 'AB'};
rowTypes = {'Forward', 'Backward', 'Backward', 'Forward'};
rowIsTraining = [true false true false];

Y = cell(4,2);

% -----------------------------
% Helper functions
% -----------------------------
smoothStep = @(x,c,k) 1 ./ (1 + exp(-k*(x-c)));

makeNoise = @(scale) smoothdata(scale * randn(size(x)), 'gaussian', 13);

wiggle = @(phase, amp) ...
    amp * sin(2*pi*(1.4*x + phase)) + ...
    0.5*amp * sin(2*pi*(3.1*x + 0.4*phase)) + ...
    0.35*amp * sin(2*pi*(5.2*x + 0.7*phase));

clipRange = @(y) min(max(y, 0.08), 0.52);

% -----------------------------
% Curves
% -----------------------------
% Curves live mostly between 0.1 and 0.5.
% The state line at 0.55 appears when curves exceed 0.4.

% Row 1: AB Forward / Training
Y{1,1}.g = 0.46 - 0.04*x + wiggle(0.1, 0.018) + makeNoise(0.007);
Y{1,1}.r = 0.10 + 0.025*(1-exp(-7*x)) + wiggle(0.5, 0.006) + makeNoise(0.003);

Y{1,2}.g = 0.10 + 0.022*(1-exp(-7*x)) + wiggle(0.2, 0.005) + makeNoise(0.003);
Y{1,2}.r = 0.47 - 0.04*x + wiggle(0.6, 0.014) + makeNoise(0.006);

% Row 2: BA Backward / Test
Y{2,1}.g = 0.45 - 0.35*smoothStep(x,0.31,32) + wiggle(0.2, 0.015) + makeNoise(0.006);
Y{2,1}.r = 0.10 + 0.35*smoothStep(x,0.30,32) + wiggle(0.8, 0.016) + makeNoise(0.007);

Y{2,2}.g = 0.10 + 0.34*smoothStep(x,0.34,28) + wiggle(0.4, 0.014) + makeNoise(0.006);
Y{2,2}.r = 0.45 - 0.34*smoothStep(x,0.31,32) + wiggle(0.1, 0.014) + makeNoise(0.006);

% Row 3: BA Backward / Training
Y{3,1}.g = 0.47 - 0.36*smoothStep(x,0.31,30) + wiggle(0.7, 0.017) + makeNoise(0.007);
Y{3,1}.r = 0.11 + 0.35*smoothStep(x,0.30,31) + wiggle(0.3, 0.017) + makeNoise(0.007);

Y{3,2}.g = 0.10 + 0.34*smoothStep(x,0.34,28) + wiggle(0.9, 0.014) + makeNoise(0.006);
Y{3,2}.r = 0.47 - 0.31*smoothStep(x,0.31,28) + wiggle(0.2, 0.015) + makeNoise(0.006);

% Row 4: AB Forward / Test
Y{4,1}.g = 0.47 - 0.045*x + wiggle(0.4, 0.018) + makeNoise(0.007);
Y{4,1}.r = 0.10 + 0.025*(1-exp(-7*x)) + wiggle(0.7, 0.005) + makeNoise(0.003);

Y{4,2}.g = 0.10 + 0.025*(1-exp(-7*x)) + wiggle(0.6, 0.005) + makeNoise(0.003);
Y{4,2}.r = 0.47 - 0.045*x + wiggle(0.1, 0.015) + makeNoise(0.006);

% Clip curves
for r = 1:4
    for c = 1:2
        Y{r,c}.g = clipRange(Y{r,c}.g);
        Y{r,c}.r = clipRange(Y{r,c}.r);
    end
end

visibleFlag = 'off';
if ifplot
    visibleFlag = 'on';
end

% -----------------------------
% Figure layout
% -----------------------------
hfg = struct();
hfg.Chen02_FwdBwd = figure( ...
    'Visible', visibleFlag, ...
    'Color', 'w', ...
    'Name', 'Chen02_FwdBwd', ...
    'Position', [200 80 500 660]);
fig = hfg.Chen02_FwdBwd;

left0 = 0.33;
bottom0 = 0.30;
axW = 0.24;
axH = 0.13;
gapX = 0.13;
gapY = 0.035;

axs = gobjects(4,2);

for r = 1:4
    for c = 1:2

        left = left0 + (c-1)*(axW + gapX);
        bottom = bottom0 + (4-r)*(axH + gapY);

        ax = axes('Position',[left bottom axW axH]);
        axs(r,c) = ax;
        hold(ax,'on');

        yg = Y{r,c}.g;
        yr = Y{r,c}.r;

        % Row-dependent Training/Test background.
        % Rows 1 and 3 are Training; rows 2 and 4 are Test.
        if rowIsTraining(r)
            ax.Color = bgTraining;
        else
            ax.Color = bgTest;
        end

        % Initial pre-delay/training band: always green until the vertical dashed line.
        % This overrides the red Test background in the initial part.
        patch(ax, ...
            [0 preDelayEnd preDelayEnd 0], ...
            [0.05 0.05 0.62 0.62], ...
            bgTraining, ...
            'EdgeColor','none', ...
            'FaceAlpha',1.0);

        % Moving decoding curves
        plot(ax, x, yg, 'Color', green, 'LineWidth', lineW);
        plot(ax, x, yr, 'Color', red,   'LineWidth', lineW);

        % State lines at y = 0.55.
        % Draw only where the corresponding moving curve is above 0.4.
        drawSegmentedStateLine(ax, x, yg > thresholdY, stateY, green, stateLineW);
        drawSegmentedStateLine(ax, x, yr > thresholdY, stateY, red,   stateLineW);

        % Late-delay marker
        xline(ax, 0.72, '--', ...
            'Color', 'k', ...
            'LineWidth', 0.8);

        ylim(ax, [0.05 0.62]);
        xlim(ax, [0 1]);

        ax.YTick = [0.1 0.5];
        ax.XTick = [];

        ax.FontSize = 12;
        ax.LineWidth = 0.8;
        ax.Box = 'on';
        ax.TickDir = 'out';

        % Black ticks and black axes
        ax.XColor = 'k';
        ax.YColor = 'k';

        % Only show y tick labels on left column
        if c == 2
            ax.YTickLabel = [];
        end

        % Hide x tick labels everywhere
        ax.XTickLabel = [];

        % Draw an explicit black frame on top so every panel has the same box.
        rectangle(ax, ...
            'Position', [0, 0.05, 1, 0.62 - 0.05], ...
            'EdgeColor', 'k', ...
            'LineWidth', 0.8);

        % Center the Delay 2 label below the bottom panels.
        if r == 4
            xlabel(ax, 'Delay 2', ...
                'FontSize', 14, ...
                'FontAngle', 'italic', ...
                'FontWeight', 'normal', ...
                'Color', [0.10 0.10 0.10]);

            ax.XLabel.Units = 'normalized';
            ax.XLabel.Position(1) = 0.50;
            ax.XLabel.Position(2) = -0.18;
        end
    end
end

% -----------------------------
% Column titles
% -----------------------------
annotation(fig, 'textbox', [left0 0.94 axW 0.04], ...
    'String','Memory-1', ...
    'EdgeColor','none', ...
    'HorizontalAlignment','center', ...
    'FontSize',16, ...
    'FontWeight','bold');

annotation(fig, 'textbox', [left0+axW+gapX 0.94 axW 0.04], ...
    'String','Memory-2', ...
    'EdgeColor','none', ...
    'HorizontalAlignment','center', ...
    'FontSize',16, ...
    'FontWeight','bold');

% Horizontal divider between the top and bottom 2x2 blocks
annotation(fig, 'line', ...
    [0.07, left0 + 2*axW + gapX + 0.02], ...
    [bottom0 + 2*axH + 1.5*gapY, bottom0 + 2*axH + 1.5*gapY], ...
    'Color', 'k', ...
    'LineWidth', 0.8);

% -----------------------------
% Left labels
% -----------------------------
for r = 1:4
    bottom = bottom0 + (4-r)*(axH + gapY);

    annotation(fig, 'textbox', [0.075 bottom+0.050 0.05 0.08], ...
        'String', rowNames{r}, ...
        'EdgeColor','none', ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','middle', ...
        'Rotation',90, ...
        'FontSize',14, ...
        'FontWeight','bold');

    annotation(fig, 'textbox', [0.185 bottom+0.040 0.07 0.11], ...
        'String', rowTypes{r}, ...
        'EdgeColor','none', ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','middle', ...
        'Rotation',90, ...
        'FontSize',13, ...
        'FontWeight','bold');
end

% Shared decoding/accuracy labels, one per 2-row block
topBlockBottom = bottom0 + 2*(axH + gapY);
bottomBlockBottom = bottom0;

add_shared_decoding_label(fig, topBlockBottom, axH, gapY);
add_shared_decoding_label(fig, bottomBlockBottom, axH, gapY);

% -----------------------------
% Bottom legend
% -----------------------------

% Training/Test background legend
annotation(fig, 'rectangle', [0.32 0.16 0.07 0.04], ...
    'FaceColor', bgTraining, ...
    'EdgeColor', [0.88 0.92 0.88]);

annotation(fig, 'textbox', [0.41 0.155 0.18 0.05], ...
    'String','Training', ...
    'EdgeColor','none', ...
    'FontSize',14, ...
    'FontAngle','italic');

annotation(fig, 'rectangle', [0.32 0.10 0.07 0.04], ...
    'FaceColor', bgTest, ...
    'EdgeColor', [0.94 0.88 0.86]);

annotation(fig, 'textbox', [0.41 0.095 0.18 0.05], ...
    'String','Test', ...
    'EdgeColor','none', ...
    'FontSize',14, ...
    'FontAngle','italic');

% Line legend
annotation(fig, 'textbox', [0.70 0.16 0.09 0.05], ...
    'String','A(1)', ...
    'EdgeColor','none', ...
    'FontSize',14);

annotation(fig, 'line', [0.80 0.92], [0.184 0.184], ...
    'Color', green, ...
    'LineWidth', lineW);

annotation(fig, 'textbox', [0.70 0.10 0.09 0.05], ...
    'String','B(2)', ...
    'EdgeColor','none', ...
    'FontSize',14);

annotation(fig, 'line', [0.80 0.92], [0.124 0.124], ...
    'Color', red, ...
    'LineWidth', lineW);

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
    printPms.pdf_file = fullfile(pathDir, 'Chen02_FwdBwd.pdf');
    printPms.save_dir = pathDir;
    hfigPrint(hfg, printPms);
end

end


function drawSegmentedStateLine(ax, x, mask, yval, colorVal, lineW)
% Draw a horizontal line at yval only over contiguous regions where mask is true.

mask = logical(mask(:)');
x = x(:)';

if ~any(mask)
    return;
end

d = diff([false mask false]);
starts = find(d == 1);
stops  = find(d == -1) - 1;

for iSeg = 1:numel(starts)
    idx = starts(iSeg):stops(iSeg);

    % Avoid tiny noisy fragments
    if numel(idx) < 3
        continue;
    end

    plot(ax, x(idx), yval * ones(size(idx)), ...
        '-', ...
        'Color', colorVal, ...
        'LineWidth', lineW);
end

end

function add_shared_decoding_label(fig, blockBottom, axH, gapY)
annotation(fig, 'textbox', [0.275 blockBottom + axH + gapY + 0.020 0.06 0.12], ...
    'String', 'accuracy', ...
    'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'Rotation', 90, ...
    'FontSize', 13, ...
    'FontAngle', 'italic');

annotation(fig, 'textbox', [0.275 blockBottom + 0.065 0.06 0.12], ...
    'String', 'Decoding', ...
    'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'Rotation', 90, ...
    'FontSize', 13, ...
    'FontAngle', 'italic');
end

function assert_hfigprint_dependency()
if exist('hfigPrint', 'file') ~= 2 || exist('hfigPrintParams', 'file') ~= 2
    error('Chen02_FwdBwd:MissingDependency', ...
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

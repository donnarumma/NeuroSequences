function hfg = Mushiake_Spikes(pathDir, ifplot)
%MUSHIAKE_SPIKES Draw a MATLAB recreation of Mushiake Fig02 panel A.
%
% hfg = Mushiake_Spikes(pathDir, ifplot)
% hfg = Mushiake_Spikes(ifplot)
%
% This is a figure-only script. It does not run the computational model:
% it recreates the panel layout and stylized spike-density traces from the
% published figure using MATLAB graphics primitives.
%
% INPUT
%   pathDir : output directory used when ifplot is false.
%             Default = /TESTS/HAI_SEQUENCES/Mushiake/
%   ifplot  : when true, keep the figure visible and skip saving.
%             Default = true
%
% OUTPUT
%   hfg     : struct containing the figure handle in hfg.Mushiake_Spikes

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
    pathDir = '/TESTS/HAI_SEQUENCES/Mushiake/';
end
if isempty(ifplot)
    ifplot = true;
end

visibleFlag = 'off';
if ifplot
    visibleFlag = 'on';
end

style = mushiake_spike_style();
panelSpec = build_panel_spec();

hfg = struct();
hfg.Mushiake_Spikes = figure( ...
    'Visible', visibleFlag, ...
    'Color', 'w', ...
    'Name', 'Mushiake_Spikes', ...
    'Position', [80, 60, 1900, 1068]);

panelAxes = cell(3, 2, 6);
for iGroup = 1:3
    for iCol = 1:2
        for iRow = 1:6
            panelPos = get_panel_position(iGroup, iCol, iRow, style);
            ax = axes('Parent', hfg.Mushiake_Spikes, ...
                'Units', 'normalized', ...
                'Position', panelPos, ...
                'Box', 'on', ...
                'Color', 'w', ...
                'XColor', style.panelEdgeColor, ...
                'YColor', style.panelEdgeColor, ...
                'LineWidth', style.panelLineWidth, ...
                'XTick', [], ...
                'YTick', []);

            draw_spike_panel(ax, ...
                panelSpec(iGroup).labels{iCol}{iRow}, ...
                panelSpec(iGroup).patterns{iCol}{iRow}, ...
                style, ...
                iGroup, iCol, iRow);
            panelAxes{iGroup, iCol, iRow} = ax;
        end
    end
end

overlay = axes('Parent', hfg.Mushiake_Spikes, ...
    'Units', 'normalized', ...
    'Position', [0, 0, 1, 1], ...
    'Color', 'none', ...
    'XLim', [0, 1], ...
    'YLim', [0, 1], ...
    'Visible', 'off', ...
    'HitTest', 'off');
hold(overlay, 'on');

draw_group_titles(overlay, panelSpec, style);
draw_group_separators(overlay, style);
draw_go_labels(overlay, style);
draw_scale_bar(overlay, style);

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
    printPms.pdf_file = fullfile(pathDir, 'Mushiake_Spikes.pdf');
    printPms.save_dir = pathDir;
    hfigPrint(hfg, printPms);
end
end

function style = mushiake_spike_style()
style.groupX = [0.105, 0.355, 0.605];
style.groupWidth = 0.205;
style.colGap = 0.02;
style.rowGap = 0.018;
style.panelTop = 0.84;
style.panelWidth = (style.groupWidth - style.colGap) / 2;
style.panelHeight = 0.088;
style.panelEdgeColor = [0.65, 0.65, 0.65];
style.panelLineWidth = 1.0;
style.traceColor = [0, 0, 0];
style.dashedX = 0.51;
style.dashedColor = [0.25, 0.25, 0.25];
style.labelX = style.dashedX / 2;
style.goAnchorX = style.dashedX;
style.labelY = 0.80;
style.labelCharSpacing = 0.108;
style.labelUnderlineHalfWidth = 0.040;
style.labelUnderlineYOffset = 0.158;
style.labelUnderlineLineWidth = 2.2;
style.baselineY = 0.06;
style.titleY = 0.905;
style.titleFontSize = 32;
style.labelFontSize = 20;
style.goFontSize = 26;
style.scaleFontSize = 24;
style.separatorX = [0.328, 0.578];
style.separatorY = [0.095, 0.94];
style.scaleBase = [0.434, 0.092];
style.scaleBarLength = 0.026;
style.scaleBarHeight = 0.028;
end

function panelSpec = build_panel_spec()
panelSpec(1).title = {'1^{st} cursor-motion', 'selective neurons'};
panelSpec(1).labels = { ...
    {'LLU', 'LUL', 'ULL', 'LLD', 'LDL', 'DLL'}, ...
    {'RRU', 'RUR', 'URR', 'RRD', 'RDR', 'DRR'}};
panelSpec(1).patterns = { ...
    {'flat', 'flat', 'flat', 'flat', 'flat', 'flat'}, ...
    {'peak_tail', 'peak_tail', 'flat', 'peak', 'peak_tail', 'flat'}};

panelSpec(2).title = {'2^{nd} cursor-motion', 'selective neurons'};
panelSpec(2).labels = { ...
    {'UUL', 'ULU', 'LUU', 'DDL', 'DLD', 'LDD'}, ...
    {'UUR', 'URU', 'RUU', 'DDR', 'DRD', 'RDD'}};
panelSpec(2).patterns = { ...
    {'flat', 'peak_small', 'flat', 'flat', 'peak_small', 'flat'}, ...
    {'flat', 'flat', 'flat', 'flat', 'flat', 'flat'}};

panelSpec(3).title = {'3^{rd} cursor-motion', 'selective neurons'};
panelSpec(3).labels = { ...
    {'UUL', 'ULU', 'LUU', 'DDL', 'DLD', 'LDD'}, ...
    {'UUR', 'URU', 'RUU', 'DDR', 'DRD', 'RDD'}};
panelSpec(3).patterns = { ...
    {'peak_small', 'flat', 'flat', 'peak_small', 'flat', 'flat'}, ...
    {'flat', 'flat', 'flat', 'flat', 'flat', 'flat'}};
end

function panelPos = get_panel_position(iGroup, iCol, iRow, style)
x0 = style.groupX(iGroup) + (iCol - 1) * (style.panelWidth + style.colGap);
y0 = style.panelTop - iRow * style.panelHeight - (iRow - 1) * style.rowGap;
panelPos = [x0, y0, style.panelWidth, style.panelHeight];
end

function draw_spike_panel(ax, labelText, patternName, style, iGroup, iCol, iRow)
x = linspace(0, 1, 240);
baseline = compute_baseline(x, iGroup, iCol, iRow, style.baselineY);
y = baseline;

switch patternName
    case 'flat'
        q = resolve_quiet_params(iGroup, iCol, iRow);
        y = add_quiet_trace(x, baseline, q.rippleAmp, q.noiseAmp, q.phase);
    case 'peak'
        p = resolve_peak_params(patternName, iGroup, iCol, iRow);
        y = add_peak_trace(x, baseline, ...
            p.amp, p.center, p.width, p.tailAmp, p.tailPhase, p.rippleAmp, p.noiseAmp);
    case 'peak_tail'
        p = resolve_peak_params(patternName, iGroup, iCol, iRow);
        y = add_peak_trace(x, baseline, ...
            p.amp, p.center, p.width, p.tailAmp, p.tailPhase, p.rippleAmp, p.noiseAmp);
    case 'peak_small'
        p = resolve_peak_params(patternName, iGroup, iCol, iRow);
        y = add_peak_trace(x, baseline, ...
            p.amp, p.center, p.width, p.tailAmp, p.tailPhase, p.rippleAmp, p.noiseAmp);
    otherwise
        error('Mushiake_Spikes:UnknownPattern', ...
            'Unknown panel pattern: %s', patternName);
end

hold(ax, 'on');
fill_activity_area(ax, x, baseline, y, style.traceColor);
plot(ax, x, max(y, baseline), 'Color', style.traceColor, 'LineWidth', 1.4);
xline(ax, style.dashedX, '--', 'Color', style.dashedColor, 'LineWidth', 1.6);

draw_sequence_label(ax, labelText, iGroup, style);

xlim(ax, [0, 1]);
ylim(ax, [0, 1]);
end

function draw_sequence_label(ax, labelText, highlightIndex, style)
letters = char(labelText);
nLetters = numel(letters);
xPositions = style.labelX + ((1:nLetters) - (nLetters + 1) / 2) * style.labelCharSpacing;
highlightIndex = resolve_highlight_index(letters, highlightIndex);

for iLetter = 1:nLetters
    fontWeight = 'normal';
    if iLetter == highlightIndex
        fontWeight = 'bold';
    end

    text(ax, xPositions(iLetter), style.labelY, letters(iLetter), ...
        'Units', 'normalized', ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', ...
        'FontSize', style.labelFontSize, ...
        'FontWeight', fontWeight, ...
        'Interpreter', 'none');

    if iLetter == highlightIndex
        yUnderline = style.labelY - style.labelUnderlineYOffset;
        plot(ax, ...
            [xPositions(iLetter) - style.labelUnderlineHalfWidth, xPositions(iLetter) + style.labelUnderlineHalfWidth], ...
            [yUnderline, yUnderline], ...
            'Color', 'k', ...
            'LineWidth', style.labelUnderlineLineWidth);
    end
end
end

function highlightIndex = resolve_highlight_index(letters, iGroup)
highlightIndex = 0;

switch iGroup
    case 1
        if numel(letters) >= 1 && letters(1) == 'R'
            highlightIndex = 1;
        end
    case 2
        if numel(letters) >= 2 && letters(2) == 'L'
            highlightIndex = 2;
        end
    case 3
        if numel(letters) >= 3 && letters(3) == 'L'
            highlightIndex = 3;
        end
end
end

function baseline = compute_baseline(x, iGroup, iCol, iRow, baselineY)
phase = 0.7 * iGroup + 0.31 * iCol + 0.17 * iRow;
wiggle = 0.004 * sin(2 * pi * (2.1 * x + phase)) ...
       + 0.002 * sin(2 * pi * (7.8 * x + 0.5 * phase));
baseline = baselineY + wiggle;
end

function q = resolve_quiet_params(iGroup, iCol, iRow)
q.rippleAmp = 0.0136 + 0.0011 * iGroup;
q.noiseAmp = 0.0116 + 0.0010 * iCol;
q.phase = 0.41 * iRow + 0.23 * iCol + 0.17 * iGroup;
end

function p = resolve_peak_params(patternName, iGroup, iCol, iRow)
rowOffsets = [0.015, -0.010, 0.008, 0.035, -0.006, 0.022];
widthScale = [1.00, 0.92, 1.06, 0.88, 0.95, 1.04];

switch patternName
    case 'peak'
        p.amp = 0.36;
        p.center = 0.33;
        p.width = 0.078;
        p.tailAmp = 0.00;
        p.rippleAmp = 0.040;
        p.noiseAmp = 0.032;
    case 'peak_tail'
        p.amp = 0.39;
        p.center = 0.31;
        p.width = 0.082;
        p.tailAmp = 0.022;
        p.rippleAmp = 0.050;
        p.noiseAmp = 0.041;
    case 'peak_small'
        p.amp = 0.43;
        p.center = 0.30;
        p.width = 0.070;
        p.tailAmp = 0.00;
        p.rippleAmp = 0.039;
        p.noiseAmp = 0.032;
    otherwise
        error('Mushiake_Spikes:UnknownPattern', ...
            'Unknown peak pattern: %s', patternName);
end

p.center = p.center + rowOffsets(iRow) + 0.010 * (iCol - 1) + 0.006 * (iGroup - 2);
p.center = min(max(p.center, 0.21), 0.40);
p.width = p.width * widthScale(iRow);
p.tailPhase = 0.35 * (iRow + iCol + 0.5 * iGroup);
end

function y = add_quiet_trace(x, baseline, rippleAmp, noiseAmp, phase)
quietEnvelope = 0.55 + 0.45 * exp(-((x - 0.32) / 0.30) .^ 2);
ripple = rippleAmp * quietEnvelope .* ( ...
    0.75 * sin(2 * pi * (8.0 * x + phase)) + ...
    0.40 * sin(2 * pi * (19.0 * x + 0.4 * phase)));
microNoise = noiseAmp * ( ...
    0.60 * sin(2 * pi * (13.0 * x + 0.2 * phase)) + ...
    0.30 * sin(2 * pi * (27.0 * x + 0.7 * phase)));
blipCenter1 = 0.16 + 0.035 * sin(phase);
blipCenter2 = 0.33 + 0.025 * cos(1.3 * phase);
smallBlips = ...
    0.024 * exp(-0.5 * ((x - blipCenter1) / 0.024) .^ 2) + ...
    0.020 * exp(-0.5 * ((x - blipCenter2) / 0.020) .^ 2);
y = baseline + ripple + microNoise + smallBlips;
y = max(y, baseline - 0.002);
end

function y = add_peak_trace(x, baseline, amp, center, width, tailAmp, tailPhase, rippleAmp, noiseAmp)
peak = amp * exp(-0.5 * ((x - center) / width) .^ 2);
leftShoulder = 0.022 * exp(-x / 0.11);
peakEnvelope = exp(-0.5 * ((x - center) / (width * 1.45)) .^ 2);
localRipple = rippleAmp * peakEnvelope .* ( ...
    0.70 * sin(2 * pi * (11.0 * x + tailPhase)) + ...
    0.45 * sin(2 * pi * (23.0 * x + 0.4 * tailPhase)));
postNoiseEnvelope = exp(-0.5 * ((x - (center + 0.06)) / (width * 2.1)) .^ 2);
microNoise = noiseAmp * postNoiseEnvelope .* ( ...
    0.60 * sin(2 * pi * (17.0 * x + 0.2 * tailPhase)) + ...
    0.35 * sin(2 * pi * (29.0 * x + 0.5 * tailPhase)));
roughEnvelope = 0.65 * peakEnvelope + 0.35 * postNoiseEnvelope;
roughNoise = 1.45 * noiseAmp * roughEnvelope .* ( ...
    0.55 * sin(2 * pi * (31.0 * x + 0.6 * tailPhase)) + ...
    0.30 * sin(2 * pi * (43.0 * x + 0.15 * tailPhase)));
y = baseline + peak + leftShoulder + localRipple + microNoise + roughNoise;

if tailAmp > 0
    tailMask = x >= 0.48;
    tail = tailAmp * ( ...
        0.60 * sin(2 * pi * (15.0 * x + tailPhase)) + ...
        0.35 * sin(2 * pi * (31.0 * x + 0.3 * tailPhase)));
    y(tailMask) = baseline(tailMask) + 0.010 + 0.020 * tail(tailMask);
end

y = max(y, baseline);
y = min(y, 0.92);
end

function fill_activity_area(ax, x, baseline, y, faceColor)
mask = y > baseline + 0.005;
if ~any(mask)
    return;
end

xPatch = [x(mask), fliplr(x(mask))];
yPatch = [y(mask), fliplr(baseline(mask))];
patch(ax, xPatch, yPatch, faceColor, ...
    'EdgeColor', 'none', ...
    'FaceAlpha', 1.0);
end

function draw_group_titles(ax, panelSpec, style)
for iGroup = 1:3
    xCenter = style.groupX(iGroup) + style.groupWidth / 2;
    text(ax, xCenter, style.titleY, panelSpec(iGroup).title, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', ...
        'FontSize', style.titleFontSize, ...
        'FontWeight', 'bold', ...
        'Interpreter', 'tex');
end
end

function draw_group_separators(ax, style)
for iSep = 1:numel(style.separatorX)
    plot(ax, [style.separatorX(iSep), style.separatorX(iSep)], style.separatorY, ...
        'Color', [0.45, 0.45, 0.45], ...
        'LineWidth', 1.0);
end
end

function draw_go_labels(ax, style)
for iGroup = 1:3
    for iCol = 1:2
        xAnchor = style.groupX(iGroup) + (iCol - 1) * (style.panelWidth + style.colGap) ...
            + style.panelWidth * style.goAnchorX;
        yGo = 0.165;
        plot(ax, xAnchor, yGo + 0.003, ...
            '^', ...
            'MarkerFaceColor', 'k', ...
            'MarkerEdgeColor', 'k', ...
            'MarkerSize', 12);
        text(ax, xAnchor + 0.012, yGo, 'GO', ...
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'FontSize', style.goFontSize, ...
            'FontAngle', 'italic', ...
            'Interpreter', 'none');
    end
end
end

function draw_scale_bar(ax, style)
x0 = style.scaleBase(1);
y0 = style.scaleBase(2);
plot(ax, [x0, x0 + style.scaleBarLength], [y0, y0], ...
    'k', 'LineWidth', 4);
plot(ax, [x0 + style.scaleBarLength, x0 + style.scaleBarLength], ...
    [y0, y0 + style.scaleBarHeight], ...
    'k', 'LineWidth', 4);

text(ax, x0 - 0.012, y0 - 0.018, '1 second', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'middle', ...
    'FontSize', style.scaleFontSize, ...
    'FontAngle', 'italic', ...
    'Interpreter', 'none');
text(ax, x0 + style.scaleBarLength + 0.008, y0 + style.scaleBarHeight - 0.004, '10 spikes/s', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'middle', ...
    'FontSize', style.scaleFontSize, ...
    'FontAngle', 'italic', ...
    'Interpreter', 'none');
end

function assert_hfigprint_dependency()
if exist('hfigPrint', 'file') ~= 2 || exist('hfigPrintParams', 'file') ~= 2
    error('Mushiake_Spikes:MissingDependency', ...
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

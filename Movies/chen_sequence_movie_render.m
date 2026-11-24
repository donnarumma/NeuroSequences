function outputs = chen_sequence_movie_render(p, scenario, files)
%CHEN_SEQUENCE_MOVIE_RENDER Animate saved readouts for Figures 4 and 5.
if isempty(p.outputDir)
    root = fileparts(fileparts(mfilename('fullpath')));
    p.outputDir = fullfile(root, 'Movies', 'output', scenario.stem);
end
paths = struct2cell(files);
for k = 1:numel(paths)
    if ~isfile(paths{k})
        error('chen_sequence_movie_render:MissingSource', ...
            'Missing saved figure: %s\nRun %s or set sourceDir to its Rep01/FIG directory.', ...
            paths{k}, scenario.simulationMain);
    end
end

if ~p.previewOnly
    assert_ffmpeg();
end

outputs = output_files(p.outputDir, scenario.stem);
if isfile(outputs.video) && ~p.previewOnly && ~p.overwrite
    error('chen_sequence_movie_render:ExistingVideo', ...
        'Video already exists. Set overwrite=true or choose another outputDir: %s', outputs.video);
end
if ~isfolder(p.outputDir)
    mkdir(p.outputDir);
end

ink = [0.10, 0.15, 0.21];
fig = figure('Visible', 'off', 'Color', [0.98, 0.985, 0.99], ...
    'Name', sprintf('Figure %d | %s', scenario.figureNumber, scenario.label), 'Position', [20, 20, p.pixelSize], ...
    'Renderer', 'painters', 'PaperUnits', 'inches', ...
    'PaperPosition', [0, 0, p.pixelSize / 100], ...
    'PaperSize', p.pixelSize / 100, 'InvertHardcopy', 'off');
closeFigure = onCleanup(@() close(fig));
set(fig, 'DefaultAxesFontName', 'DejaVu Sans', 'DefaultTextFontName', 'DejaVu Sans');

[rasterAx, ~] = copy_panel(files.raster, fig, 1);
[rateAx, rateLegend] = copy_panel(files.firingRate, fig, 1);
[pcaAx, ~] = copy_panel(files.pca, fig, scenario.nRanks);
rasterFontSize = 11;
if scenario.nRanks == 3, rasterFontSize = 9; end
format_axis(rasterAx, [0.350, 0.505, 0.305, 0.280], rasterFontSize);
format_axis(rateAx, [0.350, 0.170, 0.305, 0.205], 11);
if scenario.nRanks == 2
    pcaPositions = [0.755, 0.510, 0.210, 0.220; 0.755, 0.180, 0.210, 0.220];
    pcaFontSize = 11;
else
    pcaPositions = [0.755, 0.555, 0.210, 0.145; ...
        0.755, 0.335, 0.210, 0.145; 0.755, 0.115, 0.210, 0.145];
    pcaFontSize = 9;
end
for j = 1:scenario.nRanks
    format_axis(pcaAx(j), pcaPositions(j, :), pcaFontSize);
end
rateLegend.Units = 'normalized';
rateLegend.Position = [0.348, 0.386, 0.310, 0.060];
rateLegend.FontSize = 8;
rateLegend.NumColumns = 6;
rateLegend.Box = 'off';
rateLegend.AutoUpdate = 'off';

title(rasterAx, ''); title(rateAx, '');
xlabel(rasterAx, ''); xlabel(rateAx, 'Display time (s)');
ylabel(rasterAx, 'Neural populations'); ylabel(rateAx, 'Response');
for j = 1:scenario.nRanks
    oldTitle = pcaAx(j).Title.String;
    title(pcaAx(j), strrep(oldTitle, sprintf('pca t%d', j), sprintf('%s %d', scenario.pcaTitlePrefix, j)), ...
        'FontSize', pcaFontSize + 2);
    xlabel(pcaAx(j), 'Display time (s)');
    ylabel(pcaAx(j), 'PC 1'); zlabel(pcaAx(j), 'PC 2');
    if scenario.nRanks == 2
        pcaAx(j).XTick = 0:6;
    else
        pcaAx(j).XTick = 0:5;
        xlabel(pcaAx(j), '');
    end
end
xlabel(pcaAx(1), '');

rasterRecords = consolidate_spikes(rasterAx);
imageRecords = raster_images(rasterAx);
rateRecords = temporal_lines(rateAx);
pcaRecords = empty_records();
for j = 1:scenario.nRanks
    pcaRecords = [pcaRecords, temporal_lines(pcaAx(j))]; %#ok<AGROW>
end
records = [rasterRecords, rateRecords, pcaRecords];
assert(~isempty(rasterRecords) && ~isempty(rateRecords) && numel(pcaRecords) >= 12, ...
    'chen_sequence_movie_render:MissingTraces', 'Saved figures do not contain the expected traces.');
timedShapes = pca_end_shapes(pcaAx);
timeEnd = max_visible_pca_time(pcaRecords, pcaAx(1).XLim);
if scenario.nRanks == 3
    timeEnd = max([timeEnd, rasterAx.XLim(2), rateAx.XLim(2)]);
end
timeRange = [0, timeEnd];
frameTimes = linspace(timeRange(1), timeEnd, ...
    max(2, ceil(timeEnd / p.playbackSpeed * p.frameRate) + 1));

annotation(fig, 'rectangle', [0, 0.905, 1, 0.095], ...
    'FaceColor', ink, 'EdgeColor', 'none');
textbox(fig, [0.028, 0.945, 0.76, 0.035], ...
    'INFERENTIAL PLANNING IN THE FRONTAL CORTEX', 23, 'w', 'bold');
textbox(fig, [0.030, 0.913, 0.76, 0.032], ...
    sprintf('Figure %d  |  %s  |  %s  |  Chen et al. (2024)', ...
        scenario.figureNumber, scenario.taskLabel, scenario.label), ...
    13, [0.78, 0.83, 0.88], 'normal');
clockText = textbox(fig, [0.80, 0.932, 0.18, 0.040], '', 23, 'w', 'bold');
clockText.HorizontalAlignment = 'right';

[~, timelineHead, timelineDots] = task_timeline(fig, timeEnd, scenario);
[targets, fixation, cue, phaseText, planText] = task_display(fig, scenario);
textbox(fig, [0.030, 0.795, 0.26, 0.036], 'A / B  |  Task and target layout', 16, ink, 'bold');
textbox(fig, [0.350, 0.795, 0.31, 0.036], ...
    [scenario.panels{1} '  |  Simulated spikes'], 16, ink, 'bold');
textbox(fig, [0.350, 0.450, 0.31, 0.030], ...
    [scenario.panels{2} '  |  Simulated firing rates'], 16, ink, 'bold');
textbox(fig, [0.755, 0.795, 0.23, 0.036], ...
    [scenario.panels{3} '  |  Population geometry'], 16, ink, 'bold');
textbox(fig, [0.755, 0.765, 0.23, 0.026], scenario.pcaSubtitle, 11, [0.4, 0.45, 0.5], 'normal');
keyY = 0.470;
if scenario.nRanks == 3, keyY = 0.738; end
draw_pca_key(fig, pcaAx(1), keyY);
annotation(fig, 'line', [0.305, 0.305], [0.130, 0.805], 'Color', [0.83, 0.86, 0.89]);
annotation(fig, 'line', [0.705, 0.705], [0.130, 0.805], 'Color', [0.83, 0.86, 0.89]);

allAxes = [rasterAx, rateAx, pcaAx(:)'];
heads = gobjects(size(allAxes));
for j = 1:numel(allAxes)
    heads(j) = xline(allAxes(j), 0, '-', 'Color', ink, 'LineWidth', 1.25, ...
        'HandleVisibility', 'off');
end
textbox(fig, [0.03, 0.058, 0.94, 0.030], ...
    sprintf('Saved model readouts  |  Original panel axes and values  |  Playback %.2gx  |  Fixed scales throughout', ...
    p.playbackSpeed), 11, [0.4, 0.45, 0.5], 'normal');
textbox(fig, [0.03, 0.028, 0.94, 0.028], ...
    scenario.footer, ...
    11, [0.4, 0.45, 0.5], 'normal');

previewTimes = [0, 1.5, 2.5, 4.5, timeEnd];
if scenario.nRanks == 3
    previewTimes = [0, 1.5, 2.5, 3.5, 4.5, timeEnd];
end
outputs.previews = cell(size(previewTimes));
for k = 1:numel(previewTimes)
    draw_frame(previewTimes(k));
    verify_frame(records, imageRecords, previewTimes(k));
    outputs.previews{k} = fullfile(p.outputDir, sprintf('preview_%02d.png', k));
    print(fig, outputs.previews{k}, '-dpng', '-r100');
end
draw_frame(timeEnd);
verify_frame(records, imageRecords, timeEnd);
print(fig, outputs.poster, '-dpng', '-r100');
exportgraphics(fig, outputs.posterPDF, 'ContentType', 'vector', 'BackgroundColor', fig.Color);
savefig(fig, outputs.figure);

provenance = struct('sourceFiles', files, 'options', p, 'scenario', scenario, 'frameTimes', frameTimes, ...
    'previewTimes', previewTimes, 'timeRange', timeRange, ...
    'createdUTC', char(datetime('now', 'TimeZone', 'UTC')), ...
    'paperURL', 'https://www.sciencedirect.com/science/article/pii/S2211124726009836', ...
    'pcaScope', sprintf('Condition-level trajectories for targets A-F; not single-trial %s projections', scenario.sequence), ...
    'clock', 'Original plotted X coordinates; existing panel offsets are retained');
provenance.signals = rmfield(records, 'handle');
provenance.rasterImages = rmfield(imageRecords, 'handle');
provenance.sourceSHA256 = cellfun(@file_sha256, struct2cell(files), 'UniformOutput', false);
provenance.codeSHA256 = file_sha256([mfilename('fullpath') '.m']);
provenance.entryPoint = scenario.entryPoint;
provenance.entryPointSHA256 = file_sha256(which(scenario.entryPoint));
provenance.optionsCodeSHA256 = file_sha256(which('chen_sequence_movie_options'));
save(outputs.provenance, 'provenance', '-v7');
if p.previewOnly
    fprintf('Saved Figure %d previews: %s\n', scenario.figureNumber, p.outputDir);
    return;
end

framesDir = tempname;
mkdir(framesDir);
frameCleanup = onCleanup(@() remove_frames(framesDir, p.keepFrames));
fprintf('Rendering %d frames at %g fps: %s\n', numel(frameTimes), p.frameRate, outputs.video);
for k = 1:numel(frameTimes)
    draw_frame(frameTimes(k));
    print(fig, fullfile(framesDir, sprintf('frame_%06d.png', k)), '-dpng', '-r100');
    if mod(k, 20) == 0 || k == numel(frameTimes)
        fprintf('  frame %d/%d\n', k, numel(frameTimes));
    end
end
encode_movie(framesDir, outputs.video, p);
outputs.framesDir = '';
if p.keepFrames
    outputs.framesDir = framesDir;
end
fprintf('Saved %s\n', outputs.video);

    function draw_frame(t)
        for i = 1:numel(records)
            r = records(i);
            keep = r.x <= t + 1e-10;
            y = r.y; y(~keep) = NaN;
            set(r.handle, 'XData', r.x, 'YData', y);
            if ~isempty(r.z)
                z = r.z; z(~keep) = NaN;
                r.handle.ZData = z;
            end
        end
        for i = 1:numel(timedShapes)
            if t + 1e-10 >= timedShapes(i).time
                timedShapes(i).handle.Visible = 'on';
            else
                timedShapes(i).handle.Visible = 'off';
            end
        end
        for i = 1:numel(imageRecords)
            r = imageRecords(i);
            alpha = r.alpha;
            alpha(:, r.time > t + 1e-10) = 0;
            r.handle.AlphaData = alpha;
        end
        for i = 1:numel(heads)
            heads(i).Value = t;
        end
        timelineHead.Value = t;
        nPhases = size(timelineDots.CData, 1);
        phase = min(nPhases, floor(t) + 1);
        timelineDots.CData = repmat([0.82, 0.85, 0.88], nPhases, 1);
        timelineDots.CData(phase, :) = ink;
        update_task(targets, fixation, cue, phaseText, planText, phase, scenario);
        clockText.String = sprintf('t = %.2f s', t);
        drawnow;
    end
end

function outputs = output_files(directory, caseStem)
stem = fullfile(directory, caseStem);
outputs.video = [stem '.mp4'];
outputs.poster = [stem '_poster.png'];
outputs.posterPDF = [stem '_poster.pdf'];
outputs.figure = [stem '_poster.fig'];
outputs.provenance = [stem '_sources.mat'];
end

function [axesOut, legendOut] = copy_panel(path, destination, expectedAxes)
source = openfig(path, 'new', 'invisible');
cleanup = onCleanup(@() close(source));
sourceAxes = findall(source, 'Type', 'axes', 'Visible', 'on');
assert(numel(sourceAxes) == expectedAxes, 'chen_sequence_movie_render:AxesMismatch', ...
    'Expected %d data axes in %s; found %d.', expectedAxes, path, numel(sourceAxes));
positions = vertcat(sourceAxes.Position);
[~, order] = sort(positions(:, 2), 'descend');
sourceAxes = sourceAxes(order);
axesOut = gobjects(1, expectedAxes);
legendOut = gobjects(0);
for k = 1:expectedAxes
    axesOut(k) = copyobj(sourceAxes(k), destination);
    axesOut(k).Units = 'normalized';
    axesOut(k).PositionConstraint = 'innerposition';
    colormap(axesOut(k), colormap(sourceAxes(k)));
end
% Copy the rate legend together with its axes to retain its original entries.
if expectedAxes == 1 && contains(path, 'FiringRate')
    oldLegend = findall(source, 'Type', 'legend');
    assert(numel(oldLegend) == 1, 'chen_sequence_movie_render:MissingLegend', 'Expected one firing-rate legend.');
    delete(axesOut);
    objects = copyobj([sourceAxes; oldLegend], destination);
    axesOut = objects(1); legendOut = objects(2);
    axesOut.Units = 'normalized';
    axesOut.PositionConstraint = 'innerposition';
    colormap(axesOut, colormap(sourceAxes));
end
end

function format_axis(ax, position, fontSize)
set(ax, 'Units', 'normalized', 'Position', position, 'FontSize', fontSize, ...
    'FontName', 'DejaVu Sans', 'Color', 'w', 'XLimMode', 'manual', ...
    'YLimMode', 'manual', 'ZLimMode', 'manual');
texts = findall(ax, 'Type', 'text');
set(texts, 'FontSize', fontSize, 'FontName', 'DejaVu Sans');
end

function records = consolidate_spikes(ax)
% Combine tick segments by colour to reduce per-frame raster updates.
objects = findall(ax, 'Type', 'line');
records = empty_records();
colours = zeros(0, 3);
for k = 1:numel(objects)
    h = objects(k); x = h.XData; y = h.YData;
    if numel(x) ~= 2 || any(~isfinite([x, y])) || abs(diff(x)) > 1e-9 ...
            || abs(diff(y)) > 1 || abs(diff(y)) < eps
        continue;
    end
    group = find(all(abs(colours - h.Color) < 1e-10, 2), 1);
    if isempty(group)
        colours(end + 1, :) = h.Color; %#ok<AGROW>
        group = size(colours, 1);
        records(group) = trace_record(h, 'raster');
        records(group).x = []; records(group).y = [];
    end
    records(group).x = [records(group).x, x, NaN];
    records(group).y = [records(group).y, y, NaN];
    delete(h);
end
for k = 1:numel(records)
    records(k).handle = line(ax, records(k).x, records(k).y, ...
        'Color', colours(k, :), 'LineWidth', 0.8, 'HandleVisibility', 'off');
end
end

function records = raster_images(ax)
objects = findall(ax, 'Type', 'image');
records = struct('handle', {}, 'time', {}, 'cdata', {}, 'alpha', {});
for k = 1:numel(objects)
    h = objects(k);
    times = linspace(h.XData(1), h.XData(end), size(h.CData, 2));
    alpha = h.AlphaData;
    if isscalar(alpha)
        alpha = repmat(alpha, size(h.CData, 1), size(h.CData, 2));
    end
    records(end + 1) = struct('handle', h, 'time', times, ...
        'cdata', h.CData, 'alpha', alpha); %#ok<AGROW>
end
end

function records = temporal_lines(ax)
objects = findall(ax, 'Type', 'line');
records = empty_records();
for k = 1:numel(objects)
    h = objects(k);
    if isempty(h.XData) || ~any(isfinite(h.YData))
        continue;
    end
    % Static 2-D epoch dividers have constant X and span the axes height.
    is3D = ~isempty(h.ZData);
    if ~is3D && numel(h.XData) == 2 && abs(diff(h.XData)) < eps ...
            && abs(diff(h.YData)) > 0.8 * diff(ax.YLim)
        continue;
    end
    records(end + 1) = trace_record(h, 'trace'); %#ok<AGROW>
end
end

function record = trace_record(h, kind)
record = struct('handle', h, 'x', h.XData, 'y', h.YData, 'z', h.ZData, ...
    'kind', kind, 'color', h.Color);
end

function records = empty_records()
records = struct('handle', {}, 'x', {}, 'y', {}, 'z', {}, 'kind', {}, 'color', {});
end

function shapes = pca_end_shapes(axesList)
shapes = struct('handle', {}, 'time', {});
for ax = axesList
    objects = findall(ax, 'Type', 'patch');
    for k = 1:numel(objects)
        h = objects(k);
        % Grey epoch planes are the reference grid, not a data hull.
        if strcmp(h.EdgeColor, 'none')
            continue;
        end
        shapes(end + 1) = struct('handle', h, 'time', max(h.XData(:))); %#ok<AGROW>
    end
end
end

function lastTime = max_visible_pca_time(records, limits)
times = [records.x];
times = times(isfinite(times) & times >= limits(1) & times <= limits(2));
assert(~isempty(times), 'chen_sequence_movie_render:EmptyPCA', 'No visible PCA coordinates.');
lastTime = max(times);
end

function verify_frame(records, images, timeEnd)
for k = 1:numel(records)
    r = records(k);
    expectedY = r.y; expectedY(r.x > timeEnd + 1e-10 | isnan(r.x)) = NaN;
    assert(isequaln(r.handle.XData, r.x) && isequaln(r.handle.YData, expectedY), ...
        'chen_sequence_movie_render:ChangedValues', 'Animation changed saved trace coordinates.');
    if ~isempty(r.z)
        expectedZ = r.z; expectedZ(r.x > timeEnd + 1e-10 | isnan(r.x)) = NaN;
        assert(isequaln(r.handle.ZData, expectedZ), ...
            'chen_sequence_movie_render:ChangedValues', 'Animation changed saved PCA coordinates.');
    end
end
for k = 1:numel(images)
    r = images(k);
    alpha = r.alpha; alpha(:, r.time > timeEnd + 1e-10) = 0;
    assert(isequaln(r.handle.CData, r.cdata) && isequaln(r.handle.AlphaData, alpha), ...
        'chen_sequence_movie_render:RasterImageMismatch', 'Raster image values or reveal mask changed.');
end
end

function h = textbox(fig, position, textValue, fontSize, colour, weight)
h = annotation(fig, 'textbox', position, 'String', textValue, 'FontSize', fontSize, ...
    'Color', colour, 'FontWeight', weight, 'EdgeColor', 'none', 'Interpreter', 'none', ...
    'Margin', 0, 'VerticalAlignment', 'middle');
end

function [ax, head, dots] = task_timeline(fig, timeEnd, scenario)
ax = axes(fig, 'Units', 'normalized', 'Position', [0.04, 0.850, 0.925, 0.040], ...
    'Visible', 'off', 'XLim', [0, timeEnd], 'YLim', [0, 1]);
hold(ax, 'on');
plot(ax, [0, timeEnd], [0.5, 0.5], '-', 'Color', [0.82, 0.85, 0.88], 'LineWidth', 2);
if scenario.nRanks == 2
    centres = 0.5:1:5.5;
    labels = {'Pre', sprintf('S1: target %c', scenario.sequence(1)), ...
        sprintf('S2: target %c', scenario.sequence(2)), 'Delay 1', ...
        ['Cue: ' scenario.direction], 'Delay 2'};
else
    centres = [0.5, 1.5, 2.5, 3.5, (4 + timeEnd) / 2];
    labels = {'Pre', 'S1: target A', 'S2: target B', 'S3: target C', 'Delay'};
end
nPhases = numel(labels);
dots = scatter(ax, centres, 0.5 * ones(1, nPhases), 50, ...
    repmat([0.82, 0.85, 0.88], nPhases, 1), 'filled');
for k = 1:nPhases
    text(ax, centres(k), -0.08, labels{k}, 'FontSize', 12, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
end
head = xline(ax, 0, '-', 'Color', [0.10, 0.15, 0.21], 'LineWidth', 2);
end

function [targets, fixation, cue, phaseText, planText] = task_display(fig, scenario)
ax = axes(fig, 'Position', [0.025, 0.415, 0.26, 0.345], ...
    'XLim', [-1.55, 1.55], 'YLim', [-1.4, 1.4], 'Visible', 'off');
hold(ax, 'on'); axis(ax, 'equal');
targets = gobjects(1, 6);
theta = pi / 2 - (0:5) * pi / 3;
for k = 1:6
    xy = [cos(theta(k)), sin(theta(k))];
    targets(k) = rectangle(ax, 'Position', [xy - 0.12, 0.24, 0.24], ...
        'Curvature', [1, 1], 'FaceColor', [0.86, 0.87, 0.88], ...
        'EdgeColor', [0.4, 0.45, 0.5], 'LineWidth', 1.2);
    text(ax, 1.30 * xy(1), 1.30 * xy(2), char('A' + k - 1), ...
        'FontSize', 18, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
end
fixation = plot(ax, 0, 0, 'o', 'MarkerSize', 15, ...
    'MarkerFaceColor', [0.1, 0.7, 0.3], 'MarkerEdgeColor', 'w', 'LineWidth', 1.5);
cue = text(ax, 0, 0, upper(scenario.direction), 'FontSize', 17, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'Visible', 'off', 'BackgroundColor', 'w', 'Margin', 10);
phaseText = textbox(fig, [0.030, 0.350, 0.255, 0.045], '', 19, [0.10, 0.15, 0.21], 'bold');
phaseText.HorizontalAlignment = 'center';
planText = textbox(fig, [0.030, 0.250, 0.255, 0.085], '', 15, [0.4, 0.45, 0.5], 'normal');
planText.HorizontalAlignment = 'center';
textbox(fig, [0.040, 0.160, 0.240, 0.058], ...
    {'Six possible targets A-F'; 'A: up     B: upper-right'}, 13, [0.4, 0.45, 0.5], 'normal');
if scenario.nRanks == 3
    if strcmp(scenario.readoutRole, 'sensory')
        rule = 'Level 1 sensory readout | both rules';
    else
        rule = ['Rule known before S1: ' upper(scenario.direction)];
    end
    textbox(fig, [0.030, 0.210, 0.255, 0.035], rule, 12, [0.4, 0.45, 0.5], 'bold');
end
end

function update_task(targets, fixation, cue, phaseText, planText, phase, scenario)
if scenario.nRanks == 3
    update_three_target_task(targets, fixation, cue, phaseText, planText, phase, scenario);
    return;
end
set(targets, 'FaceColor', [0.86, 0.87, 0.88], 'LineWidth', 1.2);
fixation.Visible = 'on'; cue.Visible = 'off';
if phase <= 3
    fixation.MarkerFaceColor = [0.1, 0.7, 0.3];
else
    fixation.MarkerFaceColor = [0.6, 0.63, 0.66];
end
switch phase
    case 1
        phaseText.String = 'PRE';
        planText.String = {'Fixation'; 'Waiting for the sequence'};
    case 2
        target = scenario.sequence(1) - 'A' + 1;
        targets(target).FaceColor = [1, 0.05, 0.05]; targets(target).LineWidth = 2;
        phaseText.String = sprintf('S1  |  TARGET %c', scenario.sequence(1));
        planText.String = {'First stimulus'; sprintf('%c is presented', scenario.sequence(1))};
    case 3
        target = scenario.sequence(2) - 'A' + 1;
        targets(target).FaceColor = [1, 0.05, 0.05]; targets(target).LineWidth = 2;
        phaseText.String = sprintf('S2  |  TARGET %c', scenario.sequence(2));
        planText.String = {'Second stimulus'; sprintf('%c is presented', scenario.sequence(2))};
    case 4
        phaseText.String = 'DELAY 1';
        planText.String = {sprintf('Remember %c and %c', scenario.sequence); 'Await the direction cue'};
    case 5
        fixation.Visible = 'off'; cue.Visible = 'on';
        phaseText.String = ['CUE  |  ' upper(scenario.direction)];
        planText.String = {['Infer the ' scenario.direction ' plan']; scenario.planLabel};
    case 6
        phaseText.String = 'DELAY 2';
        planText.String = {'Hold the inferred plan'; scenario.planLabel};
end
end

function update_three_target_task(targets, fixation, cue, phaseText, planText, phase, scenario)
set(targets, 'FaceColor', [0.86, 0.87, 0.88], 'LineWidth', 1.2);
fixation.Visible = 'on'; cue.Visible = 'off';
fixation.MarkerFaceColor = [0.1, 0.7, 0.3];
sensory = strcmp(scenario.readoutRole, 'sensory');
if phase == 1
    phaseText.String = 'PRE';
    if sensory
        planText.String = {'Sensory readout (Level 1)'; 'Same inputs in both task directions'};
    else
        planText.String = {'Rule known before S1'; 'Sequence length is initially unknown'};
    end
elseif phase <= 4
    target = phase - 1;
    letter = scenario.sequence(target);
    targets(target).FaceColor = [1, 0.05, 0.05]; targets(target).LineWidth = 2;
    phaseText.String = sprintf('S%d  |  TARGET %c', target, letter);
    if sensory
        planText.String = {sprintf('Current input: %c', letter); 'Transient target encoding'};
    elseif target == 3
        planText.String = {'Third stimulus'; 'Three-target sequence is complete'};
    elseif strcmp(scenario.direction, 'backward')
        planText.String = {sprintf('Observe target %c', letter); 'Rank depends on final sequence length'};
    else
        planText.String = {sprintf('Observe target %c', letter); 'Build the forward plan'};
    end
else
    fixation.MarkerFaceColor = [0.6, 0.63, 0.66];
    phaseText.String = 'DELAY';
    if sensory
        planText.String = {'Input removed'; 'Sensory responses return to baseline'};
    else
        planText.String = {'Hold the inferred plan'; scenario.planLabel};
    end
end
end

function draw_pca_key(fig, ax, y)
objects = findall(ax, 'Type', 'line');
traces = objects(arrayfun(@(h) numel(h.XData) > 2 && max(h.XData) > min(h.XData), objects));
traces = flipud(traces);
for k = 1:min(6, numel(traces))
    x = 0.76 + (k - 1) * 0.034;
    annotation(fig, 'line', [x, x + 0.012], [y, y], ...
        'Color', traces(k).Color, 'LineWidth', 2);
    textbox(fig, [x + 0.014, y - 0.012, 0.018, 0.026], char('A' + k - 1), ...
        10, [0.10, 0.15, 0.21], 'normal');
end
end

function assert_ffmpeg()
[status, ~] = system('ffmpeg -version');
assert(status == 0, 'chen_sequence_movie_render:MissingFFmpeg', ...
    'ffmpeg is required for MP4 encoding. previewOnly=true exports still figures.');
end

function encode_movie(framesDir, output, p)
temporary = [tempname(fileparts(output)) '.mp4'];
cleanup = onCleanup(@() delete_if_present(temporary));
filter = sprintf(['pad=ceil(iw/2)*2:ceil(ih/2)*2,' ...
    'tpad=start_mode=clone:start_duration=%g:stop_mode=clone:stop_duration=%g'], ...
    p.holdStartSeconds, p.holdEndSeconds);
prefix = '';
if isunix
    prefix = 'env -u LD_LIBRARY_PATH -u LD_PRELOAD ';
end
command = sprintf(['%sffmpeg -hide_banner -loglevel error -y -framerate %g -i %s ' ...
    '-vf %s -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -movflags +faststart %s'], ...
    prefix, p.frameRate, shell_quote(fullfile(framesDir, 'frame_%06d.png')), ...
    shell_quote(filter), shell_quote(temporary));
[status, message] = system(command);
assert(status == 0, 'chen_sequence_movie_render:EncodingFailed', 'ffmpeg failed: %s', message);
movefile(temporary, output, 'f');
end

function value = shell_quote(value)
if ispc
    value = ['"' strrep(char(value), '"', '""') '"'];
else
    value = ['''' strrep(char(value), '''', '''"''"''') ''''];
end
end

function hash = file_sha256(path)
fid = fopen(path, 'rb');
assert(fid >= 0, 'chen_sequence_movie_render:UnreadableSource', 'Cannot read %s.', path);
cleanup = onCleanup(@() fclose(fid));
md = java.security.MessageDigest.getInstance('SHA-256');
while ~feof(fid)
    md.update(fread(fid, 1024 * 1024, '*uint8'));
end
bytes = typecast(md.digest(), 'uint8');
hash = lower(reshape(dec2hex(bytes, 2)', 1, []));
end

function remove_frames(path, keep)
if ~keep && isfolder(path)
    rmdir(path, 's');
end
end

function delete_if_present(path)
if isfile(path)
    delete(path);
end
end

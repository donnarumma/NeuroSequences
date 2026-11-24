function outputs = Mushiake_Fig02_Movie(options)
%MUSHIAKE_FIG02_MOVIE Animate Figure 2 planning and a separate maze replay.
%   outputs = Mushiake_Fig02_Movie;  % ULL, panels D/E/F, trial 2
%   outputs = Mushiake_Fig02_Movie(struct('caseName', 'URR'));
%   outputs = Mushiake_Fig02_Movie(struct('previewOnly', true));
% Reads existing .fig exports and the matching cached MDP. Does not rerun
% inference, spike sampling or readout processing. The path replay is a
% schematic second phase; its pace is not the model's neural time.
if nargin < 1, options = struct(); end
validateattributes(options, {'struct'}, {'scalar'});
replayStepSeconds = 1.5;
replayStateHoldSeconds = 1.2;
planHoldSeconds = 1.5;
if isfield(options, 'replayStepSeconds')
    replayStepSeconds = options.replayStepSeconds;
    options = rmfield(options, 'replayStepSeconds');
end
if isfield(options, 'replayStateHoldSeconds')
    replayStateHoldSeconds = options.replayStateHoldSeconds;
    options = rmfield(options, 'replayStateHoldSeconds');
end
if isfield(options, 'planHoldSeconds')
    planHoldSeconds = options.planHoldSeconds;
    options = rmfield(options, 'planHoldSeconds');
end
validateattributes(replayStepSeconds, {'numeric'}, {'scalar', 'finite', 'positive'});
validateattributes(replayStateHoldSeconds, {'numeric'}, {'scalar', 'finite', 'nonnegative'});
validateattributes(planHoldSeconds, {'numeric'}, {'scalar', 'finite', 'nonnegative'});
if ~isfield(options, 'playbackSpeed'), options.playbackSpeed = 0.10; end
p = chen_sequence_movie_options(options, 'ULL', ...
    '/TESTS/HAI_SEQUENCES/Mushiake/Mushiake_SEQUENCES_UDLRS/Rep01');
p.replayStepSeconds = replayStepSeconds;
p.replayStateHoldSeconds = replayStateHoldSeconds;
p.planHoldSeconds = planHoldSeconds;
p.caseName = validatestring(p.caseName, {'ULL', 'URR'}, mfilename, 'caseName');
scenario = struct('sequence', p.caseName, 'trial', 2, 'panels', {{'D', 'E', 'F'}});
if strcmp(p.caseName, 'URR')
    scenario.trial = 1;
    scenario.panels = {'G', 'H', 'I'};
end
stem = ['Mushiake_Fig02_' p.caseName];
if isempty(p.outputDir)
    p.outputDir = fullfile(fileparts(mfilename('fullpath')), 'output', stem);
end
figureDir = p.sourceDir;
if isfolder(fullfile(figureDir, 'FIG')), figureDir = fullfile(figureDir, 'FIG'); end
trialDir = fileparts(figureDir);
files.maze = fullfile(figureDir, sprintf('Maze_Mushiake_UDLR_Trial%d.fig', scenario.trial));
files.raster = fullfile(figureDir, sprintf('Raster_Mushiake_UDLR_Trial%d.fig', scenario.trial));
files.firingRate = fullfile(figureDir, sprintf('FiringRate_Mushiake_UDLR_Trial%d.fig', scenario.trial));
matches = dir(fullfile(trialDir, sprintf('MDP_*Trial%d_*.mat', scenario.trial)));
assert(~isempty(matches), 'Mushiake_Fig02_Movie:MissingMDP', ...
    'No cached trial-%d MDP in %s. Set sourceDir to Rep01 or Rep01/FIG.', scenario.trial, trialDir);
[~, latest] = max([matches.datenum]);
files.mdp = fullfile(matches(latest).folder, matches(latest).name);
paths = struct2cell(files);
for k = 1:numel(paths)
    assert(isfile(paths{k}), 'Mushiake_Fig02_Movie:MissingSource', 'Missing source: %s', paths{k});
end
sourceHashes = cellfun(@sha256, paths, 'UniformOutput', false);
if ~p.previewOnly
    [status, ~] = system('ffmpeg -version');
    assert(status == 0, 'Mushiake_Fig02_Movie:MissingFFmpeg', 'ffmpeg is required for MP4 encoding.');
end
outputStem = fullfile(p.outputDir, stem);
outputs = struct('video', [outputStem '.mp4'], 'poster', [outputStem '_poster.png'], ...
    'posterPDF', [outputStem '_poster.pdf'], 'figure', [outputStem '_poster.fig'], ...
    'provenance', [outputStem '_sources.mat']);
assert(p.previewOnly || p.overwrite || ~isfile(outputs.video), ...
    'Mushiake_Fig02_Movie:ExistingVideo', 'Set overwrite=true to replace %s.', outputs.video);
if ~isfolder(p.outputDir), mkdir(p.outputDir); end

ink = [0.10, 0.15, 0.21];
fig = figure('Visible', 'off', 'Color', [0.98, 0.985, 0.99], ...
    'Name', ['Figure 2 | ' p.caseName], 'Position', [20, 20, p.pixelSize], ...
    'Renderer', 'painters', 'PaperUnits', 'inches', ...
    'PaperPosition', [0, 0, p.pixelSize / 100], 'PaperSize', p.pixelSize / 100, ...
    'InvertHardcopy', 'off');
cleanupFigure = onCleanup(@() close(fig));
set(fig, 'DefaultAxesFontName', 'DejaVu Sans', 'DefaultTextFontName', 'DejaVu Sans');
[mazeAx, ~] = copy_panel(files.maze, fig);
[rasterAx, ~] = copy_panel(files.raster, fig);
[rateAx, rateLegend] = copy_panel(files.firingRate, fig);
format_axis(mazeAx, [0.035, 0.310, 0.385, 0.480], 15);
format_axis(rasterAx, [0.510, 0.485, 0.450, 0.315], 11);
format_axis(rateAx, [0.510, 0.125, 0.450, 0.205], 11);
title(mazeAx, ''); title(rasterAx, ''); title(rateAx, '');
xlabel(mazeAx, ''); ylabel(mazeAx, '');
xlabel(rasterAx, ''); ylabel(rasterAx, 'Action populations');
xlabel(rateAx, 'Planning time (source axis)'); ylabel(rateAx, 'Response');
rateLegend.Units = 'normalized';
rateLegend.Position = [0.505, 0.350, 0.460, 0.075];
rateLegend.FontSize = 8;
rateLegend.NumColumns = 8;
rateLegend.Box = 'off'; rateLegend.AutoUpdate = 'off';
oldArrows = findall(mazeAx, 'Type', 'quiver');
set(oldArrows, 'Visible', 'off');
mazeLines = findall(mazeAx, 'Type', 'line');
for k = 1:numel(mazeLines)
    h = mazeLines(k);
    if isscalar(h.XData)
        h.MarkerSize = 32;
    else
        h.LineWidth = 3;
    end
end
mazeAx.LineWidth = 3;
[pathXY, stateLabels, actions, stateIndices] = read_path(files.mdp, mazeAx, p.caseName);
blocks = findall(rasterAx, 'Type', 'patch');
[~, order] = sort(arrayfun(@(h) min(h.YData(:)), blocks));
blocks = blocks(order);
assert(numel(blocks) == 3, 'Mushiake_Fig02_Movie:RasterBlocks', 'Expected three raster rank blocks.');
rankColours = vertcat(blocks.FaceColor);
pathView = mushiake_movie_path(mazeAx, pathXY, rankColours);

[records, images] = capture_signals(rasterAx, rateAx);
assert(any(strcmp({records.kind}, 'spike')) && any(strcmp({records.kind}, 'rate')), ...
    'Mushiake_Fig02_Movie:MissingSignals', 'Saved neural traces were not found.');
timeRange = rasterAx.XLim;
assert(abs(timeRange(1)) < eps && abs(timeRange(2) - 1) < eps, ...
    'Mushiake_Fig02_Movie:TimeRange', 'Expected the saved 0-1 planning interval.');
planningSeconds = diff(timeRange) / p.playbackSpeed;
replayStart = planningSeconds + p.planHoldSeconds;
duration = replayStart + 3 * (p.replayStepSeconds + p.replayStateHoldSeconds);
% Preserve the requested frame rate: durations are rounded up to a frame.
frameTimes = (0:ceil(duration * p.frameRate)) / p.frameRate;
neuralTimes = min(timeRange(2), timeRange(1) + frameTimes * p.playbackSpeed);
[replaySteps, replayActions, replayHolding] = replay_timing(frameTimes, replayStart, p);

annotation(fig, 'rectangle', [0, 0.905, 1, 0.095], 'FaceColor', ink, 'EdgeColor', 'none');
boxtext(fig, [0.028, 0.945, 0.76, 0.035], ...
    'INFERENTIAL PLANNING IN THE FRONTAL CORTEX', 23, 'w', 'bold');
boxtext(fig, [0.030, 0.913, 0.76, 0.032], ...
    sprintf('Figure 2  |  Cursor-movement planning  |  %s  |  Mushiake et al. (2006)', p.caseName), ...
    13, [0.78, 0.83, 0.88], 'normal');
clockText = boxtext(fig, [0.80, 0.932, 0.18, 0.040], '', 21, 'w', 'bold');
clockText.HorizontalAlignment = 'right';
phaseText = boxtext(fig, [0.030, 0.850, 0.93, 0.035], '', 16, ink, 'bold');
annotation(fig, 'line', [0.030, 0.970], [0.835, 0.835], 'Color', [0.83, 0.86, 0.89]);
annotation(fig, 'line', [0.450, 0.450], [0.115, 0.805], 'Color', [0.83, 0.86, 0.89]);
boxtext(fig, [0.030, 0.795, 0.40, 0.035], ...
    [scenario.panels{1} '  |  Maze and planned path'], 16, ink, 'bold');
boxtext(fig, [0.510, 0.800, 0.45, 0.035], ...
    [scenario.panels{2} '  |  Simulated spikes'], 16, ink, 'bold');
boxtext(fig, [0.510, 0.425, 0.45, 0.035], ...
    [scenario.panels{3} '  |  Simulated firing rates'], 16, ink, 'bold');
statusText = boxtext(fig, [0.045, 0.240, 0.38, 0.035], '', 17, ink, 'bold');
statusText.Interpreter = 'tex';
boxtext(fig, [0.045, 0.205, 0.38, 0.030], ...
    'Green square: start    Red circle: goal', 12, [0.4, 0.45, 0.5], 'normal');
cards = gobjects(1, 3);
for k = 1:3
    x = 0.045 + (k - 1) * 0.125;
    cards(k) = boxtext(fig, [x, 0.142, 0.115, 0.050], '', 19, rankColours(k, :), 'bold');
    cards(k).HorizontalAlignment = 'center';
end
boxtext(fig, [0.045, 0.103, 0.38, 0.030], ...
    'Colour denotes position in the action sequence', 11, [0.4, 0.45, 0.5], 'normal');
boxtext(fig, [0.030, 0.052, 0.94, 0.030], ...
    'Planning: original saved neural coordinates, colours and smoothing. No inference or spike sampling is repeated.', ...
    11, [0.4, 0.45, 0.5], 'normal');
boxtext(fig, [0.030, 0.023, 0.94, 0.028], ...
    'Path replay: schematic movement through the cached MDP states; neural time is frozen. Replay pace is illustrative.', ...
    11, [0.4, 0.45, 0.5], 'normal');
heads = [xline(rasterAx, 0, '-', 'Color', ink, 'LineWidth', 1.25, 'HandleVisibility', 'off'), ...
    xline(rateAx, 0, '-', 'Color', ink, 'LineWidth', 1.25, 'HandleVisibility', 'off')];
arrivalTimes = replayStart + (0:2) * (p.replayStepSeconds + p.replayStateHoldSeconds) ...
    + p.replayStepSeconds;
previewTimes = [0, 0.3 * planningSeconds, 0.65 * planningSeconds, ...
    planningSeconds, arrivalTimes + p.replayStateHoldSeconds / 2];
outputs.previews = cell(size(previewTimes));
previewStatusText = cell(size(previewTimes));
for k = 1:numel(previewTimes)
    draw_frame(previewTimes(k));
    previewStatusText{k} = statusText.String;
    verify_frame(records, images, min(1, previewTimes(k) * p.playbackSpeed));
    outputs.previews{k} = fullfile(p.outputDir, sprintf('preview_%02d.png', k));
    print(fig, outputs.previews{k}, '-dpng', '-r100');
end
draw_frame(duration);
print(fig, outputs.poster, '-dpng', '-r100');
exportgraphics(fig, outputs.posterPDF, 'ContentType', 'vector', 'BackgroundColor', fig.Color);
savefig(fig, outputs.figure);
provenance = struct('sourceFiles', files, 'sourceSHA256', {sourceHashes}, ...
    'options', p, 'scenario', scenario, 'pathXY', pathXY, 'stateLabels', {stateLabels}, ...
    'stateIndices', stateIndices, 'actions', actions, 'frameTimes', frameTimes, ...
    'neuralTimes', neuralTimes, 'replaySteps', replaySteps, 'previewTimes', previewTimes, ...
    'replayActions', replayActions, 'replayHolding', replayHolding, ...
    'arrivalTimes', arrivalTimes, 'previewStatusText', {previewStatusText}, ...
    'replayStart', replayStart, 'rankColours', rankColours, ...
    'clock', 'Source planning coordinates 0-1; frozen during the independent schematic replay', ...
    'createdUTC', char(datetime('now', 'TimeZone', 'UTC')), ...
    'paperURL', 'https://www.sciencedirect.com/science/article/pii/S2211124726009836');
provenance.signals = rmfield(records, 'handle');
provenance.rasterImages = rmfield(images, 'handle');
provenance.codeFiles = {[mfilename('fullpath') '.m'], which('mushiake_movie_path'), which('chen_sequence_movie_options')};
provenance.codeSHA256 = cellfun(@sha256, provenance.codeFiles, 'UniformOutput', false);
save(outputs.provenance, 'provenance', '-v7');
if p.previewOnly
    fprintf('Saved Mushiake %s previews: %s\n', p.caseName, p.outputDir);
    return;
end
framesDir = tempname; mkdir(framesDir);
cleanupFrames = onCleanup(@() remove_frames(framesDir, p.keepFrames));
fprintf('Rendering %d frames at %g fps: %s\n', numel(frameTimes), p.frameRate, outputs.video);
for k = 1:numel(frameTimes)
    draw_frame(frameTimes(k));
    print(fig, fullfile(framesDir, sprintf('frame_%06d.png', k)), '-dpng', '-r100');
    if mod(k, 20) == 0 || k == numel(frameTimes)
        fprintf('  frame %d/%d\n', k, numel(frameTimes));
    end
end
verify_frame(records, images, 1);
assert(isequal(sourceHashes, cellfun(@sha256, paths, 'UniformOutput', false)), ...
    'Mushiake_Fig02_Movie:ChangedSource', 'A saved input changed during rendering.');
encode_movie(framesDir, outputs.video, p);
outputs.framesDir = '';
if p.keepFrames, outputs.framesDir = framesDir; end
fprintf('Saved %s\n', outputs.video);

    function draw_frame(playbackTime)
        neuralTime = min(1, playbackTime * p.playbackSpeed);
        [step, action, holding] = replay_timing(playbackTime, replayStart, p);
        for i = 1:numel(records)
            r = records(i); y = r.y;
            y(r.x > neuralTime + 1e-10) = NaN;
            set(r.handle, 'XData', r.x, 'YData', y);
        end
        for i = 1:numel(images)
            r = images(i); alpha = r.alpha;
            alpha(:, r.time > neuralTime + 1e-10) = 0;
            r.handle.AlphaData = alpha;
        end
        set(heads, 'Value', neuralTime);
        pathView.setStep(step);
        for i = 1:3
            if neuralTime < 1
                cards(i).String = sprintf('?(%d)', i);
            else
                cards(i).String = sprintf('%c(%d)', p.caseName(i), i);
            end
        end
        if playbackTime < planningSeconds
            phaseText.String = '1 / 2   PLANNING  |  Inference over the complete action sequence';
            clockText.String = sprintf('t = %.2f', neuralTime);
            statusText.String = sprintf('Start %s   |   Goal %s', stateLabels{1}, stateLabels{end});
        elseif playbackTime < replayStart
            phaseText.String = 'PLAN READY  |  Sustained sequence-selective responses';
            clockText.String = 't = 1.00';
            statusText.String = sprintf('Inferred sequence: %s', p.caseName);
        else
            phaseText.String = '2 / 2   PATH REPLAY  |  Schematic movement; neural time frozen at t = 1';
            clockText.String = sprintf('Replay  %d / 3', action);
            if holding
                statusText.String = sprintf('State %s   |   Step %d / 3', stateLabels{action + 1}, action);
            else
                statusText.String = sprintf('%s  to  %s   |   Step %d / 3', ...
                    stateLabels{action}, stateLabels{action + 1}, action);
            end
        end
        drawnow;
    end
end

function [step, action, holding] = replay_timing(time, replayStart, p)
% Alternate motion and a readable dwell at each destination, including the goal.
elapsed = max(0, time - replayStart);
cycleSeconds = p.replayStepSeconds + p.replayStateHoldSeconds;
action = min(3, floor((elapsed + 1e-10) / cycleSeconds) + 1);
withinAction = max(0, elapsed - (action - 1) * cycleSeconds);
step = action - 1 + min(1, withinAction / p.replayStepSeconds);
holding = time >= replayStart & withinAction >= p.replayStepSeconds - 1e-10;
end

function [ax, legendOut] = copy_panel(path, fig)
source = openfig(path, 'new', 'invisible');
cleanup = onCleanup(@() close(source));
a = findall(source, 'Type', 'axes', 'Visible', 'on');
assert(isscalar(a), 'Mushiake_Fig02_Movie:AxesMismatch', 'Expected one data axes: %s', path);
legendOut = findall(source, 'Type', 'legend');
if ~isempty(legendOut)
    copied = copyobj([a; legendOut], fig);
    ax = copied(1); legendOut = copied(2);
else
    ax = copyobj(a, fig);
end
ax.Units = 'normalized'; ax.PositionConstraint = 'innerposition';
colormap(ax, colormap(a));
end

function format_axis(ax, position, fontSize)
set(ax, 'Units', 'normalized', 'Position', position, 'FontSize', fontSize, ...
    'FontName', 'DejaVu Sans', 'Color', 'w', 'XLimMode', 'manual', 'YLimMode', 'manual');
set(findall(ax, 'Type', 'text'), 'FontSize', fontSize, 'FontName', 'DejaVu Sans');
end

function [xy, labels, actions, states] = read_path(file, ax, expected)
data = load(file, 'MDP'); root = data.MDP;
if iscell(root), root = root{1}; end
low = root.mdp(1);
columns = find(low.s(2, 2:end) ~= 5) + 1;
actions = low.s(2, columns);
alphabet = 'UDLRS';
assert(isequal(alphabet(actions), expected) && isequal(columns, 2:4), ...
    'Mushiake_Fig02_Movie:PolicyMismatch', 'Cached MDP does not match the requested three-action policy.');
states = [low.s(1, 1), low.s(1, columns)];
objects = findall(ax, 'Type', 'image');
assert(isscalar(objects), 'Mushiake_Fig02_Movie:MazeImage', 'Expected one maze map.');
maze = objects.CData;
assert(isequal(size(maze), [5, 5]) && all(ismember(maze(:), [0, 1])), ...
    'Mushiake_Fig02_Movie:MazeMap', 'Expected the binary 5-by-5 maze.');
map = zeros(size(maze)); n = 0;
for row = 1:5
    for col = 1:5
        if maze(row, col), n = n + 1; map(row, col) = n; end
    end
end
xy = zeros(4, 2); labels = cell(1, 4);
for k = 1:4
    [row, col] = find(map == states(k));
    assert(isscalar(row), 'Mushiake_Fig02_Movie:StateMap', 'Invalid cached state.');
    xy(k, :) = [col, row]; labels{k} = sprintf('S_{%d%d}', row, col);
end
directions = [0, -1; 0, 1; -1, 0; 1, 0];
assert(isequal(diff(xy), directions(actions, :)), ...
    'Mushiake_Fig02_Movie:TransitionMismatch', 'Cached state/action transitions disagree.');
[~, goal] = max(low.C{1}(:, 1));
assert(states(end) == goal, 'Mushiake_Fig02_Movie:GoalMismatch', 'Cached path does not reach the goal.');
% Check the maze's drawn walls at every traversed doorway, without rebuilding it.
walls = findall(ax, 'Type', 'line');
for k = 1:3
    midpoint = mean(xy(k:k + 1, :), 1);
    for j = 1:numel(walls)
        x = walls(j).XData; y = walls(j).YData;
        if numel(x) ~= 2, continue; end
        onWall = min(x) - eps <= midpoint(1) && midpoint(1) <= max(x) + eps ...
            && min(y) - eps <= midpoint(2) && midpoint(2) <= max(y) + eps;
        assert(~onWall, 'Mushiake_Fig02_Movie:ClosedDoor', 'Cached path crosses a drawn wall.');
    end
end
end

function [records, images] = capture_signals(rasterAx, rateAx)
records = struct('handle', {}, 'x', {}, 'y', {}, 'kind', {}, 'color', {});
colours = zeros(0, 3);
objects = findall(rasterAx, 'Type', 'line');
for k = 1:numel(objects)
    h = objects(k); x = h.XData; y = h.YData;
    if numel(x) ~= 2 || any(~isfinite([x, y])) || abs(diff(x)) > 1e-9 ...
            || abs(diff(y)) > 1 || abs(diff(y)) < eps
        continue;
    end
    group = find(all(abs(colours - h.Color) < 1e-10, 2), 1);
    if isempty(group)
        colours(end + 1, :) = h.Color; group = size(colours, 1); %#ok<AGROW>
        records(group) = struct('handle', h, 'x', [], 'y', [], 'kind', 'spike', 'color', h.Color);
    end
    records(group).x = [records(group).x, x, NaN];
    records(group).y = [records(group).y, y, NaN];
    delete(h);
end
for k = 1:numel(records)
    records(k).handle = line(rasterAx, records(k).x, records(k).y, ...
        'Color', records(k).color, 'LineWidth', 0.8, 'HandleVisibility', 'off');
end
objects = findall(rateAx, 'Type', 'line');
for k = 1:numel(objects)
    h = objects(k);
    records(end + 1) = struct('handle', h, 'x', h.XData, 'y', h.YData, ...
        'kind', 'rate', 'color', h.Color); %#ok<AGROW>
end
images = struct('handle', {}, 'time', {}, 'cdata', {}, 'alpha', {});
objects = findall(rasterAx, 'Type', 'image');
for k = 1:numel(objects)
    h = objects(k); alpha = h.AlphaData;
    if isscalar(alpha), alpha = repmat(alpha, size(h.CData)); end
    images(end + 1) = struct('handle', h, ...
        'time', linspace(h.XData(1), h.XData(end), size(h.CData, 2)), ...
        'cdata', h.CData, 'alpha', alpha); %#ok<AGROW>
end
end

function verify_frame(records, images, time)
for k = 1:numel(records)
    r = records(k); y = r.y; y(r.x > time + 1e-10 | isnan(r.x)) = NaN;
    assert(isequaln(r.handle.XData, r.x) && isequaln(r.handle.YData, y), ...
        'Mushiake_Fig02_Movie:ChangedSignal', 'Saved signal coordinates were changed.');
end
for k = 1:numel(images)
    r = images(k); alpha = r.alpha; alpha(:, r.time > time + 1e-10) = 0;
    assert(isequaln(r.handle.CData, r.cdata) && isequaln(r.handle.AlphaData, alpha), ...
        'Mushiake_Fig02_Movie:ChangedImage', 'Raster values or reveal mask were changed.');
end
end

function h = boxtext(fig, position, value, fontSize, colour, weight)
h = annotation(fig, 'textbox', position, 'String', value, 'FontSize', fontSize, ...
    'Color', colour, 'FontWeight', weight, 'EdgeColor', 'none', 'Interpreter', 'none', ...
    'Margin', 0, 'VerticalAlignment', 'middle');
end

function encode_movie(directory, output, p)
temporary = [tempname(fileparts(output)) '.mp4'];
cleanup = onCleanup(@() delete_if_present(temporary));
filter = sprintf(['pad=ceil(iw/2)*2:ceil(ih/2)*2,' ...
    'tpad=start_mode=clone:start_duration=%g:stop_mode=clone:stop_duration=%g'], ...
    p.holdStartSeconds, p.holdEndSeconds);
prefix = '';
if isunix, prefix = 'env -u LD_LIBRARY_PATH -u LD_PRELOAD '; end
command = sprintf(['%sffmpeg -hide_banner -loglevel error -y -framerate %g -i %s ' ...
    '-vf %s -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -movflags +faststart %s'], ...
    prefix, p.frameRate, shell_quote(fullfile(directory, 'frame_%06d.png')), ...
    shell_quote(filter), shell_quote(temporary));
[status, message] = system(command);
assert(status == 0, 'Mushiake_Fig02_Movie:EncodingFailed', 'ffmpeg failed: %s', message);
movefile(temporary, output, 'f');
end

function value = shell_quote(value)
if ispc
    value = ['"' strrep(char(value), '"', '""') '"'];
else
    value = ['''' strrep(char(value), '''', '''"''"''') ''''];
end
end

function hash = sha256(path)
fid = fopen(path, 'rb');
assert(fid >= 0, 'Mushiake_Fig02_Movie:UnreadableSource', 'Cannot read %s.', path);
cleanup = onCleanup(@() fclose(fid));
md = java.security.MessageDigest.getInstance('SHA-256');
while ~feof(fid), md.update(fread(fid, 1024 * 1024, '*uint8')); end
bytes = typecast(md.digest(), 'uint8');
hash = lower(reshape(dec2hex(bytes, 2)', 1, []));
end

function remove_frames(path, keep)
if ~keep && isfolder(path), rmdir(path, 's'); end
end

function delete_if_present(path)
if isfile(path), delete(path); end
end

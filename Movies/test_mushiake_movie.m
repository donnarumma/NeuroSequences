function test_mushiake_movie(sourceDir)
%TEST_MUSHIAKE_MOVIE Check path overlays and numerical saved-source fidelity.
% Uses only MATLAB graphics and existing exports; does not run a simulation.
if nargin < 1
    sourceDir = '/TESTS/HAI_SEQUENCES/Mushiake/Mushiake_SEQUENCES_UDLRS/Rep01';
end
directory = tempname; mkdir(directory);
cleanupDirectory = onCleanup(@() rmdir(directory, 's'));
fig = figure('Visible', 'off');
cleanupFigure = onCleanup(@() close(fig));
ax = axes(fig);
xy = [3, 3; 3, 2; 2, 2; 1, 2];
colours = lines(3);
view = mushiake_movie_path(ax, xy, colours);
for step = [0, 0.5, 1, 2, 3, 0]
    view.setStep(step);
    segment = max(1, ceil(step));
    fraction = step - (segment - 1);
    expected = xy(segment, :) + fraction * (xy(segment + 1, :) - xy(segment, :));
    assert(max(abs(view.cursor.Position(1:2) + 0.34 - expected)) < 1e-12);
    for k = 1:3
        assert(strcmp(view.arrows(k).Visible, 'on') == (step >= k - 1 + 0.15));
    end
end
for name = {'ULL', 'URR'}
    out = Mushiake_Fig02_Movie(struct('caseName', name{1}, 'sourceDir', sourceDir, ...
        'outputDir', fullfile(directory, name{1}), 'previewOnly', true));
    assert(~isfile(out.video) && numel(out.previews) == 7);
    data = load(out.provenance, 'provenance'); p = data.provenance;
    assert(isequal(p.pathXY(1, :), [3, 3]) && isequal(p.pathXY(2, :), [3, 2]));
    if strcmp(name{1}, 'ULL')
        assert(isequal(p.pathXY, xy));
    else
        assert(isequal(p.pathXY, [3, 3; 3, 2; 4, 2; 5, 2]));
    end
    assert(all(p.neuralTimes(p.frameTimes >= p.replayStart) == 1));
    assert(p.replaySteps(1) == 0 && p.replaySteps(end) == 3);
    assert(all(diff(p.replaySteps) >= -1e-10));
    for k = 1:3
        frames = p.replayHolding & p.replayActions == k;
        assert(sum(frames) >= floor(p.options.replayStateHoldSeconds * p.options.frameRate));
        assert(all(abs(p.replaySteps(frames) - k) < 1e-10));
        expectedText = sprintf('State %s   |   Step %d / 3', p.stateLabels{k + 1}, k);
        assert(strcmp(p.previewStatusText{k + 4}, expectedText));
    end
    source = openfig(p.sourceFiles.firingRate, 'new', 'invisible');
    cleanupSource = onCleanup(@() close(source));
    original = findall(findall(source, 'Type', 'axes', 'Visible', 'on'), 'Type', 'line');
    stored = p.signals(strcmp({p.signals.kind}, 'rate'));
    assert(numel(original) == numel(stored));
    for k = 1:numel(original)
        found = arrayfun(@(r) isequaln(r.x, original(k).XData) ...
            && isequaln(r.y, original(k).YData) && isequal(r.color, original(k).Color), stored);
        assert(any(found), 'A saved firing-rate trace was not preserved.');
    end
    clear cleanupSource;
    source = openfig(p.sourceFiles.raster, 'new', 'invisible');
    cleanupSource = onCleanup(@() close(source));
    originalImages = findall(source, 'Type', 'image');
    assert(numel(originalImages) == numel(p.rasterImages));
    for k = 1:numel(originalImages)
        assert(isequaln(originalImages(k).CData, p.rasterImages(k).cdata));
    end
    ticks = findall(source, 'Type', 'line');
    spikes = p.signals(strcmp({p.signals.kind}, 'spike'));
    count = 0;
    for k = 1:numel(ticks)
        x = ticks(k).XData; y = ticks(k).YData;
        if numel(x) ~= 2 || any(~isfinite([x, y])) || abs(diff(x)) > 1e-9 ...
                || abs(diff(y)) > 1 || abs(diff(y)) < eps
            continue;
        end
        group = find(arrayfun(@(r) isequal(r.color, ticks(k).Color), spikes));
        assert(isscalar(group));
        savedX = reshape(spikes(group).x, 3, []);
        savedY = reshape(spikes(group).y, 3, []);
        assert(any(all(savedX(1:2, :) == x(:), 1) & all(savedY(1:2, :) == y(:), 1)));
        count = count + 1;
    end
    assert(count == sum(arrayfun(@(r) numel(r.x) / 3, spikes)));
    clear cleanupSource;
end
fprintf('Mushiake movie checks passed: readable state/step holds, both paths, frozen replay clock, all rate traces, all spike ticks and raster images.\n');
end

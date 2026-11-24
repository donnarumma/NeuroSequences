function view = mushiake_movie_path(ax, pathXY, colours)
%MUSHIAKE_MOVIE_PATH Add a stepwise path overlay to an existing maze axes.
%   view = mushiake_movie_path(ax, [3 3; 3 2; 2 2; 1 2]);
%   view.setStep(0);   % start state
%   view.setStep(1);   % first destination (fractional steps interpolate)
% Coordinates are [column, row], matching plot_MAZE. This is an illustrative
% overlay, not an inference routine or a mapping from neural time to motion.
validateattributes(pathXY, {'numeric'}, {'2d', 'ncols', 2, 'finite'});
nSteps = size(pathXY, 1) - 1;
assert(nSteps >= 1 && all(sum(abs(diff(pathXY)), 2) == 1), ...
    'mushiake_movie_path:InvalidPath', 'Path must contain adjacent maze cells.');
if nargin < 3
    colours = lines(nSteps);
end
validateattributes(colours, {'numeric'}, {'size', [nSteps, 3], '>=', 0, '<=', 1});
wasHeld = ishold(ax);
hold(ax, 'on');
arrows = gobjects(1, nSteps);
for k = 1:nSteps
    delta = pathXY(k + 1, :) - pathXY(k, :);
    start = pathXY(k, :) + 0.28 * delta;
    arrows(k) = quiver(ax, start(1), start(2), 0.44 * delta(1), 0.44 * delta(2), ...
        0, 'Color', colours(k, :), 'LineWidth', 3.5, 'MaxHeadSize', 1.2, ...
        'Visible', 'off', 'HandleVisibility', 'off');
end
cursor = rectangle(ax, 'Position', [pathXY(1, :) - 0.34, 0.68, 0.68], ...
    'Curvature', [1, 1], 'EdgeColor', [0.08, 0.25, 0.36], ...
    'LineWidth', 2.5, 'FaceColor', 'none');
if ~wasHeld, hold(ax, 'off'); end
view.setStep = @update;
view.cursor = cursor;
view.arrows = arrows;
view.pathXY = pathXY;

    function update(step)
        validateattributes(step, {'numeric'}, {'scalar', 'finite', '>=', 0, '<=', nSteps});
        segment = max(1, ceil(step));
        fraction = step - (segment - 1);
        position = pathXY(segment, :) + fraction * (pathXY(segment + 1, :) - pathXY(segment, :));
        cursor.Position = [position - 0.34, 0.68, 0.68];
        if step > 0
            cursor.EdgeColor = colours(segment, :);
        else
            cursor.EdgeColor = [0.08, 0.25, 0.36];
        end
        for j = 1:nSteps
            if step >= j - 1 + 0.15
                arrows(j).Visible = 'on';
            else
                arrows(j).Visible = 'off';
            end
        end
    end
end

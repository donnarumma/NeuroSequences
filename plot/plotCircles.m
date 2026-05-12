function hfig = plotCircles(par)
%PLOTCIRCLES Draw a circular target layout used in Xie target panels.
%
% hfig = plotCircles(par)
%
% Required fields in par:
%   par.target : selected target index
%   par.labels : cell array of LaTeX labels for the peripheral circles
%
% Optional:
%   par.hfig   : existing figure handle

if ~isfield(par, 'hfig') || isempty(par.hfig) || ~isvalid(par.hfig)
    hfig = figure('Color', 'w');
else
    hfig = par.hfig;
end

target = par.target;
labels = par.labels;
nCircles = numel(labels);

theta = linspace(0, 2*pi, nCircles + 1) + pi/2;
theta = theta(end:-1:1);
theta(end) = [];

radius = 1;
circleRadius = 0.2;
lineWidth = 3;

hold on;
box on;
axis equal;

faceColors = 0.8 * ones(nCircles, 3);
if target >= 1 && target <= nCircles && target == floor(target)
    faceColors(target, :) = [1, 0, 0];
end
centerColor = 'green';
if target == 0
    centerColor = 0.8 * ones(1, 3);
end

rectangle( ...
    'Position', [0 - circleRadius, 0 - circleRadius, 2 * circleRadius, 2 * circleRadius], ...
    'Curvature', [1, 1], ...
    'EdgeColor', 'k', ...
    'LineWidth', lineWidth, ...
    'FaceColor', centerColor);

points = nan(nCircles, 2);
for iCircle = 1:nCircles
    x = radius * cos(theta(iCircle));
    y = radius * sin(theta(iCircle));
    points(iCircle, :) = [x, y];

    rectangle( ...
        'Position', [x - circleRadius, y - circleRadius, 2 * circleRadius, 2 * circleRadius], ...
        'Curvature', [1, 1], ...
        'EdgeColor', 'k', ...
        'LineWidth', lineWidth, ...
        'FaceColor', faceColors(iCircle, :));

    text(x, y, labels{iCircle}, ...
        'HorizontalAlignment', 'center', ...
        'FontSize', 16, ...
        'Interpreter', 'latex');
end

grid on;
xlabel('');
ylabel('');
xticks([]);
yticks([]);
hold off;

xLimits = [min(points(:, 1)) - 2 * circleRadius, max(points(:, 1)) + 2 * circleRadius];
yLimits = [min(points(:, 2)) - 2 * circleRadius, max(points(:, 2)) + 2 * circleRadius];
limits = [min([xLimits, yLimits]), max([xLimits, yLimits])];
xlim(limits);
ylim(limits);

ax = gca;
ax.LineWidth = 7;
ax.Box = 'on';
ax.XColor = 'k';
ax.YColor = 'k';

end

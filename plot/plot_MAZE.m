function   hfig = plot_MAZE(MAZE, par)
% function hfig = plot_MAZE(MAZE, par)
% PLOT_MAZE Visualizes a maze with explicitly defined transitions.
%
% Inputs:
%   MAZE: binary matrix (0=blocked, 1=open)
%   par:  struct with visualization parameters, including transitions
%
% Example usage:
%   pms  = plot_MAZEParams;
%   hfig = plot_MAZE(MAZE, pms);

execinfo = par.exec;
if ~isempty(execinfo)
    t = tic;
    fprintf('Function: %s \n', mfilename);
end

if isempty(par.hfig) || ~isvalid(par.hfig)
    hfig = figure;
else
    hfig = par.hfig;
end
imagesc(MAZE);
axis equal tight;
colormap(gray);
hold on;

[nRows, nCols]  = size(MAZE);
bordercol       = par.bordercol;
doorWidth       = par.doorWidth;
lw              = par.lw;
transitions     = par.transitions;
textcol         = par.textcol;
halfdoorcol     = [0.7, 0.7, 0.7]; % gray for half-open doors
fs              = par.fs;
par.fa          = 50;

arrowOffset     = 0;%0.3;
arrows          = {'↑', '↓', '←', '→'};
dRow            = [-1, 1, 0, 0];
dCol            = [0, 0, -1, 1];
% actions         = {'up', 'down', 'left', 'right'};
opposite_Dirs   = [2,1,4,3];

% plot arrows, doors and borders
for iRow = 1:nRows
    for iCol = 1:nCols
        if MAZE(iRow, iCol) == 0, continue; end

        for iDir = 1:4
            niRow = iRow + dRow(iDir);
            niCol = iCol + dCol(iDir);

            if niRow < 1 || niRow > nRows || niCol < 1 || niCol > nCols
                continue;
            end

            current  = transitions(iRow,iCol,iDir);
            opposite = transitions(niRow,niCol,opposite_Dirs(iDir));
            
            % fprintf('S%g%g,u:%s, val=%g\n',iRow,iCol,actions{iDir},transitions(iRow,iCol,iDir))

            % Coordinates for walls and doors
            if iDir <= 2  % horizontal wall (up/down)
                x_wall = [iCol-0.5, iCol+0.5];
                y_wall = [iRow-0.5, iRow-0.5] + (iDir-1);
                door_x = [mean(x_wall)-doorWidth/2, mean(x_wall)+doorWidth/2];
                door_y = y_wall;
                arrow_x = mean(door_x);
                arrow_y = door_y(1) + arrowOffset*dRow(iDir);
            else  % vertical wall (left/right)
                x_wall = [iCol-0.5, iCol-0.5] + (iDir-3);
                y_wall = [iRow-0.5, iRow+0.5];
                door_x = x_wall;
                door_y = [mean(y_wall)-doorWidth/2, mean(y_wall)+doorWidth/2];
                arrow_x = door_x(1) + arrowOffset*dCol(iDir);
                arrow_y = mean(door_y);
            end

            if current && opposite
                % Fully open door
                line([x_wall(1), door_x(1)], [y_wall(1), door_y(1)], 'Color', bordercol, 'LineWidth', lw);
                line([door_x(2), x_wall(2)], [door_y(2), y_wall(2)], 'Color', bordercol, 'LineWidth', lw);

            elseif xor(current, opposite)
                % Asymmetric transition (gray door with arrow if outgoing transition allowed)
                line([x_wall(1), door_x(1)], [y_wall(1), door_y(1)], 'Color', bordercol, 'LineWidth', lw);
                line(door_x, door_y, 'Color', halfdoorcol, 'LineWidth', lw);
                line([door_x(2), x_wall(2)], [door_y(2), y_wall(2)], 'Color', bordercol, 'LineWidth', lw);

                if current
                    % Correct scalar positions for arrow
                    text(arrow_x, arrow_y, arrows{iDir}, ...
                        'Color', halfdoorcol, 'FontSize', par.fa, ...
                        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
                end
            else
                % Fully closed wall
                line(x_wall, y_wall, 'Color', bordercol, 'LineWidth', lw);
            end
        end
    end
end

labelsmode = par.labelsmode;
% set state labels
labels = cell(nRows, nCols);
switch labelsmode
    case 1  %% Sij  
    for iRow = 1:nRows
        for iCol = 1:nCols
            labels{iRow, iCol} = sprintf('S_{%d%d}', iRow, iCol);
        end
    end
    labels(~MAZE) = {''};
    case 2 %% 1:K
    labels(~MAZE)   = {''};
    labels=labels';
    labels(~~MAZE)  = arrayfun(@num2str, 1:sum(MAZE(:)), 'UniformOutput', false);
    labels=labels';
    case 3 %% alphabet
    alphabet='A':'Y';
    for iter=1:length(alphabet)
        labels{iter}=alphabet(iter);
    end
    labels=labels';
    labels(~MAZE)   = {''};
    otherwise %% no labels
    labels(:)   = {''};
end

% plot start and goal
start                               = par.start2d; % [3,3];
goal                                = par.goal2d;  % [5,2];
hold on
ms = 65; %40
mlw = 2;
splt=plot(start(1), start(2), 's', 'MarkerSize', ms, 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'k', 'LineWidth', mlw); % Green filled square
gplt=plot( goal(1),  goal(2), 'o', 'MarkerSize', ms, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k', 'LineWidth', mlw); % Red filled circle


for iRow = 1:nRows
    for iCol = 1:nCols
        text(iCol, iRow, labels{iRow, iCol}, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'Color', textcol,'FontSize',fs);
    end
end



hold off;
xticks(1:nCols);
yticks(1:nRows);

set(gca, 'YDir', 'reverse');
p = [0,0,800,800];
set(hfig, 'PaperPositionMode','auto', 'Position', p);
% borderThickness = 5; % Adjust this value to control border thickness

% Add thick black border
ax              = gca; 
ax.LineWidth    = lw;
ax.Box          = 'on';
ax.XColor       = 'k';
ax.YColor       = 'k';

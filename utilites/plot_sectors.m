function   plot_sectors(time, fractions, labels, dst, behind)
% function plot_sectors(time, fractions, labels, dst)
    % Plot the data
    % figure; plot(t, X, 'LineWidth', 1.5); hold on;
    try 
        behind;
    catch
        behind=false;
    end
    if ~behind
        colline=zeros(3,1);
    else
        colline=0.8*ones(3,1);
    end
    xlim([min(time), max(time)]);
    
    % Check inputs
    assert(abs(sum(fractions) - 1) < 1e-6, 'Fractions must sum to 1');
    assert(length(fractions) == length(labels), 'Each fraction must have a label');

    % Compute sector boundaries
    T_start = min(time);
    T_end   = max(time);
    T_range = T_end - T_start + mean(diff(time));
    edges   = [0, cumsum(fractions)] * T_range;% + T_start;

    % Store line handles to send them to background
    xlineHandles = gobjects(length(edges)-2, 1);  % preallocate

    % Draw vertical lines and label sectors
    for k = 2:length(edges)-1
        xlineHandles(k-1)=line([edges(k), edges(k)], ylim, ...
                         'Color', colline, 'LineWidth', 3); %xline(edges(k), 'color', 0.3*ones(3,1), 'LineWidth', 3);
        if behind
            uistack(xlineHandles(k-1), 'bottom');
        end
    end

    % Move the main plot up and shrink to make space
    ax1         = gca;
    pos1        = get(ax1, 'Position');
    pos1(2)     = pos1(2) + dst(2);%0.05; 0.1;    % move main axis up
    pos1(4)     = pos1(4) - 0.1;    % reduce its height
    set(ax1, 'Position', pos1);

    % Now create label axis in the freed space
    labelPos    = pos1;
    labelDown   = dst(1);                   % 0.2;% 06; % height for labels
    labelHeight = 0.1;                      % shrink the height

    labelPos(2) = pos1(2) - labelDown;  % new axis just below the main one
    labelPos(4) = labelHeight;             % enough height for text
    ax2 = axes('Position', labelPos, ...
               'Color', 'none', ...
               'XLim', [min(time), max(time)], ...
               'YLim', [0, 1], ...
               'XTick', [], 'YTick', [], ...
               'Box', 'off','Visible', 'off');
    
    % Add text labels at the center of each sector
    for k = 1:length(fractions)
        center = (edges(k) + edges(k+1)) / 2;
        
        text(center,0.5,labels{k},'Parent',ax2,'HorizontalAlignment','center', ...
               'VerticalAlignment','middle','FontSize',25,'FontWeight','bold');
    end
    linkaxes([ax1 ax2], 'x');
end

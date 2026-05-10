%% Hexagon + 6 3D lines with opening control
figName = 'Sensory';
ifplot = false;
hfg.(figName)=figure('Visible',ifplot); clf; hold on; axis equal; box on
set(gcf,'Color','w');
p =[0,0,5000,450];
fs=16;
rng(50);
%-------------------------
% USER PARAMETERS
%-------------------------
openFrac    = 0.1;%0.60;   % [0,1) fraction of the trajectory that is flat/common
widenFactor = 0.1;    % >=0, how much they spread away from the trunk

%-------------------------
% Hexagon in 3D
%-------------------------
nVert   = 6;
R       = 1.0;
hexCtr  = [0 0 0];
% zHexs   = [3,6,9];
zHexs   = [1,2,3];
sig     = 0.4;

angles  = linspace(0, 2*pi, nVert+1); angles(end) = [];


% Colored vertices (you can change colors here)
vertexColors = [ ...
    0.00 0.45 0.74;  % blue
    0.85 0.33 0.10;  % orange
    0.93 0.69 0.13;  % yellow
    0.47 0.67 0.19;  % green
    0.85 0.33 0.10;  % orange/red
    0.80 0.10 0.10]; % red

colors = [  ...
            0.0 0.8 0.9;    % cyan
            1.0 0.3 0.9;    % magenta
            1.0 0.7 0.0;    % orange
         ];    

%-------------------------
% 3D “axonal” curves
%-------------------------
startPoint = [0 0 0];               % common origin
dz          = -0.9;% -2;
splitPoints = [zHexs(1)+dz, 0, 0; ...
               zHexs(2)+dz, 0, 0; ...
               2.7, 0, 0];           % where they start enlarging
% lineColor  = [0.95 0.7 0];        % yellow–orange
nSamples            = 200;

params.nVert        = nVert;
params.startPoint   = startPoint;
params.nSamples     = nSamples;
params.openFrac     = openFrac;
params.widenFactor  = widenFactor;
params.Extend       = 50;
starts              = [1,50,50];
% hfg.Backward        = figure;

% nTiles              = 3;
% t                   = tiledlayout(nTiles, 1);
for iPlot=1:3
    % ax3D=nexttile;
  
    hold on;
    zHex    = zHexs(iPlot);
    vy      = hexCtr(1) + R*cos(angles) + rand(1,nVert)*sig;
    vz      = hexCtr(2) + R*sin(angles) + rand(1,nVert)*sig;
    vx      = zHex*ones(size(vy));
    
    plot3([vx vx(1)], [vy vy(1)], [vz vz(1)], ...
      'k-', 'LineWidth', 4);   % hexagon edges


    for k = 1:nVert
        scatter3(vx(k), vy(k), vz(k), ...
                 200, vertexColors(k,:), 'filled');
    end
    
    params.vx           = vx;
    params.vy           = vy;
    params.vz           = vz;
    params.splitPoint   = splitPoints(iPlot,:);

    params.lineColor    = colors(iPlot,:);
    params.start        = starts(iPlot);
    plotPCAHexagonTraj(params);
    ax3D=gca;
    set(ax3D,'fontsize',fs);
    % l=text(-1.5,0.4,2.5,sprintf('Memory-%d',iPlot), ...
    %     'HorizontalAlignment','right', ...
    %     'VerticalAlignment','middle', ...
    %     'FontName','Helvetica', ...
    %     'FontSize',20,'Rotation', 90,'FontWeight','Bold');
    % set(l,'Clipping','off');       % <-- add this
    % set(gca,'Clipping','off');


    % xlim([-2 6]);
    % view(10,-25)
    % view(-7,22)

    view(ax3D,-7,22);

    % Get position of this tile in figure-normalized coordinates
    % pos = ax3D.Position;

    % Create overlay axes at same position
    % axLabel = axes('Position',pos, ...
    %                'Color','none', ...
    %                'XLim',[0 1],'YLim',[0 1], ...
    %                'XTick',[],'YTick',[], ...
    %                'HitTest','off', ...
    %                'Box','off');

    % Put rotated text near the left edge of the tile
    % text(axLabel, 0.02, 0.5, sprintf('Memory-%d',iPlot), ...
    %     'Rotation',90, ...
    %     'HorizontalAlignment','center', ...
    %     'VerticalAlignment','middle', ...
    %     'FontName','Helvetica', ...
    %     'FontSize',20,'FontWeight','bold');
    % Make sure future plotting goes back to 3D axes
    % axes(ax3D);
    % view(35,25);
    % axis off;
end
ax3D=gca;
view(ax3D,-7,22);
text(ax3D, -0.8,0,0+0.8, sprintf('Sensory'), ...
    'HorizontalAlignment','right', ...
    'VerticalAlignment','middle', ...
    'Rotation',90, 'FontSize',20, ...
    'FontWeight','bold', ...
    'Clipping','off');
    
xlabel('time');
hY          = ylabel('axis 1','Rotation',-70);
% pos         = hY.Position;       % [x y z] in data units for 3D axes
% pos(2)      = pos(2) - 0.0005;   % move right (closer to axis)
% hY.Position = pos;

hZ          = zlabel('axis 2');
pos         = hZ.Position;       % [x y z] in data units for 3D axes
pos(1)      = pos(1)+0.4;   % move right (closer to axis)
hZ.Position = pos
set(gca,'Clipping','off');
ylim([-1,1]);
zlim([-1,1]);
xticks(0:5);
xlim([0,5])    
% S1,S2,S3,Delay (posizioni teoriche)
% sPos = [sort(splitPoints(:,1)); max(splitPoints(:,1))+1.5]-0.5;%+0.7;
labels = {'S1','S2','S3','Delay'};
sPos =[ -0.4,    0.6,    1.7,    2.8];
for i = 1:4
    % plot(sPos(i),-5-1.05,'k|','LineWidth',1.2);
   spo= text(sPos(i)+1,0,-1.5, labels{i}, ...
        'HorizontalAlignment','center', ...
        'FontSize',24,'FontWeight','bol');
   set(spo, 'Clipping', 'off');
   set(gca,'Clipping', 'off');
end
set(hfg.(figName),'Position',p);
if ~ifplot
    fprintf('Step 6. save some plots\n')
    path_dir                    = '~/TESTS/HAI_LANGUAGE/SEQUENCES/FIG4/';
    description                 = figName;
    save_dir                    = [path_dir description '/'];
    par.hfigPrint               = hfigPrintParams();
    par.hfigPrint.pdf_file      = [path_dir '/' description '.pdf'];
    par.hfigPrint.save_dir      = path_dir; 
    hfigPrint(hfg,par.hfigPrint)
end

return

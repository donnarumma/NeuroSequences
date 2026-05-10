%% Hexagon + 6 3D lines with opening control
figName = 'Forward';
ifplot = false;
hfg.(figName)=figure('Visible',ifplot); clf; hold on; axis equal; box on
set(gcf,'Color','w');
p =[0,0,600,700];
fs=16;
rng(50);
%-------------------------
% USER PARAMETERS
%-------------------------
openFrac    = 0.1;%0.60;   % [0,1) fraction of the trajectory that is flat/common
widenFactor = 2.0;    % >=0, how much they spread away from the trunk

%-------------------------
% Hexagon in 3D
%-------------------------
nVert   = 6;
R       = 1.0;
hexCtr  = [0 0 0];
zHex    = 5;
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

colors = [ ...
    1.0 0.3 0.9;   % magenta
    0.0 0.8 0.9;   % cyan
    1.0 0.7 0.0;];  % orange
  

%-------------------------
% 3D “axonal” curves
%-------------------------
startPoint = [0 0 0];               % common origin

splitPoints = [3.0, 0, 0; ...
               2.0, 0, 0; ...
               1.0, 0, 0];           % where they start enlarging
% lineColor  = [0.95 0.7 0];        % yellow–orange
nSamples            = 200;

params.nVert        = nVert;
params.startPoint   = startPoint;
params.nSamples     = nSamples;
params.openFrac     = openFrac;
params.widenFactor  = widenFactor;
% hfg.Backward        = figure;

nTiles              = 3;
t                   = tiledlayout(nTiles, 1);
for iPlot=1:3
    ax3D=nexttile;
  
    hold on;
    
    vx      = zHex*ones(size(vx));
    vy      = hexCtr(1) + R*cos(angles) + rand(1,nVert)*sig;
    vz      = hexCtr(2) + R*sin(angles) + rand(1,nVert)*sig;

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
    plotPCAHexagonTraj(params);
    set(gca,'fontsize',fs);
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
    text(ax3D, -1.3,0.4,2.5, sprintf('Memory-%d',iPlot), ...
    'HorizontalAlignment','right', ...
    'VerticalAlignment','middle', ...
    'Rotation',90, 'FontSize',20, ...
    'FontWeight','bold', ...
    'Clipping','off');
    % Make sure future plotting goes back to 3D axes
    % axes(ax3D);
    % view(35,25);
    % axis off;
end
xlabel('time');
hY          = ylabel('axis 1');
% pos         = hY.Position;       % [x y z] in data units for 3D axes
% pos(2)      = pos(2) - 0.0005;   % move right (closer to axis)
% hY.Position = pos;

hZ          = zlabel('axis 2');
pos         = hZ.Position;       % [x y z] in data units for 3D axes
pos(1)      = pos(1) + 0.4;   % move right (closer to axis)
hZ.Position = pos;
set(gca,'Clipping','off');
    
% S1,S2,S3,Delay (posizioni teoriche)
sPos = [sort(splitPoints(:,1)); max(splitPoints(:,1))+1.5]-0.3;%+0.7;
labels = {'S1','S2','S3','Delay'};
for i = 1:4
    % plot(sPos(i),-5-1.05,'k|','LineWidth',1.2);
   spo= text(sPos(i),-1.18,-2.3, labels{i}, ...
        'HorizontalAlignment','center', ...
        'FontSize',24,'FontWeight','bol');
   set(spo, 'Clipping', 'off');
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


for k = 1:nVert
    P0 = startPoint;
    Pf = splitPoint;
    P2 = [vx(k) vy(k) vz(k)];

    t       = linspace(0,1,nSamples);
    nFlat   = max(2, round(openFrac * nSamples));  % samples in flat part

    x = zeros(size(t));
    y = zeros(size(t));
    z = zeros(size(t));

    % -------- flat common segment --------
    x(1:nFlat) = linspace(P0(1), Pf(1), nFlat);
    y(1:nFlat) = 0;
    z(1:nFlat) = 0;

    % -------- curved diverging part (quadratic Bézier) --------
    nCurv = nSamples - nFlat;
    if nCurv > 0
        tau = linspace(0,1,nCurv);

        % lateral offset for each branch
        baseYOffset = 0.5 * (k - (nVert+1)/2);  % spread across Y
        baseZOffset = 0.7;                      % amount in Z
        P1 = Pf + widenFactor * [0 baseYOffset baseZOffset];

        B0 = (1-tau).^2;
        B1 = 2*(1-tau).*tau;
        B2 = tau.^2;

        x(nFlat+1:end) = B0*Pf(1) + B1*P1(1) + B2*P2(1);
        y(nFlat+1:end) = B0*Pf(2) + B1*P1(2) + B2*P2(2);
        z(nFlat+1:end) = B0*Pf(3) + B1*P1(3) + B2*P2(3);
    end

    x = smooth(x,100);
    y = smooth(y,100);
    z = smooth(z,100);
    plot3(x,y,z,'-','LineWidth',6,'Color',lineColor);
end

% axis off;
% view(35,25);

%camproj('pe
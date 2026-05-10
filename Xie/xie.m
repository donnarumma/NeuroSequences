function hfg = xie()
%% Coordinates for each rank

ifplot = false;
rank1 = [
    -5.2  1.6;
     0.0  6.0;
     5.2  3.6;
     3.0 -1.8; % 3.0 -2.0;
     1.2 -4.7;
    -1.3 -5.6
];

rank2 = [
    -4.5  0.2;
     0.0  3.2;
     2.6  2.4;
     2.9 -1.0;
     0.0 -3.0;
    -2.0 -2.2
];

rank3 = [
    -3.6  0.2;
     0.0  2.6;
     2.6  2.3;
     2.6 -1.0; % 2.7 -1.0;
     1.7 -2.0; %  1.0 -2.3;
    -1.8 -2.0  % -1.8 -2.3 
];

colors=linspecer(6);

% colors = [
%     0.8500 0.3250 0.0980;   % orange
%     0.4660 0.6740 0.1880;   % green
%     0.6350 0.0780 0.1840;   % red
%     0.4940 0.1840 0.5560;   % purple
%     0.6350 0.3250 0.2780;   % brown
%     0.0000 0.4470 0.7410;   % blue
% ];

% central cloud points
cloud = [
   -0.3  0.2;
    0.2 -0.1;
    0.1  0.4;
   -0.2 -0.3;
    0.35 0.15;
   -0.05 0.0
];


ids = [  2,  3,  4,  5,  6,  1];
dx  = [0.5,0.5,0.5,0.5,0.5,0.5,];
dy  = [0.5,0.5,0.5,0.5,0.5,0.5,];
hfg.xieReproduction=figure('Position',[100 200 1100 350],'visible',ifplot);

%% ---------- Helper function ----------
function draw_panel(rankPts, titleStr, colors, cloudPts, labelFlag, ids, dx, dy)
    hold on, box on; grid on;
    % polygon lines
    poly = [rankPts; rankPts(1,:)];
    plot(poly(:,1), poly(:,2), 'Color',[0.6 0.6 0.6], 'LineWidth',1.5)

    % vertices with circle markers (o)
    for i = 1:size(rankPts,1)
        plot(rankPts(i,1), rankPts(i,2), 'o', ...
            'MarkerFaceColor', colors(i,:), ...
            'MarkerEdgeColor', [0.2 0.2 0.2], ...
            'MarkerSize', 10)
        if labelFlag
            text(rankPts(i,1)+dx(i), rankPts(i,2)+dy(i), sprintf('%d',ids(i)), ...
                 'Color',[0.3 0.3 0.3], 'FontSize',13)
        end
    end

    % translucent cloud
    for i = 1:size(cloudPts,1)
        scatter(cloudPts(i,1), cloudPts(i,2), 120, ...
                'MarkerFaceColor', colors(i,:), ...
                'MarkerEdgeColor','none', ...
                'MarkerFaceAlpha',0.25)
    end

    title(titleStr, 'FontSize', 16)
    xlabel('rPC1')
    ylabel('rPC2')
    xlim([-6 6]); ylim([-6 6])
    set(gca,'XTick',[-6 0 6],'YTick',[-6 0 6])
    set(gca,'fontsize',16)
    %set(gca, 'LooseInset', max(get(gca,'TightInset'), 0.02*[1 1 1 1]));
    axis equal
    box off
end

%% ---------- Plot panels ----------
subplot(1,3,1)
hold on; box on; grid on;
draw_panel(rank1, 'Rank-1 subspace', colors, cloud, false, ids, dx, dy)

subplot(1,3,2)
draw_panel(rank2, 'Rank-2 subspace', colors, cloud, false, ids, dx, dy)

subplot(1,3,3)
draw_panel(rank3, 'Rank-3 subspace', colors, cloud, false, ids, dx, dy)


%% save some plots
if ~ifplot
    fprintf('save some plots\n')
    path_dir                    = '/TESTS/HAI_SEQUENCES/Xie/';
    % path_dir                    = '~/TESTS/HAI_LANGUAGE/SEQUENCES/FIG3/';
    description                 = 'xieexagons';%mfilename;
    save_dir                    = [path_dir description '/'];
    par.hfigPrint               = hfigPrintParams();
    par.hfigPrint.pdf_file      = [path_dir '/' description '.pdf'];
    par.hfigPrint.save_dir      = path_dir; 
    hfigPrint(hfg,par.hfigPrint)
end

end
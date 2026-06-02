function   hfg=HAI_ABC_XIE_FiringRate_L1(hfg,data_trials,MDP,par)
% function hfg=HAI_ABC_XIE_FiringRate_L1(hfg,data_trials,MDP,par)

actions     = par.actions;
iFactor     = par.iFactor;
trials      = par.trials;
ifplot      = par.ifplot;
try
    nPoints=par.nPoints;
catch
    nPoints=10;
end
try 
    nActions=par.nActions;
catch
    nActions    = length(MDP{1}.mdp(1).D{iFactor});
end
try 
    reset=par.reset;
catch
    reset=0;
end
    nEpochs     = MDP{1}.mdp(1).T;
    nActionsRep = nEpochs*nActions;
    for iTrial=trials
        % MDP_Low     = MDP{iTrial}.mdp;
        icounter    = 0;
        labneurons  = actions(mod(0:nActionsRep-1,nActions)+1);
    % for iTime =1:nEpochs
    %     for iAction=1:nActions
    %         icounter=icounter+1;
    %         labneurons{icounter}=[labneurons{icounter} '(' num2str(iTime+reset) ')'];
    %     end
    % end
    
    timePotentials  = data_trials(iTrial).tPopFR;
    firingRates     = data_trials(iTrial).popFR;
    if isfield(par, 'firingRateFirstTimeOverride') && ~isempty(par.firingRateFirstTimeOverride)
        timePotentials(1) = par.firingRateFirstTimeOverride;
    end
    % firingRates(1:nActions,:)=0; % avoid first step WARNING
    nmFR            = ['FiringRate_Trial' num2str(iTrial) par.imnm];
    hfg.(nmFR)      = figure('Visible',ifplot); 
    tile            = tiledlayout(1,1); % One plot
    ax              = nexttile;
    box on; grid on; hold(ax, 'on');%hold on; 
    lw              = 2; % linewidth
    if par.smooth
        pmssmooth       = par.smooth;%8;
        [nCells,nTimes] = size(firingRates);
        newP            = zeros(nCells,nTimes);
        noise           = rand(1,size(firingRates,2))*par.noise;

        for iNeuron=1:nCells
            jitter      = par.jitter*randn(size(firingRates(iNeuron,:)));
            offset      = par.offset*iNeuron*ones(size(firingRates(iNeuron,:)));
            if par.asim==1; if iNeuron  == 1 || iNeuron == 7; offset(18:36)= 0.45*iNeuron*offset(18:36); end; end;
            if par.asim==2; if iNeuron  == 2 || iNeuron == 8; offset(18:36)= 0.45*iNeuron*offset(18:36); end; end;

            % c = 0*0.02; % left right
            % xJitter     = jitterAmplitude * (2*rand(size(timePotentials)) - 1); % uniform [-amp, +amp]
            newP(iNeuron,:)  = smooth(firingRates(iNeuron,:)+jitter+offset+noise,pmssmooth);    
        end
        firingRates      = newP;
    end
    % for iC=1:nCells
    %     interp1(timePotentials,firingRates(iC,:),timePotentials);
    % end
    nNeurons        = size(firingRates,1);
    actionIds       = mod(0:nNeurons-1,nActions)+1;
    epochIds        = floor((0:nNeurons-1)/nActions) + reset;
    if isfield(par, 'firingRateAppendEpochIndex') && par.firingRateAppendEpochIndex
        labneurons = arrayfun(@(idx) sprintf('%s(%d)', actions{actionIds(idx)}, epochIds(idx)), ...
            1:nNeurons, 'UniformOutput', false)';
    else
        labneurons = actions(actionIds)';
    end
    % Define color map depending on time epoch
    try
        cmaps=par.cmaps;
    catch
        cmaps           = lines(nEpochs);           % nEpochs distinct colors, one per subset
    % cmaps           = cmaps(end:-1:1,:);
    % 1) Blue % 2) red % 3) orange % 4) purple % 5) green % 6) light blue % 7) brown % 8) Blue % 9) red
        cmaps([6:8,2:4],:)= cmaps([2:4,6:8],:);
    end
    % parameters for fading colors for low rate neurons
    final_vals = firingRates(:, end);
    valueRange = max(final_vals) - min(final_vals);
    if valueRange > 0
        norm_vals = (final_vals - min(final_vals)) / valueRange; % 0 (low) to 1 (high)
    else
        norm_vals = ones(size(final_vals));
    end
    %                   U1  U2  U3  U4  U5  U6  U7 
    markers         = {'o','s','d','^','v','p','x','+'};  % Cross, Square, Diamond, Triangle-Up, Triangle-Down, Plus, Circle
    
    % alternatives: 
    line_styles = {'-','--',':','-.','-o','-','--',':','-.','-o','-','--',':','-.','-o'}; 
    % letters     = {'U','D','L','R','S'};    letter      = letters{actionId};
        
    pl              = gobjects(nNeurons,1); % used for legend
    pl2             = gobjects(nNeurons,1); % plot lines
    pl3             = gobjects(nNeurons,1); % plot markers
    for iNeuron=1:nNeurons
        % noise       = rand(1,size(firingRates,2))*0.04*0;
        epochColorId = ceil(iNeuron / nActions); % one color per temporal block
        actionId    = actionIds(iNeuron);  % [1-nActions]
        % marker depends on the action
        markerId    = mod(actionId - 1, numel(markers)) + 1;
        lineStyleId = mod(actionId - 1, numel(line_styles)) + 1;
        marker      = markers{markerId};
        line_style  = line_styles{lineStyleId};
        % Adjust color brightness based on final firing rate when requested.
        if isfield(par, 'firingRateUseBrightnessScaling') && ~par.firingRateUseBrightnessScaling
            brightness = 1;
        else
            brightness  = 0.3 + 0.7 * norm_vals(iNeuron); % ensures visible minimum brightness
        end
        if isfield(par, 'firingRateColorMode') && strcmpi(par.firingRateColorMode, 'action')
            colorIndex = min(actionId, size(cmaps, 1));
        else
            colorIndex = min(epochColorId, size(cmaps, 1));
        end
        colorBase   = cmaps(colorIndex, :);
        color       = colorBase * brightness + [1 1 1] * (1 - brightness);
        % firstly plot lines
        iTimes      = round(linspace(1,length(timePotentials),nPoints));
        % jitter      = 0.003 * randn(size(firingRates(iNeuron,:)));
        % offset      =  0.0025*iNeuron*ones(size(firingRates(iNeuron,:)));
        % if iNeuron == 1 || iNeuron == 7; offset(18:36)= 0.45*iNeuron*offset(18:36); end
        jitterAmplitude = par.jitterAmplitude; %0*0.02; % left right
        xJitter         = jitterAmplitude * (2*rand(size(timePotentials)) - 1); % uniform [-amp, +amp]
        
        % pl2(iNeuron) = plot(timePotentials+xJitter,firingRates(iNeuron,:)+offset+jitter+noise,line_style,'linewidth',lw,'Color', color); hold on;
        pl2(iNeuron) = plot(timePotentials+xJitter,firingRates(iNeuron,:),line_style,'linewidth',lw,'Color', color); hold on;
        
        % legend 
        % pl(iNeuron) = plot(timePotentials(iTimes(2:3))+xJitter(iTimes(2:3)),firingRates(iNeuron,iTimes(2:3))+offset(iTimes(2:3))+jitter(iTimes(2:3))+noise(iTimes(2:3)),...
        pl(iNeuron) = plot(timePotentials(iTimes(2:3))+xJitter(iTimes(2:3)),firingRates(iNeuron,iTimes(2:3)),...
                           'LineWidth', lw, 'color', color, 'linestyle','none',...
                           'Marker', marker, 'MarkerSize',10,'MarkerFaceColor', color, 'MarkerEdgeColor','k');
        % lastly plot markers
        % pl3(iNeuron) = plot(timePotentials(iTimes)+xJitter(iTimes),firingRates(iNeuron,iTimes)+offset(iTimes)+jitter(iTimes)+noise(iTimes), ...
        pl3(iNeuron) = plot(timePotentials(iTimes)+xJitter(iTimes),firingRates(iNeuron,iTimes), ...
                           'linestyle','none','Marker', marker, 'MarkerSize',10,'MarkerFaceColor', color, 'MarkerEdgeColor','k');
        
    end
    grid on, 
    % title(['Firing rates: ' [actions{MDP_Low.s(2,2:end)}]],'FontSize',24)
    xlabel('time [s]','FontSize',12)
    ylabel('response','FontSize',12)
    % toplot          = firingRates(:,end)>0.6;%0.6;
    toplot          = firingRates>par.thresh;%0.13;%0.6;
    toplot          = sum(toplot,2)>0;
    if isfield(par, 'firingRateKeepActions') && ~isempty(par.firingRateKeepActions)
        toplot = toplot & ismember(actions(actionIds)', par.firingRateKeepActions);
    end
    if isfield(par, 'firingRateKeepEpochIndices') && ~isempty(par.firingRateKeepEpochIndices)
        toplot = toplot & ismember(epochIds', par.firingRateKeepEpochIndices);
    end
    % toplot          = toplot' + strcmp(labneurons,'A(7)');
    % toplot          = toplot  + strcmp(labneurons,'A(8)');
    % toplot          = logical(toplot);
    legendHandles   = pl(toplot);
    legendLabels    = labneurons(toplot);
    if isfield(par, 'firingRateLegendUnique') && par.firingRateLegendUnique
        [legendLabels, uniqueIndex] = unique(legendLabels, 'stable');
        legendHandles = legendHandles(uniqueIndex);
    end
    if ~isempty(legendHandles)
        hLegend = legend(legendHandles, legendLabels, 'location', 'eastoutside', 'AutoUpdate', 'off');
        if isfield(par, 'firingRateLegendFontSize') && ~isempty(par.firingRateLegendFontSize)
            hLegend.FontSize = par.firingRateLegendFontSize;
        end
    end
    delete(pl(~toplot));
    delete(pl3(~toplot));
    delete(pl2(~toplot));
    minY            = 0;
    maxY            = max(firingRates(:)); %1;
    dy              = 0.02;
    ylim([minY-dy,maxY+dy])
    dx              = 0.03;
    xlim([timePotentials(1)-dx,timePotentials(end)+dx])
    set(gca,'fontsize',16)
    p=[0,0,1000,600];
    set(hfg.(nmFR),'Position',p);
end
end

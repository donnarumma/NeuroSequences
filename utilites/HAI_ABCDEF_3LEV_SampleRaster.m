function   hfg=HAI_ABCDEF_3LEV_SampleRaster(hfg,data_trials,MDP,par)
% function hfg=HAI_ABCDEF_3LEV_SampleRaster(hfg,data_trials,MDP,par)
%% plot a sample raster (see spm_MDP_VB_LFP.m in spm12)
salpha      = 0.1;
nla         = 0.05;
trials      = par.trials;
iFactor     = par.iFactor;
% Nnr         = par.Nnr;
ifplot      = par.ifplot;
actions     = par.actions;
labEpochs   = [data_trials.labEpochs];
% nEpochs     = max(labEpochs); 
nBins       = sum(labEpochs==1);
try
    par.imnm;
catch
    par.imnm='';
end
Nnr         = size(data_trials(1).Spikes,1)/size(data_trials(1).popFR,1);   
try 
    nActions=par.nActions;
catch
    nActions    = length(MDP{1}.mdp(1).D{iFactor});
end
try
    reset = par.reset;
catch
    reset = 0;
end
nEpochs     = MDP{1}.mdp(1).T;
 
istotal     = nActions*nEpochs*Nnr;
if istotal ~= size(data_trials(1).Spikes,1) && par.reduce
    isreduced = true; % accounts if we want not to show first and last step
else
    isreduced = false;
end
try 
    stepcmaps=par.cmaps;
catch
    stepcmaps               = lines(nEpochs);
    % stepcmaps       = stepcmaps(end:-1:1,:);
    if size(stepcmaps, 1) >= 8
        stepcmaps([6:8,2:4],:)  = stepcmaps([2:4,6:8],:);
    end
end

% 1) Blue
% 2) red
% 3) orange
% 4) violet
% 5) green
% 6) light blue
% 7) brown
% 8) blue
% 9) red


if isreduced
    nEpochs  = nEpochs-2;
    nActions = nActions-1;
    stepcmaps= lines(nEpochs);
end
    
% DICTIONARY  = DICTIONARY_ABCDEF_3LEV();
for iTrial=trials
    % MDP_Low     = MDP{iTrial}.mdp;
    Xtime       = data_trials(iTrial).timeSpikes;
    Spval       = ~data_trials(iTrial).Spikes; % invert to have an image of black for spikes and white non spikes
    nPops       = size(Spval,1)/Nnr; 
    YNlab       = 1:nPops*Nnr;       % nPopos=nSLev2*nEpochs
    imnm        = ['RasterTrial' num2str(iTrial) par.imnm];
    hfg.(imnm)  = figure('visible',ifplot); 
    hold on; imagesc(Xtime,YNlab,Spval); colormap gray; 
    % %%%%%%%%
    trialName   = data_trials(iTrial).trialName;
    title(['Unit firing ' trialName],'FontSize',16)
    % title(['Unit firing ' [actions{MDP_Low.s(2,:)}]],'FontSize',16)
    xlabel('time [s]','FontSize',12)
    grid on, 
    ylabel(sprintf('Population Coding')); %% DONNARUMMA
    
    % set all lines, one per each group nPop of Nnr cells encoding nSLev2*nEpochs states
    allyticks   = YNlab((1:Nnr:end))+(Nnr-1)/2; % set one tick per Nnr (centered)
    grid on, set(gca,'YTick',allyticks)  % set y ticks for each neuron
    HN          = yline(allyticks);
    set(HN,'alpha',nla);
    
    % set delimiter of epoch-encoding
    tlines          = (0:nActions*Nnr:nEpochs*nActions*Nnr) + 0.5; % first neuron at 1
    ylines          = (0:nActions*nBins:nEpochs*nActions*nBins) + 0.5; % first neuron at 1
    
    set(gca,'Ydir','reverse');
    ylim([YNlab(1)-1/(2),YNlab(end)+1/(2)]);
    
    p           = [0,0,1500,1200];
    fs          = 16;
    set(gca,'fontsize',fs);
    set(hfg.(imnm), 'PaperPositionMode','auto');
    set(hfg.(imnm),'Position',p);
    % %%%%% FILL STEP LINES %%%%%%
    istart      = ylines(1);
    try
        nLegends = par.nEpochs;
    catch
        nLegends    = nEpochs;
    end
    Hide        = gobjects(nLegends,1);
    HdL         = cell(nLegends,1);
    
    Spvls       = data_trials(iTrial).Spikes;
    for iy = 1:nLegends
        iend    = tlines(iy+1);
        Hide(iy)= fill([Xtime(1),Xtime(1),Xtime(end),Xtime(end)],[istart,iend,iend,istart],stepcmaps(iy,:));
        % %
        wdwNeu  = ceil(istart:iend-1);
        for iNeuron = 1:length(wdwNeu)
            neuSpkTimes = Xtime(logical( Spvls(wdwNeu(iNeuron),:) ) );
            for iTime=1:length(neuSpkTimes)
                plot([neuSpkTimes(iTime), neuSpkTimes(iTime)],    ...
                    [wdwNeu(iNeuron) - 0.4, wdwNeu(iNeuron) + 0.4], ...
                    'Color', stepcmaps(iy,:), 'LineWidth', 1.5);
            end
        end
        % %
        istart  = iend;
        set(Hide(iy),'facealpha',salpha)
        HdL{iy} =['Step: ' num2str(iy-(~isreduced))];
    end
    
    nActionsRep = nEpochs*nActions;    
    yticks((0.5+(Nnr/2)):Nnr:nActionsRep*Nnr);   
    labneurons  = actions(mod(0:nActionsRep-1,nActions)+1);
  
    icounter=0;
    for iTime =1:nEpochs
        for iAction=1:nActions
            icounter=icounter+1;
            labneurons{icounter}=[labneurons{icounter} '(' num2str(iTime+reset) ')'];
        end
    end
    
    yticklabels(labneurons)
    nLabels     = length(labneurons);

    legend(Hide,HdL,'location','southwest')
    set(gca,'fontsize',14);
    
    xlim([floor(Xtime(1)),Xtime(end)]);
    ylim([0,nLabels]*(Nnr)+0.5);

    p   =[0,0,800,1000];
    fs  =16;
    set(gca,'fontsize',fs);
    set(hfg.(imnm), 'PaperPositionMode','auto');
    set(hfg.(imnm), 'Position',p);
end

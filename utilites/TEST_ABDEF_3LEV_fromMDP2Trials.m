function   data_trials = TEST_ABDEF_3LEV_fromMDP2Trials(par,MDP)
% function data_trials = TEST_ABDEF_3LEV_fromMDP2Trials(par,MDP)

data_trials =struct();
actions     =par.actions;
iFactor     =par.iFactor;
dt          =par.dt;
Nnr         =par.Nnr;
cap         =par.cap;
th          =par.th;
SpT         =par.SpT;
reduce      =par.reduce;
MDP         =MDP(:);
for iTrial=1:length(MDP)
    MDP_Low                         = MDP{iTrial}.mdp; % select low level
    Nev                             = ones(1,MDP_Low.T);
    % extract firing rates of the population (state updates)
    [popFR,tPopFR,labEpochs]              = HAI_MDPtoFiringRates(MDP_Low,iFactor,dt);

    % nPops                                 = size(popFR,1);
    nBins                                 = sum(labEpochs==1);
    % nEpochs                               = max(labEpochs);          

    % do not include neurons encoding t1 and t5xX
    if reduce
        nActions                              = length(MDP{1}.mdp(1).D{par.iFactor});
        nNeurons                              = size(popFR,1);
        popFR                                 = popFR((nActions+1):(nNeurons-nActions),:);
        
        % do not include "Stay" neurons (encoded on last action)
        popFR(nActions:nActions:end,:)          = [];
    end
    try
        popFR(~par.goods,:)=[];
    end
    % extend to Nnr neurons and Nev new bins 
    [FR,tFR,extLabEpochs]                 = HAI_extendFiringRates(popFR,nBins,Nnr,Nev,dt);
   
    % construct data_trial
    SpikesM                               = HAI_fireToSpikes(FR,cap,th,SpT);
    idxTrial                              = iTrial;
    data_trials(idxTrial).Spikes          = SpikesM;
    data_trials(idxTrial).timeSpikes      = tFR/tFR(end); % normalize in one second
    data_trials(idxTrial).popFR           = popFR;
    data_trials(idxTrial).tPopFR          = tPopFR/tPopFR(end);
    data_trials(idxTrial).firingRates     = FR;
    data_trials(idxTrial).timeFiringRates = tFR/tFR(end);
    data_trials(idxTrial).extLabEpochs    = extLabEpochs;
    data_trials(idxTrial).labEpochs       = labEpochs;
    data_trials(idxTrial).trialName       = [actions{MDP_Low.s(par.iFactor,2:end-1)}];
end

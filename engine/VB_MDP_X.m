function [MDP] = VB_MDP_X(MDP,OPTIONS)
fprintf('MDP %s entering %s\n',mfilename,MDP.Hname);
spm_MDP_VB_H=str2func(mfilename);
% active inference and learning using variational message passing
% FORMAT [MDP] = VB_MDP_X(MDP,OPTIONS)
%
% Input; MDP(m,n)       - structure array of m models over n epochs
%
% MDP.V(T - 1,P,F)      - P allowable policies (T - 1 moves) over F factors
% orV
% MDP.U(1,P,F)          - P allowable actions at each move
% MDP.T                 - number of outcomes
%
% MDP.A{G}(O,N1,...,NF) - likelihood of O outcomes given hidden states
% MDP.B{F}(NF,NF,MF)    - transitions among states under MF control states
% MDP.C{G}(O,T)         - (log) prior preferences for outcomes (modality G)
% MDP.D{F}(NF,1)        - prior probabilities over initial states
% MDP.E(P,1)            - prior probabilities over policies
%
% MDP.a{G}              - concentration parameters for A
% MDP.b{F}              - concentration parameters for B
% MDP.c{G}              - concentration parameters for C
% MDP.d{F}              - concentration parameters for D
% MDP.e                 - concentration parameters for E
%
% optional:
% MDP.s(F,T)            - matrix of true states - for each hidden factor
% MDP.o(G,T)            - matrix of outcomes    - for each outcome modality
% or .O{G}(O,T)         - likelihood matrix     - for each outcome modality
% MDP.u(F,T - 1)        - vector of actions     - for each hidden factor
%
% MDP.alpha             - precision - action selection [512]
% MDP.beta              - precision over precision (Gamma hyperprior - [1])
% MDP.chi               - Occams window for deep updates
% MDP.tau               - time constant for gradient descent [4]
% MDP.eta               - learning rate for model parameters
% MDP.zeta              - Occam's window for policies [3]
% MDP.erp               - resetting of initial states, to simulate ERPs [4]
%
% MDP.demi.C            - Mixed model: cell array of true causes (DEM.C)
% MDP.demi.U            - Bayesian model average (DEM.U) see: spm_MDP_DEM
% MDP.link              - link array to generate outcomes from
%                         subordinate MDP; for deep (hierarchical) models
%
% OPTIONS.plot          - switch to suppress graphics:  (default: [0])
% OPTIONS.gamma         - switch to suppress precision: (default: [0])
% OPTIONS.D             - switch to update initial states over epochs
% OPTIONS.BMR           - Bayesian model reduction for multiple trials
%                         see: spm_MDP_VB_sleep(MDP,BMR)
% Outputs:
%
% MDP.P(M1,...,MF,T)    - probability of emitting action M1,.. over time
% MDP.Q{F}(NF,T,P)      - expected hidden states under each policy
% MDP.X{F}(NF,T)        - and Bayesian model averages over policies
% MDP.R(P,T)            - response: conditional expectations over policies
%
% MDP.un          - simulated neuronal encoding of hidden states
% MDP.vn          - simulated neuronal prediction error
% MDP.xn          - simulated neuronal encoding of policies
% MDP.wn          - simulated neuronal encoding of precision (tonic)
% MDP.dn          - simulated dopamine responses (phasic)
% MDP.rt          - simulated reaction times
%
% MDP.F           - (P x T) (negative) free energies over time
% MDP.G           - (P x T) (negative) expected free energies over time
% MDP.H           - (1 x T) (negative) total free energy over time
% MDP.Fa          - (1 x 1) (negative) free energy of parameters (a)
% MDP.Fb          - ...
%
% This routine provides solutions of active inference (minimisation of
% variational free energy) using a generative model based upon a Markov
% decision process (or hidden Markov model, in the absence of action). The
% model and inference scheme is formulated in discrete space and time. This
% means that the generative model (and process) are  finite state machines
% or hidden Markov models whose dynamics are given by transition
% probabilities among states and the likelihood corresponds to a particular
% outcome conditioned upon hidden states.
%
% When supplied with outcomes, in terms of their likelihood (O) in the
% absence of any policy specification, this scheme will use variational
% message passing to optimise expectations about latent or hidden states
% (and likelihood (A) and prior (B) probabilities). In other words, it will
% invert a hidden Markov model. When  called with policies, it will
% generate outcomes that are used to infer optimal policies for active
% inference.
%
% This implementation equips agents with the prior beliefs that they will
% maximise expected free energy: expected free energy is the free energy of
% future outcomes under the posterior predictive distribution. This can be
% interpreted in several ways - most intuitively as minimising the KL
% divergence between predicted and preferred outcomes (specified as prior
% beliefs) - while simultaneously minimising ambiguity.
%
% This particular scheme is designed for any allowable policies or control
% sequences specified in MDP.V. Constraints on allowable policies can limit
% the numerics or combinatorics considerably. Further, the outcome space
% and hidden states can be defined in terms of factors; corresponding to
% sensory modalities and (functionally) segregated representations,
% respectively. This means, for each factor or subset of hidden states
% there are corresponding control states that determine the transition
% probabilities.
%
% This specification simplifies the generative model, allowing a fairly
% exhaustive model of potential outcomes. In brief, the agent encodes
% beliefs about hidden states in the past (and in the future) conditioned
% on each policy. The conditional expectations determine the (path
% integral) of free energy that then determines the prior over policies.
% This prior is used to create a predictive distribution over outcomes,
% which specifies the next action.
%
% In addition to state estimation and policy selection, the scheme also
% updates model parameters; including the state transition matrices,
% mapping to outcomes and the initial state. This is useful for learning
% the context. Likelihood and prior probabilities can be specified in terms
% of concentration parameters (of a Dirichlet distribution (a,b,c,..). If
% the corresponding (A,B,C,..) are supplied, they will be used to generate
% outcomes; unless called without policies (in hidden Markov model mode).
% In this case, the (A,B,C,..) are treated as posterior estimates.
%
% If supplied with a structure array, this routine will automatically step
% through the implicit sequence of epochs (implicit in the number of
% columns of the array). If the array has multiple rows, each row will be
% treated as a separate model or agent. This enables agents to communicate
% through acting upon a common set of hidden factors, or indeed sharing the
% same outcomes.
%
% See also: spm_MDP, which uses multiple future states and a mean field
% approximation for control states - but allows for different actions at
% all times (as in control problems).
%
% See also: spm_MDP_game_KL, which uses a very similar formulation but just
% maximises the KL divergence between the posterior predictive distribution
% over hidden states and those specified by preferences or prior beliefs.
%__________________________________________________________________________
% Copyright (C) 2005 Wellcome Trust Centre for Neuroimaging

% Karl Friston
% $Id: spm_MDP_VB_X.m 7766 2020-01-05 21:37:39Z karl $


% deal with a sequence of trials
%==========================================================================

% options
%--------------------------------------------------------------------------
try, OPTIONS.plot;  catch, OPTIONS.plot  = 0; end
try, OPTIONS.gamma; catch, OPTIONS.gamma = 0; end
try, OPTIONS.D;     catch, OPTIONS.D     = 0; end
try, MDP.alpha= OPTIONS.level(MDP.level).alpha; catch, MDP.alpha = 512;   end % action precision
try, MDP.beta = OPTIONS.level(MDP.level).beta;  catch, MDP.beta  = 1;     end % policy precision
try, MDP.tau  = OPTIONS.level(MDP.level).tau;   catch, MDP.tau   = 4;     end % update time constant
try, MDP.chi  = OPTIONS.level(MDP.level).chi;   catch, MDP.chi   = 1/64;  end % Occam window updates
try, MDP.erp;                                   catch, MDP.erp   = 4;     end % update reset
try, MDP.VBNi = OPTIONS.level(MDP.level).VBNi;  catch, MDP.VBNi  = 16;    end % number of VB iterations

% check MDP specification
%--------------------------------------------------------------------------
MDP = spm_MDP_check(MDP);

% handle multiple trials, ensuring parameters (and posteriors) are updated
%==========================================================================
if size(MDP,2) > 1
    
    % plotting options
    %----------------------------------------------------------------------
    GRAPH        = OPTIONS.plot;
    OPTIONS.plot = 0;
    
    for iModel = 1:size(MDP,2)             % number of MDPs
        for iTrial = 1:size(MDP,1)         % number of trials
            if iModel > 1                  % if previous inversions
                
                % update concentration parameters
                %----------------------------------------------------------
                MDP(iTrial,iModel)  = spm_MDP_update(MDP(iTrial,iModel),OUT(iTrial,iModel - 1));
                
                % update initial states (post-diction)
                %----------------------------------------------------------
                if any(OPTIONS.D)
                    nD = numel(MDP(iTrial,iModel).D);
                    if numel(OPTIONS.D) ~= nD
                        OPTIONS.D = ones(nD,1);
                    end
                    for iHfactor = 1:nD
                        if OPTIONS.D(iHfactor)
                            MDP(iTrial,iModel).D{iHfactor} = OUT(iTrial,iModel - 1).X{iHfactor}(:,1);
                        end
                    end
                end
            end
        end
        
        % solve this trial (for all models synchronously)
        %------------------------------------------------------------------
        OUT(:,iModel) = spm_MDP_VB_H(MDP(:,iModel),OPTIONS);
        
        % Bayesian model reduction
        %------------------------------------------------------------------
        if isfield(OPTIONS,'BMR')
            for iTrial = 1:size(MDP,1)
                OUT(iTrial,iModel) = spm_MDP_VB_sleep(OUT(iTrial,iModel),OPTIONS.BMR);
            end
        end
        
    end
    
    % plot summary statistics - over trials
    %----------------------------------------------------------------------
    MDP = OUT;
    if GRAPH
        if ishandle(GRAPH)
            figure(GRAPH); clf
        else
            spm_figure('GetWin','MDP'); clf
        end
        spm_MDP_VB_game(MDP(1,:))
    end
    return
end


% set up and preliminaries
%==========================================================================

% defaults
%--------------------------------------------------------------------------
try, alpha = MDP(1).alpha; catch, alpha = 512;  end % action precision
try, beta  = MDP(1).beta;  catch, beta  = 1;    end % policy precision
try, zeta  = MDP(1).zeta;  catch, zeta  = 3;    end % Occam window policies
try, eta   = MDP(1).eta;   catch, eta   = 1;    end % learning rate
try, tau   = MDP(1).tau;   catch, tau   = 4;    end % update time constant
try, chi   = MDP(1).chi;   catch, chi   = 1/64; end % Occam window updates
try, erp   = MDP(1).erp;   catch, erp   = 4;    end % update reset

% preclude precision updates for moving policies
%--------------------------------------------------------------------------
if isfield(MDP,'U'), OPTIONS.gamma = 1;         end


% number of updates T & policies V (hidden Markov model with no policies)
%--------------------------------------------------------------------------
[nTimes,Vpol,HMM] = spm_MDP_get_T(MDP);

% initialise model-specific variables
%==========================================================================
Ni    = 16;                                % number of VB iterations
for iTrial = 1:size(MDP,1)
    
    % ensure policy length is less than the number of updates
    %----------------------------------------------------------------------
    if size(Vpol{iTrial},1) > (nTimes - 1)
        Vpol{iTrial} = Vpol{iTrial}(1:(nTimes - 1),:,:);
    end
    
    % numbers of transitions, policies and states
    %----------------------------------------------------------------------
    Ng(iTrial) = numel(MDP(iTrial).A);               % number of outcome factors
    Nf(iTrial) = numel(MDP(iTrial).B);               % number of hidden state factors
    Np(iTrial) = size(Vpol{iTrial},2);               % number of allowable policies
    for iHfactor = 1:Nf(iTrial)
        Ns(iTrial,iHfactor) = size(MDP(iTrial).B{iHfactor},1);     % number of hidden states
        Nu(iTrial,iHfactor) = size(MDP(iTrial).B{iHfactor},3);     % number of hidden controls
    end
    for iOfactor = 1:Ng(iTrial)
        No(iTrial,iOfactor) = size(MDP(iTrial).A{iOfactor},1);     % number of outcomes
    end
    
    % parameters of generative model and policies
    %======================================================================
    
    % likelihood model (for a partially observed MDP)
    %----------------------------------------------------------------------
    for iOfactor = 1:Ng(iTrial)
        
        % ensure probabilities are normalised  : A
        %------------------------------------------------------------------
        MDP(iTrial).A{iOfactor} = spm_norm(MDP(iTrial).A{iOfactor});
        
        % parameters (concentration parameters): a
        %------------------------------------------------------------------
        if isfield(MDP,'a')
            A_lk{iTrial,iOfactor}  = spm_norm(MDP(iTrial).a{iOfactor});
        else
            A_lk{iTrial,iOfactor}  = spm_norm(MDP(iTrial).A{iOfactor});
        end
        
        % prior concentration paramters for complexity (and novelty)
        %------------------------------------------------------------------
        if isfield(MDP,'a')
            pA{iTrial,iOfactor} = MDP(iTrial).a{iOfactor};
            wA{iTrial,iOfactor} = spm_wnorm(MDP(iTrial).a{iOfactor}).*(pA{iTrial,iOfactor} > 0);
        end
        
    end
    
    % transition probabilities (priors)
    %----------------------------------------------------------------------
    for iHfactor = 1:Nf(iTrial)
        for iTimeHorizon = 1:Nu(iTrial,iHfactor)
            
            % controlable transition probabilities : B
            %--------------------------------------------------------------
            MDP(iTrial).B{iHfactor}(:,:,iTimeHorizon) = spm_norm(MDP(iTrial).B{iHfactor}(:,:,iTimeHorizon));
            
            % parameters (concentration parameters): b
            %--------------------------------------------------------------
            if isfield(MDP,'b') && ~HMM
                sB{iTrial,iHfactor}(:,:,iTimeHorizon) = spm_norm(MDP(iTrial).b{iHfactor}(:,:,iTimeHorizon) );
                rB{iTrial,iHfactor}(:,:,iTimeHorizon) = spm_norm(MDP(iTrial).b{iHfactor}(:,:,iTimeHorizon)');
            else
                sB{iTrial,iHfactor}(:,:,iTimeHorizon) = spm_norm(MDP(iTrial).B{iHfactor}(:,:,iTimeHorizon) );
                rB{iTrial,iHfactor}(:,:,iTimeHorizon) = spm_norm(MDP(iTrial).B{iHfactor}(:,:,iTimeHorizon)');
            end
            
        end
        
        % prior concentration paramters for complexity
        %------------------------------------------------------------------
        if isfield(MDP,'b')
            pB{iTrial,iHfactor} = MDP(iTrial).b{iHfactor};
        end
        
    end
    
    % priors over initial hidden states - concentration parameters
    %----------------------------------------------------------------------
    for iHfactor = 1:Nf(iTrial)
        if isfield(MDP,'d')
            D_prH{iTrial,iHfactor} = spm_norm(MDP(iTrial).d{iHfactor});
        elseif isfield(MDP,'D')
            D_prH{iTrial,iHfactor} = spm_norm(MDP(iTrial).D{iHfactor});
        else
            D_prH{iTrial,iHfactor} = spm_norm(ones(Ns(iTrial,iHfactor),1));
            MDP(iTrial).D{iHfactor} = D_prH{iTrial,iHfactor};
        end
        
        % prior concentration parameters for complexity
        %------------------------------------------------------------------
        if isfield(MDP,'d')
            pD{iTrial,iHfactor} = MDP(iTrial).d{iHfactor};
            wD{iTrial,iHfactor} = spm_wnorm(MDP(iTrial).d{iHfactor});
        end
    end
    
    % priors over policies - concentration parameters
    %----------------------------------------------------------------------
    if isfield(MDP,'e')
        E_prP{iTrial} = spm_norm(MDP(iTrial).e);
    elseif isfield(MDP,'E')
        E_prP{iTrial} = spm_norm(MDP(iTrial).E);
    else
        E_prP{iTrial} = spm_norm(ones(Np(iTrial),1));
    end
    qE{iTrial}    = spm_log(E_prP{iTrial});
    
    % prior concentration parameters for complexity
    %----------------------------------------------------------------------
    if isfield(MDP,'e')
        pE{iTrial} = MDP(iTrial).e;
    end
    
    % prior preferences (log probabilities) : C
    %----------------------------------------------------------------------
    for iOfactor = 1:Ng(iTrial)
        if isfield(MDP,'c')
            C_prefO{iTrial,iOfactor}  = spm_psi(MDP(iTrial).c{iOfactor} + 1/32);
            pC{iTrial,iOfactor} = MDP(iTrial).c{iOfactor};
        elseif isfield(MDP,'C')
            C_prefO{iTrial,iOfactor}  = MDP(iTrial).C{iOfactor};
        else
            C_prefO{iTrial,iOfactor}  = zeros(No(iTrial,iOfactor),1);
        end
        
        % assume time-invariant preferences, if unspecified
        %------------------------------------------------------------------
        if size(C_prefO{iTrial,iOfactor},2) == 1
            C_prefO{iTrial,iOfactor} = repmat(C_prefO{iTrial,iOfactor},1,nTimes);
            if isfield(MDP,'c')
                MDP(iTrial).c{iOfactor} = repmat(MDP(iTrial).c{iOfactor},1,nTimes);
                pC{iTrial,iOfactor}     = repmat(pC{iTrial,iOfactor},1,nTimes);
            end
        end
        C_prefO{iTrial,iOfactor} = spm_log(spm_softmax(C_prefO{iTrial,iOfactor}));
    end
    
    % initialise  posterior expectations of hidden states
    %----------------------------------------------------------------------
    for iHfactor = 1:Nf(iTrial)
        xneuPol{iTrial,iHfactor}= zeros(Ni,Ns(iTrial,iHfactor),1,1,Np(iTrial)) + 1/Ns(iTrial,iHfactor);
        vneuPol{iTrial,iHfactor}= zeros(Ni,Ns(iTrial,iHfactor),1,1,Np(iTrial));
        x_prob{iTrial,iHfactor} = zeros(Ns(iTrial,iHfactor),nTimes,Np(iTrial)) + 1/Ns(iTrial,iHfactor);
        X{iTrial,iHfactor}      = repmat(D_prH{iTrial,iHfactor},1,1);
        for iPol = 1:Np(iTrial)
            x_prob{iTrial,iHfactor}(:,1,iPol) = D_prH{iTrial,iHfactor};
        end
    end
    
    % initialise posteriors over polices and action
    %----------------------------------------------------------------------
    P{iTrial}       = zeros([Nu(iTrial,:),1]);
    un{iTrial}      = zeros(Np(iTrial),1);
    u_pos{iTrial}   = zeros(Np(iTrial),1);
    
    % if there is only one policy
    %----------------------------------------------------------------------
    if Np(iTrial) == 1
        u_pos{iTrial} = ones(Np(iTrial),nTimes);
    end
    
    % if states have not been specified set to 0
    %----------------------------------------------------------------------
    s{iTrial}  = zeros(Nf(iTrial),nTimes);
    try
        iSpecS              = find(MDP(iTrial).s);
        s{iTrial}(iSpecS)   = MDP(iTrial).s(iSpecS);
    end
    MDP(iTrial).s           = s{iTrial};
    
    % if outcomes have not been specified set to 0
    %----------------------------------------------------------------------
    obs{iTrial}             = zeros(Ng(iTrial),nTimes);
    try
        iSpecO              = find(MDP(iTrial).o);
        obs{iTrial}(iSpecO) = MDP(iTrial).o(iSpecO);
    end
    MDP(iTrial).o           = obs{iTrial};
    
    % (indices of) plausible (allowable) policies
    %----------------------------------------------------------------------
    pols{iTrial}  = 1:Np(iTrial);
    
    % expected rate parameter (precision of posterior over policies)
    %----------------------------------------------------------------------
    qb{iTrial}          = beta;                 % initialise rate parameters
    precision{iTrial}   = 1/qb{iTrial};         % posterior precision (policy)
    
end

% ensure any outcome generating agent is updated first
%--------------------------------------------------------------------------
[Models,MDP] = spm_MDP_get_M(MDP,nTimes,Ng);


% belief updating over successive time points
%==========================================================================
for iTime = 1:nTimes
    
   if OPTIONS.debugmode
        try 
            fprintf('Level%g,Time %g\n',MDP.level,iTime)
            % MDP.s(:,t)
            % HAI_retrieveLevel(OPTIONS.level(MDP.level).STATES{MDP.s(1,t)})
            if ismember(iTime,OPTIONS.tStop)
                pause;
            end
        catch
        end
    end

    % generate hidden states and outcomes for each agent or model
    %======================================================================
    for iTrial = Models(iTime,:)
        
        if ~HMM % not required for HMM
            
            % sample state, if not specified
            %--------------------------------------------------------------
            for iHfactor = 1:Nf(iTrial)
                
                % the next state is generated by action on external states
                %----------------------------------------------------------
                if MDP(iTrial).s(iHfactor,iTime) == 0
                    if iTime > 1
                        ps = MDP(iTrial).B{iHfactor}(:,MDP(iTrial).s(iHfactor,iTime - 1),MDP(iTrial).u(iHfactor,iTime - 1));
                    else
                        ps = spm_norm(MDP(iTrial).D{iHfactor});
                    end
                    MDP(iTrial).s(iHfactor,iTime) = find(rand < cumsum(ps),1);
                end
                
            end
            
            % posterior predictive density over hidden (external) states
            %--------------------------------------------------------------
            for iHfactor = 1:Nf(iTrial)
                
                % under selected action (xqq)
                %----------------------------------------------------------
                if iTime > 1
                    xqq{iTrial,iHfactor} = sB{iTrial,iHfactor}(:,:,MDP(iTrial).u(iHfactor,iTime - 1))*X{iTrial,iHfactor}(:,iTime - 1);
                else
                    xqq{iTrial,iHfactor} = X{iTrial,iHfactor}(:,iTime);
                end
                
                % Bayesian model average (xq)
                %----------------------------------------------------------
                xq{iTrial,iHfactor} = X{iTrial,iHfactor}(:,iTime);
                
            end
            
            % sample outcome, if not specified
            %--------------------------------------------------------------
            for iOfactor = 1:Ng(iTrial)
                
                % if outcome is not specified
                %----------------------------------------------------------
                if ~MDP(iTrial).o(iOfactor,iTime)
                    
                    % outcome is generated by model n
                    %------------------------------------------------------
                    if MDP(iTrial).n(iOfactor,iTime)

                        nModel = MDP(iTrial).n(iOfactor,iTime);
                        if nModel == iTrial
                            
                            % outcome that minimises free energy (i.e.,
                            % maximises accuracy)
                            %----------------------------------------------
                            VFE    = spm_dot(spm_log(A_lk{iTrial,iOfactor}),xqq(iTrial,:));
                            po            = spm_softmax(VFE*512);
                            MDP(iTrial).o(iOfactor,iTime) = find(rand < cumsum(po),1);
                            
                        else
                            
                            % outcome from model n
                            %----------------------------------------------
                            MDP(iTrial).o(iOfactor,iTime) = MDP(nModel).o(iOfactor,iTime);
                            
                        end
                        
                    else

                        % or sample from likelihood given hidden state
                        %--------------------------------------------------
                        ind           = num2cell(MDP(iTrial).s(:,iTime));
                        po            = MDP(iTrial).A{iOfactor}(:,ind{:});
                        MDP(iTrial).o(iOfactor,iTime) = find(rand < cumsum(po),1);
                        
                    end
                end
            end
            
        end % HMM
        
        % get probabilistic outcomes from samples or subordinate level
        %==================================================================
        
        % get outcome likelihood (O{m})
        %------------------------------------------------------------------
        for iOfactor = 1:Ng(iTrial)
            
            % specified as a likelihood or observation
            %--------------------------------------------------------------
            if HMM
                
                % specified as a likelihood(HMM)
                %----------------------------------------------------------
                O{iTrial}{iOfactor,iTime} = MDP(iTrial).O{iOfactor}(:,iTime);
                
            else
                
                % specified as the sampled outcome
                %----------------------------------------------------------
                O{iTrial}{iOfactor,iTime} = sparse(MDP(iTrial).o(iOfactor,iTime),1,1,No(iTrial,iOfactor),1);
            end
            
        end
               
        % or generate outcomes from a subordinate MDP
        %==================================================================
        if isfield(MDP,'link')
            
            % use previous inversions (if available) to reproduce outcomes
            %--------------------------------------------------------------
            try
                mdp = MDP(iTrial).mdp(iTime);
            catch
                try
                    mdp     = spm_MDP_update(MDP(iTrial).MDP(iTime),MDP(iTrial).mdp(iTime - 1));
                catch
                    try
                        mdp = spm_MDP_update(MDP(iTrial).MDP(1),MDP(iTrial).mdp(iTime - 1));
                    catch
                        mdp = MDP(iTrial).MDP(1);
                    end
                end
            end
            
            % priors over states (of subordinate level)
            %--------------------------------------------------------------
            mdp.factor = [];
            for iHfactor = 1:size(MDP(iTrial).link,1)
                for iOfactor = 1:size(MDP(iTrial).link,2)
                    if ~isempty(MDP(iTrial).link{iHfactor,iOfactor})
                        
                        % subordinate state has hierarchical constraints
                        %--------------------------------------------------
                        mdp.factor(end + 1) = iHfactor;
                                                
                        % empirical priors over initial states
                        %--------------------------------------------------
                        O{iTrial}{iOfactor,iTime} = spm_dot(A_lk{iTrial,iOfactor},xq(iTrial,:));
                        mdp.D{iHfactor}  = MDP(iTrial).link{iHfactor,iOfactor}*O{iTrial}{iOfactor,iTime};
                        
                        % outcomes (i.e., states) are generated by model n
                        %--------------------------------------------------
                        if MDP(iTrial).n(iOfactor,iTime)
                            nModel    = MDP(iTrial).n(iOfactor,iTime);
                            if iTrial == nModel
                                ps         = MDP(iTrial).link{iHfactor,iOfactor}(:,MDP(iTrial).o(iOfactor,iTime));
                                mdp.s(iHfactor,1) = find(ps);
                            else
                                mdp.s(iHfactor,1) = MDP(nModel).mdp(iTime).s(iHfactor,1);
                            end
                        end
                        
                        % hidden state for lower level is the outcome
                        %--------------------------------------------------
                        try
                            mdp.s(iHfactor,1) = mdp.s(iHfactor,1);
                        catch
                            ps         = MDP(iTrial).link{iHfactor,iOfactor}(:,MDP(iTrial).o(iOfactor,iTime));
                            mdp.s(iHfactor,1) = find(ps);
                        end

                    end
                end
            end
            
            
            % empirical prior preferences
            %--------------------------------------------------------------
            if isfield(MDP,'linkC')
                for iHfactor = 1:size(MDP(iTrial).linkC,1)
                    for iOfactor = 1:size(MDP(iTrial).linkC,2)
                        if ~isempty(MDP(iTrial).linkC{iHfactor,iOfactor})
                            O{iTrial}{iOfactor,iTime} = spm_dot(A_lk{iTrial,iOfactor},xq(iTrial,:));           
                            mdp.C{iHfactor}  = spm_log(MDP(iTrial).linkC{iHfactor,iOfactor}*O{iTrial}{iOfactor,iTime});
                        end
                    end
                end
            end
            
            % empirical priors over policies
            %--------------------------------------------------------------
            if isfield(MDP,'linkE')
                mdp.factorE = [];
                for iOfactor = 1:size(MDP(iTrial).linkE,2)
                    if ~isempty(MDP(iTrial).linkE{iOfactor})
                        O{iTrial}{iOfactor,iTime} = spm_dot(A_lk{iTrial,iOfactor},xq(iTrial,:));               
                        mdp.E     = MDP(iTrial).linkE{iOfactor}*O{iTrial}{iOfactor,iTime};
                    end
                end
            end
            
            
                        
            % infer hidden states at lower level (outcomes at this level)
            %==============================================================
            MDP(iTrial).mdp(iTime) = spm_MDP_VB_H(mdp,OPTIONS);
            

            % get inferred outcomes from subordinate MDP
            %==============================================================
            for iHfactor = 1:size(MDP(iTrial).link,1)
                for iOfactor = 1:size(MDP(iTrial).link,2)
                    if ~isempty(MDP(iTrial).link{iHfactor,iOfactor})
                        O{iTrial}{iOfactor,iTime} = MDP(iTrial).link{iHfactor,iOfactor}'*MDP(iTrial).mdp(iTime).X{iHfactor}(:,1);
                    end
                end
            end
            
            % if hierarchical preferences, these contribute to outcomes ...
            %--------------------------------------------------------------
            if isfield(MDP,'linkC')
                for iHfactor = 1:size(MDP(iTrial).linkC,1)
                    for iOfactor = 1:size(MDP(iTrial).linkC,2)
                        if ~isempty(MDP(iTrial).linkC{iHfactor,iOfactor})
                            indC      = sparse(MDP(iTrial).mdp(iTime).o(iHfactor,:)',1:length(MDP(iTrial).mdp(iTime).o(iHfactor,:)),ones(length(MDP(iTrial).mdp(iTime).o(iHfactor,:)),1),size(MDP(iTrial).mdp(iTime).C{iHfactor},1),size(MDP(iTrial).mdp(iTime).C{iHfactor},2));
                            O{iTrial}{iOfactor,iTime} = spm_softmax(spm_log(O{iTrial}{iOfactor,iTime}) + MDP(iTrial).linkC{iHfactor,iOfactor}'*sum((indC.*(MDP(iTrial).mdp(iTime).C{iHfactor})),2));
                        end
                    end
                end
            end
            
            % ... and the same for policies
            %--------------------------------------------------------------
            if isfield(MDP,'linkE')
                for iOfactor = 1:size(MDP(iTrial).linkE,2)
                    if ~isempty(MDP(iTrial).linkE{iOfactor})
                        O{iTrial}{iOfactor,iTime} = spm_softmax(spm_log(O{iTrial}{iOfactor,iTime}) + spm_log(MDP(iTrial).linkE{iOfactor}'*MDP(iTrial).mdp(iTime).R(:,end)));
                    end
                end
            end
            
            % Ensure DEM starts with final states from previous inversion
            %----------------------------------------------------------
            if isfield(MDP(iTrial).MDP,'demi')
                MDP(iTrial).MDP.DEM.G(1).x = MDP(iTrial).mdp(iTime).dem(end).pU.x{1}(:,end);
                MDP(iTrial).MDP.DEM.M(1).x = MDP(iTrial).mdp(iTime).dem(end).qU.x{1}(:,end);
            end
            
        end % end of hierarchical mode (link)
        
        
        % or generate outcome likelihoods from a variational filter
        %==================================================================
        if isfield(MDP,'demi')
            
            % use previous inversions (if available)
            %--------------------------------------------------------------
            try
                MDP(iTrial).dem(iTime) = spm_ADEM_update(MDP(iTrial).dem(iTime - 1));
            catch
                MDP(iTrial).dem(iTime) = MDP(iTrial).DEM;
            end
            
            % get prior over outcomes
            %--------------------------------------------------------------
            for iOfactor = 1:Ng(iTrial)
                O{iTrial}{iOfactor,iTime} = spm_dot(A_lk{iTrial,iOfactor},xqq(iTrial,:));
            end
            
            % get posterior outcome from Bayesian filtering
            %--------------------------------------------------------------
            MDP(iTrial).dem(iTime) = spm_MDP_DEM(MDP(iTrial).dem(iTime),...
                MDP(iTrial).demi,O{iTrial}(:,iTime),MDP(iTrial).o(:,iTime));
            
            for iOfactor = 1:Ng(iTrial)
                O{iTrial}{iOfactor,iTime} = MDP(iTrial).dem(iTime).X{iOfactor}(:,end);
            end
            
        end % end outcomes from Bayesian filter
        
        
        % or generate outcome likelihoods from voice recognition
        %==================================================================
        if isfield(MDP,'VOX')
            
            % get predictive prior over outcomes if MDP.VOX = 2
            %--------------------------------------------------------------
            if MDP(iTrial).VOX == 2
                
                % current outcome
                %----------------------------------------------------------
                for iOfactor = 1:Ng(iTrial)
                    O{iTrial}{iOfactor,iTime} = spm_dot(A_lk{iTrial,iOfactor},xqq(iTrial,:));
                end
                
                % and next outcome if available
                %----------------------------------------------------------
                try
                    for iHfactor = 1:Nf(iTrial)
                        pq{iHfactor} = sB{iTrial,iHfactor}(:,:)*xqq{iTrial,iHfactor};
                    end
                    for iOfactor = 1:Ng(iTrial)
                        O{iTrial}{iOfactor,iTime + 1} = spm_dot(A_lk{iTrial,iOfactor},pq);
                    end
                end
            
            end
            
            % get likelihood over outcomes - or articulate phrase
            %--------------------------------------------------------------
            O{iTrial}  = spm_MDP_VB_VOX(MDP(iTrial),O{iTrial},iTime);
            
            % update outcomes
            %--------------------------------------------------------------
            for iOfactor = 1:Ng(iTrial)
                po            = spm_softmax(O{iTrial}{iOfactor,iTime}*512);
                MDP(iTrial).o(iOfactor,iTime) = find(rand < cumsum(po),1);
            end
            
        end % end outcomes from voice recognition
        
        
        
        
        % Likelihood of hidden states
        %==================================================================
        Likelihood{iTrial,iTime} = 1;
        for iOfactor = 1:Ng(iTrial)
            Likelihood{iTrial,iTime} = Likelihood{iTrial,iTime}.*spm_dot(A_lk{iTrial,iOfactor},O{iTrial}{iOfactor,iTime});
        end
        
        
        % Variational updates (skip to t = T in HMM mode)
        %==================================================================
        if ~HMM || nTimes == iTime
            
            % eliminate unlikely policies
            %--------------------------------------------------------------
            if ~isfield(MDP,'U') && iTime > 1
                VFE      = log(u_pos{iTrial}(pols{iTrial},iTime - 1));
                pols{iTrial}    = pols{iTrial}((VFE - max(VFE)) > -zeta);
            end
            
            % processing time and reset
            %--------------------------------------------------------------
            tstart = tic;
            for iHfactor = 1:Nf(iTrial)
                x_prob{iTrial,iHfactor} = spm_softmax(spm_log(x_prob{iTrial,iHfactor})/erp);
            end
            
            % Variational updates (hidden states) under sequential policies
            %==============================================================
            
            
            % variational message passing (VMP)
            %--------------------------------------------------------------
            TimeHorizon = size(Vpol{iTrial},1) + 1;   % horizon
            if isfield(MDP,'U')
                R = iTime;
            else
                R = TimeHorizon;
            end
            % VFE: Variational Free Energy
            VFE = zeros(Np(iTrial),1);
            for iPol = pols{iTrial}             % loop over plausible policies
                dF    = 1;                      % reset criterion for this policy
                for iVB = 1:Ni                  % iterate belief updates
                    VFE(iPol)  = 0;             % reset free energy for this policy
                    for iTimeHorizon = 1:TimeHorizon       % loop over future time points
                        
                        % current posterior over outcome factors
                        %--------------------------------------------------
                        if iTimeHorizon <= iTime
                            for iHfactor = 1:Nf(iTrial)
                                xq{iTrial,iHfactor} = full(x_prob{iTrial,iHfactor}(:,iTimeHorizon,iPol));
                            end
                        end
                        
                        for iHfactor = 1:Nf(iTrial)
                            
                            % hidden states for this time and policy
                            %----------------------------------------------
                            sx = full(x_prob{iTrial,iHfactor}(:,iTimeHorizon,iPol));
                            qL = zeros(Ns(iTrial,iHfactor),1);
                            v  = zeros(Ns(iTrial,iHfactor),1);
                            
                            % evaluate free energy and gradients (v = dFdx)
                            %----------------------------------------------
                            if dF > exp(-8) || iVB > 4
                                
                                % marginal likelihood over outcome factors
                                %------------------------------------------
                                if iTimeHorizon <= iTime
                                    qL = spm_dot(Likelihood{iTrial,iTimeHorizon},xq(iTrial,:),iHfactor);
                                    qL = spm_log(qL(:));
                                end
                                
                                % entropy
                                %------------------------------------------
                                qx  = spm_log(sx);
                                
                                % emprical priors (forward messages)
                                %------------------------------------------
                                if iTimeHorizon < 2
                                    px = spm_log(D_prH{iTrial,iHfactor});
                                    v  = v + px + qL - qx;
                                else
                                    px = spm_log(sB{iTrial,iHfactor}(:,:,Vpol{iTrial}(iTimeHorizon - 1,iPol,iHfactor))*x_prob{iTrial,iHfactor}(:,iTimeHorizon - 1,iPol));
                                    v  = v + px + qL - qx;
                                end
                                
                                % emprical priors (backward messages)
                                %------------------------------------------
                                if iTimeHorizon < R
                                    px = spm_log(rB{iTrial,iHfactor}(:,:,Vpol{iTrial}(iTimeHorizon    ,iPol,iHfactor))*x_prob{iTrial,iHfactor}(:,iTimeHorizon + 1,iPol));
                                    v  = v + px + qL - qx;
                                end
                                
                                % (negative) free energy
                                %------------------------------------------
                                if iTimeHorizon == 1 || iTimeHorizon == TimeHorizon
                                    VFE(iPol) = VFE(iPol) + sx'*0.5*v;
                                else
                                    VFE(iPol) = VFE(iPol) + sx'*(0.5*v - (Nf(iTrial)-1)*qL/Nf(iTrial));
                                end
                                
                                % update
                                %------------------------------------------
                                v    = v - mean(v);
                                sx   = spm_softmax(qx + v/tau);
                                
                            else
                                VFE(iPol) = PrevFreeEnergy(iPol);
                            end
                            
                            % store update neuronal activity
                            %----------------------------------------------
                            x_prob{iTrial,iHfactor}(:,iTimeHorizon,iPol)      = sx;
                            xq{iTrial,iHfactor}            = sx;
                            xneuPol{iTrial,iHfactor}(iVB,:,iTimeHorizon,iTime,iPol) = sx;
                            vneuPol{iTrial,iHfactor}(iVB,:,iTimeHorizon,iTime,iPol) = v;
                            
                        end
                    end
                    
                    % convergence
                    %------------------------------------------------------
                    if iVB > 1
                        dF = VFE(iPol) - PrevFreeEnergy(iPol);
                    end
                    PrevFreeEnergy = VFE;
                    
                end
            end
            
            % accumulate expected free energy of policies (Q)
            %==============================================================
            pu  = 1;                               % empirical prior
            qu  = 1;                               % posterior
            EFE = zeros(Np(iTrial),1);             % expected free energy
            if Np(iTrial) > 1
                for iPol = pols{iTrial}
                    
                    % Bayesian surprise about inital conditions
                    %------------------------------------------------------
                    if isfield(MDP,'d')
                        for iHfactor = 1:Nf(iTrial)
                            EFE(iPol) = EFE(iPol) - spm_dot(wD{iTrial,iHfactor},x_prob{iTrial,iHfactor}(:,1,iPol));
                        end
                    end
                    
                    for iTimeHorizon = iTime:TimeHorizon
                        
                        % get expected states for this policy and time
                        %--------------------------------------------------
                        for iHfactor = 1:Nf(iTrial)
                            xq{iTrial,iHfactor} = x_prob{iTrial,iHfactor}(:,iTimeHorizon,iPol);
                        end
                        
                        % (negative) expected free energy
                        %==================================================
                        
                        % Bayesian surprise about states
                        %--------------------------------------------------
                        EFE(iPol) = EFE(iPol) + spm_MDP_G(A_lk(iTrial,:),xq(iTrial,:));
                        
                        for iOfactor = 1:Ng(iTrial)
                            
                            % prior preferences about outcomes
                            %----------------------------------------------
                            qo   = spm_dot(A_lk{iTrial,iOfactor},xq(iTrial,:));
                            EFE(iPol) = EFE(iPol) + qo'*(C_prefO{iTrial,iOfactor}(:,iTimeHorizon));
                            
                            % Bayesian surprise about parameters
                            %----------------------------------------------
                            if isfield(MDP,'a')
                                EFE(iPol) = EFE(iPol) - spm_dot(wA{iTrial,iOfactor},{qo xq{iTrial,:}});
                            end
                        end
                    end
                end
                
                % variational updates - policies and precision
                %==========================================================
                
                % previous expected precision
                %----------------------------------------------------------
                if iTime > 1
                    precision{iTrial}(iTime) = precision{iTrial}(iTime - 1);
                end
                for iterVB = 1:Ni
                    
                    % posterior and prior beliefs about policies
                    %------------------------------------------------------
                    qu = spm_softmax(qE{iTrial}(pols{iTrial}) + precision{iTrial}(iTime)*EFE(pols{iTrial}) + VFE(pols{iTrial}));
                    pu = spm_softmax(qE{iTrial}(pols{iTrial}) + precision{iTrial}(iTime)*EFE(pols{iTrial}));
                    
                    % precision (w) with free energy gradients (v = -dF/dw)
                    %------------------------------------------------------
                    if OPTIONS.gamma
                        precision{iTrial}(iTime) = 1/beta;
                    else
                        eg      = (qu - pu)'*EFE(pols{iTrial});
                        dFdg    = qb{iTrial} - beta + eg;
                        qb{iTrial}   = qb{iTrial} - dFdg/2;
                        precision{iTrial}(iTime) = 1/qb{iTrial};
                    end
                    
                    % simulated dopamine responses (expected precision)
                    %------------------------------------------------------
                    nIterVB                                 = (iTime - 1)*Ni + iterVB;
                    wn{iTrial}(nIterVB,1)                   = precision{iTrial}(iTime);
                    un{iTrial}(pols{iTrial},nIterVB)        = qu;
                    u_pos{iTrial}(pols{iTrial},iTime)       = qu;
                    
                end               
            end % end of loop over multiple policies
            
            
            % Bayesian model averaging of hidden states (over policies)
            %--------------------------------------------------------------
            for iHfactor = 1:Nf(iTrial)
                for iTHorizon = 1:TimeHorizon
                    X{iTrial,iHfactor}(:,iTHorizon) = reshape(x_prob{iTrial,iHfactor}(:,iTHorizon,:),Ns(iTrial,iHfactor),Np(iTrial))*u_pos{iTrial}(:,iTime);
                end
            end
            MDP(iTrial).X                = X(iTrial,:);                 % added DONNARUMMA save X to print in debug
            MDP(iTrial).Psel{iTime}      = pols{iTrial};                % added DONNARUMMA save selected policies
            MDP(iTrial).qE               = qE{iTrial};                  % added DONNARUMMA prior on policies, warning: not needed to at each time step
            MDP(iTrial).precision(iTime) = precision{iTrial}(iTime);    % added DONNARUMMA save precision
           
            % processing (i.e., reaction) time
            %--------------------------------------------------------------
            rt{iTrial}(iTime)       = toc(tstart);
            
            % record (negative) free energies
            %--------------------------------------------------------------
            MDP(iTrial).F(:,iTime)  = VFE;
            MDP(iTrial).G(:,iTime)  = EFE;
            MDP(iTrial).H(1,iTime)  = qu'*MDP(iTrial).F(pols{iTrial},iTime) - qu'*(spm_log(qu) - spm_log(pu));
            
            % check for residual uncertainty (in hierarchical schemes)
            %--------------------------------------------------------------
            if isfield(MDP,'factor')
                
                for iHfactor = MDP(iTrial).factor(:)'
                    qx     = X{iTrial,iHfactor}(:,1);
                    H(iTrial,iHfactor) = qx'*spm_log(qx);
                end
                
                % break if there is no further uncertainty to resolve
                %----------------------------------------------------------
                if sum(H(:)) > - chi && ~isfield(MDP,'VOX')
                    nTimes = iTime;
                end
            end
            
            % check for end of sentence (' ') if in VOX mode
            %--------------------------------------------------------------
            XVOX = 0;
            if isfield(MDP,'VOX') && iTime > 1
                if strcmp(MDP.label.outcome{1}{MDP(iTrial).o(1,iTime)},' ')
                    for iHfactor = 1:Nf(iTrial)
                        Xneural{iTrial,iHfactor} = zeros(Ni,Ns(iTrial,iHfactor),nTimes,nTimes);
                        Vn{iTrial,iHfactor} = zeros(Ni,Ns(iTrial,iHfactor),nTimes,nTimes);
                    end
                    nTimes    = iTime;
                    XVOX = 1;
                end
            end
            
            % action selection
            %==============================================================
            if iTime < nTimes
                
                % marginal posterior over action (for each factor)
                %----------------------------------------------------------
                Pu              = zeros([Nu(iTrial,:),1]);
                for iPol = 1:Np(iTrial)
                    sub         = num2cell(Vpol{iTrial}(iTime,iPol,:));
                    Pu(sub{:})  = Pu(sub{:}) + u_pos{iTrial}(iPol,iTime);
                end
                
                % action selection (softmax function of action potential)
                %----------------------------------------------------------
                sub                         = repmat({':'},1,Nf(iTrial));
                Pu(:)                       = spm_softmax(alpha*log(Pu(:)));
                P{iTrial}(sub{:},iTime)     = Pu;
                
                % next action - sampled from marginal posterior
                %----------------------------------------------------------
                try
                    MDP(iTrial).u(:,iTime)  = MDP(iTrial).u(:,iTime);
                catch
                    try
                        ind                     = find(rand < cumsum(Pu(:)),1);
                        MDP(iTrial).u(:,iTime)  = spm_ind2sub(Nu(iTrial,:),ind);
                    catch
                        fprintf('WARNING!!\n');
                    end
                end
                
                % update policy and states for moving policies
                %----------------------------------------------------------
                if isfield(MDP,'U')
                    
                    for iHfactor = 1:Nf(iTrial)
                        Vpol{iTrial}(iTime,:,iHfactor) = MDP(iTrial).u(iHfactor,iTime);
                    end
                    for iTimeHorizon = 1:size(MDP(iTrial).U,1)
                        if (iTime + 1) < nTimes
                            Vpol{iTrial}(iTime + 1,:,:) = MDP(iTrial).U(:,:);
                        end
                    end
                    
                    % and re-initialise expectations about hidden states
                    %------------------------------------------------------
                    for iHfactor = 1:Nf(iTrial)
                        for iPol = 1:Np(iTrial)
                            x_prob{iTrial,iHfactor}(:,:,iPol) = 1/Ns(iTrial,iHfactor);
                        end
                    end
                end
                
            end % end of state and action selection
        end % end of variational updates over time
    end % end of loop over models (agents)
    
    
    % Evaluate reporting function specified
    %======================================================================
    if isfield(MDP,'FCN')
        try
            MDP.FCN(MDP,X);
        end
    end
    
    % terminate evidence accumulation
    %----------------------------------------------------------------------
    if iTime == nTimes
        if nTimes == 1
            MDP(iTrial).u  = zeros(Nf(iTrial),0);
        end
        if ~HMM
            MDP(iTrial).o  = MDP(iTrial).o(:,1:nTimes);        % outcomes at 1,...,T
            MDP(iTrial).s  = MDP(iTrial).s(:,1:nTimes);        % states   at 1,...,T
            MDP(iTrial).u  = MDP(iTrial).u(:,1:nTimes - 1);    % actions  at 1,...,T - 1
        end
        break;
    end

    if OPTIONS.debugmode
        fprintf('Loop in t\n');
        TRACE_printHierarchicalLevel(MDP,iTime);
        try
            fprintf('Pol VFE | ');
            % for iPol=1:Np
            values              = VFE(pols{iTrial});
            [sortedValues, idx] = sort(values, 'descend');
            sortedLabels        = MDP.PolLabels(idx);
            for iPol=1:length(values)
                fprintf('%g)%s=%.2f,',iPol,sortedLabels{iPol},sortedValues(iPol));
            end 
            fprintf('\n');
        catch
        end
        try
            fprintf('Pol EFE | ');
            values              = EFE(pols{iTrial});
            [sortedValues, idx] = sort(values, 'descend');
            sortedLabels        = MDP.PolLabels(idx);
            for iPol=1:length(values)
                fprintf('%g)%s=%.2f,',iPol,sortedLabels,sortedValues(iPol));
            end 
            fprintf('\n\n');
        catch
        end
        try
            % see action selection
            indpol = MDP(iTrial).u(1,iTime)==Vpol{iTrial}(iTime,:,1);
            fprintf('Current action(%g): %s\n',find(indpol),MDP(iTrial).PolLabels{indpol}); 
        catch
        end
    end
    
end % end of loop over time

% learning - accumulate concentration parameters
%==========================================================================
for iTrial = 1:size(MDP,1)
    
    for iTime = 1:nTimes
        
        % mapping from hidden states to outcomes: a
        %------------------------------------------------------------------
        if isfield(MDP,'a')
            for iOfactor = 1:Ng(iTrial)
                da     = O{iTrial}(iOfactor,iTime);
                for  iHfactor = 1:Nf(iTrial)
                    da = spm_cross(da,X{iTrial,iHfactor}(:,iTime));
                end
                da     = da.*(MDP(iTrial).a{iOfactor} > 0);
                MDP(iTrial).a{iOfactor} = MDP(iTrial).a{iOfactor} + da*eta;
            end
        end
        
        % mapping from hidden states to hidden states: b(u)
        %------------------------------------------------------------------
        if isfield(MDP,'b') && iTime > 1
            for iHfactor = 1:Nf(iTrial)
                for iPol = 1:Np(iTrial)
                    v   = Vpol{iTrial}(iTime - 1,iPol,iHfactor);
                    db  = u_pos{iTrial}(iPol,iTime)*x_prob{iTrial,iHfactor}(:,iTime,iPol)*x_prob{iTrial,iHfactor}(:,iTime - 1,iPol)';
                    db  = db.*(MDP(iTrial).b{iHfactor}(:,:,v) > 0);
                    MDP(iTrial).b{iHfactor}(:,:,v) = MDP(iTrial).b{iHfactor}(:,:,v) + db*eta;
                end
            end
        end
        
        % accumulation of prior preferences: (c)
        %------------------------------------------------------------------
        if isfield(MDP,'c')
            for iOfactor = 1:Ng(iTrial)
                dc = O{iTrial}(iOfactor,iTime);
                if size(MDP(iTrial).c{iOfactor},2) > 1
                    dc = dc.*(MDP(iTrial).c{iOfactor}(:,iTime) > 0);
                    MDP(iTrial).c{iOfactor}(:,iTime) = MDP(iTrial).c{iOfactor}(:,iTime) + dc*eta;
                else
                    dc = dc.*(MDP(iTrial).c{iOfactor}>0);
                    MDP(iTrial).c{iOfactor} = MDP(iTrial).c{iOfactor} + dc*eta;
                end
            end
        end
    end
    
    % initial hidden states:
    %----------------------------------------------------------------------
    if isfield(MDP,'d')
        for iHfactor = 1:Nf(iTrial)
            iModel = MDP(iTrial).d{iHfactor} > 0;
            MDP(iTrial).d{iHfactor}(iModel) = MDP(iTrial).d{iHfactor}(iModel) + X{iTrial,iHfactor}(iModel,1);
        end
    end
    
    % policies
    %----------------------------------------------------------------------
    if isfield(MDP,'e')
        MDP(iTrial).e = MDP(iTrial).e + eta*u_pos{iTrial}(:,nTimes);
    end
    
    % (negative) free energy of parameters (complexity): outcome specific
    %----------------------------------------------------------------------
    for iOfactor = 1:Ng(iTrial)
        if isfield(MDP,'a')
            MDP(iTrial).Fa(iOfactor) = - spm_KL_dir(MDP(iTrial).a{iOfactor},pA{iTrial,iOfactor});
        end
        if isfield(MDP,'c')
            MDP(iTrial).Fc(iHfactor) = - spm_KL_dir(MDP(iTrial).c{iOfactor},pC{iOfactor});
        end
    end
    
    % (negative) free energy of parameters: state specific
    %----------------------------------------------------------------------
    for iHfactor = 1:Nf(iTrial)
        if isfield(MDP,'b')
            MDP(iTrial).Fb(iHfactor) = - spm_KL_dir(MDP(iTrial).b{iHfactor},pB{iTrial,iHfactor});
        end
        if isfield(MDP,'d')
            MDP(iTrial).Fd(iHfactor) = - spm_KL_dir(MDP(iTrial).d{iHfactor},pD{iTrial,iHfactor});
        end
    end
    
    % (negative) free energy of parameters: policy specific
    %----------------------------------------------------------------------
    if isfield(MDP,'e')
        MDP(iTrial).Fe = - spm_KL_dir(MDP(iTrial).e,pE{iTrial});
    end
    
    % simulated dopamine (or cholinergic) responses
    %----------------------------------------------------------------------
    if Np(iTrial) > 1
        dn{iTrial} = 8*gradient(wn{iTrial}) + wn{iTrial}/8;
    else
        dn{iTrial} = [];
        wn{iTrial} = [];
    end
    
    % Bayesian model averaging of expected hidden states over policies
    %----------------------------------------------------------------------
    for iHfactor = 1:Nf(iTrial)
        if ~XVOX
            Xneural{iTrial,iHfactor}    = zeros(Ni,Ns(iTrial,iHfactor),nTimes,nTimes);
            Vn{iTrial,iHfactor}         = zeros(Ni,Ns(iTrial,iHfactor),nTimes,nTimes);
        end
        for iModel = 1:nTimes
            for iPol = 1:Np(iTrial)
                Xneural{iTrial,iHfactor}(:,:,1:nTimes,iModel)   = Xneural{iTrial,iHfactor}(:,:,1:nTimes,iModel) + xneuPol{iTrial,iHfactor}(:,:,1:nTimes,iModel,iPol)*u_pos{iTrial}(iPol,iModel);
                Vn{iTrial,iHfactor}(:,:,1:nTimes,iModel)        = Vn{iTrial,iHfactor}(:,:,1:nTimes,iModel) + vneuPol{iTrial,iHfactor}(:,:,1:nTimes,iModel,iPol)*u_pos{iTrial}(iPol,iModel);
            end
        end
    end
    
    % use penultimate beliefs about moving policies
    %----------------------------------------------------------------------
    if isfield(MDP,'U')
        u_pos{iTrial}(:,nTimes)  = [];
        try un{iTrial}(:,(end - Ni + 1):end) = []; catch, end
    end
    
    % assemble results and place in NDP structure
    %----------------------------------------------------------------------
    MDP(iTrial).T  = nTimes;            % number of belief updates
    MDP(iTrial).O  = O{iTrial};         % outcomes
    MDP(iTrial).P  = P{iTrial};         % probability of action at time 1,...,T - 1
    MDP(iTrial).R  = u_pos{iTrial};     % conditional expectations over policies
    MDP(iTrial).Q  = x_prob(iTrial,:);  % conditional expectations over N states
    MDP(iTrial).X  = X(iTrial,:);       % Bayesian model averages over T outcomes
    MDP(iTrial).C  = C_prefO(iTrial,:); % utility
    
    if HMM
        MDP(iTrial).o  = zeros(Ng(iTrial),0);      % outcomes at 1,...,T
        MDP(iTrial).s  = zeros(Nf(iTrial),0);      % states   at 1,...,T
        MDP(iTrial).u  = zeros(Nf(iTrial),0);      % actions  at 1,...,T - 1
        return
    end
    
    MDP(iTrial).w  = precision{iTrial}; % posterior expectations of precision (policy)
    MDP(iTrial).vn = Vn(iTrial,:);      % simulated neuronal prediction error
    MDP(iTrial).xn = Xneural(iTrial,:);      % simulated neuronal encoding of hidden states
    MDP(iTrial).un = un{iTrial};        % simulated neuronal encoding of policies
    MDP(iTrial).wn = wn{iTrial};        % simulated neuronal encoding of precision
    MDP(iTrial).dn = dn{iTrial};        % simulated dopamine responses (deconvolved)
    MDP(iTrial).rt = rt{iTrial};        % simulated reaction time (seconds)
    
end


% plot
%==========================================================================
if OPTIONS.plot
    if ishandle(OPTIONS.plot)
        figure(OPTIONS.plot); clf
    else
        spm_figure('GetWin','MDP'); clf
    end
    spm_MDP_VB_trial(MDP(1))
end

if OPTIONS.debugmode
    fprintf('BEFORE EXIT\n');
    TRACE_printHierarchicalLevel(MDP,iTime);
end
fprintf('MDP %s exiting %s\n',mfilename,MDP.Hname);


% auxillary functions
%==========================================================================

function A  = spm_log(A)
% log of numeric array plus a small constant
%--------------------------------------------------------------------------
A  = log(A + 1e-16);

function A  = spm_norm(A)
% normalisation of a probability transition matrix (columns)
%--------------------------------------------------------------------------
A           = bsxfun(@rdivide,A,sum(A,1));
A(isnan(A)) = 1/size(A,1);

function A  = spm_wnorm(A)
% summation of a probability transition matrix (columns)
%--------------------------------------------------------------------------
A   = A + 1e-16;
A   = bsxfun(@minus,1./sum(A,1),1./A)/2;

function sub = spm_ind2sub(siz,ndx)
% subscripts from linear index
%--------------------------------------------------------------------------
n = numel(siz);
k = [1 cumprod(siz(1:end-1))];
for i = n:-1:1,
    vi       = rem(ndx - 1,k(i)) + 1;
    vj       = (ndx - vi)/k(i) + 1;
    sub(i,1) = vj;
    ndx      = vi;
end

return


function [T,V,HMM] = spm_MDP_get_T(MDP)
% FORMAT [T,V,HMM] = spm_MDP_get_T(MDP)
% returns number of policies, policy cell array and HMM flag
% MDP(m) - structure array of m MPDs
% T      - number of trials or updates
% V(m)   - indices of policies for m-th MDP
% HMM    - flag indicating a hidden Markov model
%
% This subroutine returns the policy matrix as a cell array (for each
% model) and the maximum number of updates. If outcomes are specified
% probabilistically in the field MDP(m).O, and there is only one policy,
% the partially observed MDP reduces to a hidden Markov model.
%__________________________________________________________________________

for m = 1:size(MDP,1)
    
    % check for policies: hidden Markov model, with a single policy
    %----------------------------------------------------------------------
    if isfield(MDP(m),'U')
        HMM = size(MDP(m).U,1) < 2;
    elseif isfield(MDP(m),'V')
        HMM = size(MDP(m).V,2) < 2;
    else
        HMM = 1;
    end
    
    if isfield(MDP(m),'O') && ~any(MDP(m).o(:)) && HMM
        
        % probabilistic outcomes - assume hidden Markov model (HMM)
        %------------------------------------------------------------------
        T(m) = size(MDP(m).O{1},2);         % HMM mode
        V{m} = ones(T - 1,1);               % single 'policy'
        HMM  = 1;
        
    elseif isfield(MDP(m),'U')
        
        % called with repeatable actions (U,T)
        %------------------------------------------------------------------
        T(m) = MDP(m).T;                    % number of updates
        V{m}(1,:,:) = MDP(m).U;             % allowable actions (1,Np,Nf)
        HMM  = 0;
        
    elseif isfield(MDP(m),'V')
        
        % full sequential policies (V)
        %------------------------------------------------------------------
        V{m} = MDP(m).V;                    % allowable policies (T - 1,Np,Nf)
        T(m) = size(MDP(m).V,1) + 1;        % number of transitions
        HMM  = 0;
        
    else
        sprintf('Please specify MDP(%d).U, MDP(%d).V or MDP(%d).O',m), return
    end
    
end

% number of time steps
%--------------------------------------------------------------------------
T = max(T);

return


function [M,MDP] = spm_MDP_get_M(MDP,T,Ng)
% FORMAT [M,MDP] = spm_MDP_get_M(MDP,T,Ng)
% returns an update matrix for multiple models
% MDP(m) - structure array of m MPDs
% T      - number of trials or updates
% Ng(m)  - number of output modalities for m-th MDP
%
% M      - update matrix for multiple models
% MDP(m) - structure array of m MPDs
%
% In some applications, the outcomes are generated by a particular model
% (to maximise free energy, based upon the posterior predictive density).
% The generating model is specified in the matrix MDP(m).n, with a row for
% each outcome modality, such that each row lists the index of the model
% responsible for generating outcomes.
%__________________________________________________________________________

% check for VOX and ensure the agent generates outcomes when speaking
%--------------------------------------------------------------------------
if numel(MDP) == 1
    if isfield(MDP,'MDP')
        if isfield(MDP.MDP,'VOX')
            MDP.n = [MDP.MDP.VOX] == 1;
        end
    end
end
    
for m = 1:size(MDP,1)
    
    % check size of outcome generating agent, as specified by MDP(m).n
    %----------------------------------------------------------------------
    if ~isfield(MDP(m),'n')
        MDP(m).n = zeros(Ng(m),T);
    end
    if size(MDP(m).n,1) < Ng(m)
        MDP(m).n = repmat(MDP(m).n(1,:),Ng(m),1);
    end
    if size(MDP(m).n,1) < T
        MDP(m).n = repmat(MDP(m).n(:,1),1,T);
    end
    
    % mode of generating model (most frequent over outcome modalities)
    %----------------------------------------------------------------------
    n(m,:) = mode(MDP(m).n.*(MDP(m).n > 0),1);
    
end

% reorder list of model indices for each update
%--------------------------------------------------------------------------
n     = mode(n,1);
for t = 1:T
    if n(t) > 0
        M(t,:) = circshift((1:size(MDP,1)),[0 (1 - n(t))]);
    else
        M(t,:) = 1;
    end
end


return

function MDP = spm_MDP_update(MDP,OUT)
% FORMAT MDP = spm_MDP_update(MDP,OUT)
% moves Dirichlet parameters from OUT to MDP
% MDP - structure array (new)
% OUT - structure array (old)
%__________________________________________________________________________

% check for concentration parameters at this level
%--------------------------------------------------------------------------
try,  MDP.a = OUT.a; end
try,  MDP.b = OUT.b; end
try,  MDP.c = OUT.c; end
try,  MDP.d = OUT.d; end
try,  MDP.e = OUT.e; end

% check for concentration parameters at nested levels
%--------------------------------------------------------------------------
try,  MDP.MDP(1).a = OUT.mdp(end).a; end
try,  MDP.MDP(1).b = OUT.mdp(end).b; end
try,  MDP.MDP(1).c = OUT.mdp(end).c; end
try,  MDP.MDP(1).d = OUT.mdp(end).d; end
try,  MDP.MDP(1).e = OUT.mdp(end).e; end

return


function L = spm_MDP_VB_VOX(MDP,L,t)
% FORMAT L = spm_MDP_VB_VOX(MDP,L,t)
% returns likelihoods from voice recognition (and articulates responses)
% MDP - structure array
% L   - predictive prior over outcomes
% t   - current trial
%
% L   - likelihood of lexical and prosody outcomes
%
% this subroutine determines who is currently generating auditory output
% and produces synthetic speech - or uses the current audio recorder object
% to evaluate the likelihood of the next word
%__________________________________________________________________________


% check for VOX structure
%--------------------------------------------------------------------------
global VOX
global TRAIN
if ~isstruct(VOX), load VOX; VOX.RAND = 0; end
if isempty(TRAIN), TRAIN = 0;              end
if t == 1,         pause(1);               end


if ~isfield(VOX,'msg')
    
    % prepare useful fields in (global) VOX structure
    %----------------------------------------------------------------------
    Data    = imread('recording','png');
    VOX.msg = msgbox('Recording','','custom',Data);
    set(VOX.msg,'Visible','off'), drawnow
    
    % indices of words in lexicon and inferred prosody states
    %----------------------------------------------------------------------
    VOX.io  = spm_voice_i(MDP.label.outcome{1});
    VOX.ip  = find(ismember({VOX.PRO.str},{'amp','dur','Tf','p0','p1','p2'}));
    
    % check for audio recorder
    %----------------------------------------------------------------------
    if ~isfield(VOX,'audio')
        VOX.audio  = audiorecorder(22050,16,1);
    end
    
end

if MDP.VOX == 0 || MDP.VOX == 1
    
    % Agent: computer
    %----------------------------------------------------------------------
    str = MDP.label.outcome{1}(MDP.o(1,1:t));
    fprintf('%i: %s\n',MDP.VOX, str{t});
    i   = ismember(str,' ');
    str = str(~i);
    eof = sum(i);
    
    % if this is the end of a sentence
    %----------------------------------------------------------------------
    if eof == 1 || (~eof && t == MDP.T)
        
        % get lexical and prosody
        %------------------------------------------------------------------
        lexical = spm_voice_i(str);
        prosody = VOX.prosody(:,lexical);
        if MDP.VOX == 0
            speaker = [12;12];
        else
            speaker = [3; 3 ];
        end
        
        % add prosody and articulate
        %------------------------------------------------------------------
        prosody(VOX.ip,:) = MDP.o(2:end,1:numel(str));
        prosody(1,:)      = min(8,prosody(1,:) + 2);
        spm_voice_speak(lexical,prosody,speaker);
        
        
        % TRAIN: prompt for prosody
        %------------------------------------------------------------------
        if TRAIN
            VOX.mute  = 0;
            VOX.depth = 1;
            [i,P]     = spm_voice_i(str);
            prosody   = [];
            while size(prosody,2) ~= numel(str)
                clc
                disp('Please repeat:'), disp(str)
                [SEG,W,prosody] = spm_voice_read(VOX.audio,P);
            end
            clc, disp('Thank you')
            
            % prompt for prosody
            %--------------------------------------------------------------
            for i = 1:numel(VOX.ip)
                for j = 1:size(P,2)
                    L{i + 1,j} = sparse(prosody(VOX.ip(i),j),1,1,8,1);
                end
            end
            
            % uniform priors for spce  (' ')
            %--------------------------------------------------------------
            L{i + 1,t} = ones(8,1)/8;
            
        end
        
        
    end

    
elseif MDP.VOX == 2
    
    % user
    %----------------------------------------------------------------------
    if t == 1
        VOX.IT = 1;
        stop(VOX.audio)
        record(VOX.audio,8);
        set(VOX.msg,'Visible','on')
        pause(1);
        set(VOX.msg,'Visible','off')
        
        % toggle to see spectral envelope
        %----------------------------------------------------------------------
        VOX.onsets = 0;
        
    end
    
    % get prior over outcomes and synchronise with Lexicon
    %----------------------------------------------------------------------
    io  = VOX.io;                            % indices words in lexicon
    ip  = VOX.ip;                            % indices of prosody
    no  = numel(io);                         % number of outcomes
    nw  = numel(VOX.LEX);                    % number of words in lexicon
    nk  = size(L,2) - t + 1;                 % number of predictions
    P   = zeros(nw,nk);                      % prior over lexicon
    for k = 1:nk
        for i = 1:no
            j = io(i);
            if j
                P(j,k) = L{1,t + k - 1}(i);
            end
        end
    end
      
    % deep segmentation: check for last word (P(:,2) = 0)
    %----------------------------------------------------------------------
    VOX.LL = -128;
    VOX.LW = 0;
    if size(P,2) > 1
        if any(P(:,2))
            if any(P(:,2) < (1 - 1/8))
                VOX.LL = 4;                  % there may be no next word
                VOX.LW = 0;
            else
                VOX.LL = -128;               % there is a subsequent word
                VOX.LW = 0;                  % and this is not the last
            end
        else
            P      = P(:,1);
            VOX.LW = 1;                      % this is the last word
        end
    end
    
    % or direct segmentation (comment out to suppress)
    %----------------------------------------------------------------------
    P  = P(:,1);
    
    % get likelihood of discernible words
    %----------------------------------------------------------------------
    P      = P > 1/128;
    if any(P(:,1))
        
        % log likelihoods
        %------------------------------------------------------------------
        O  = spm_voice_get_word(VOX.audio,bsxfun(@rdivide,P,sum(P)));
        
        % check for end of sentence 
        %------------------------------------------------------------------
        try
            A = spm_softmax(O{2}(:,1));    % P(lowest amplitude)
        catch
            A = 1;
        end
        if isempty(O) || A(1) > 1/2
            
            % end of sentence or indiscernible word
            %--------------------------------------------------------------
            L{1,t}( ~io) = 1;
            L{1,t}(~~io) = 0;
            L{1,t}       = L{1,t}/sum(L{1,t});
            
            % prosody likelihoods
            %--------------------------------------------------------------
            for g = 2:numel(L)
                L{g,t} = spm_softmax(spm_zeros(L{g,t}));
            end
            
        else
            
            % lexical likelihoods
            %--------------------------------------------------------------
            LL    = zeros(no,1);
            for i = 1:no
                j = io(i);
                if j
                    LL(i) = O{1}(j);
                end
            end
            L{1,t}  = spm_softmax(LL);
                        
            % prosody likelihoods
            %--------------------------------------------------------------
            for g = 2:numel(L)
                L{g,t} = spm_softmax(O{2}(:,ip(g - 1)));
            end

        end

    end % discernible words
    
    % display word
    %----------------------------------------------------------------------
    [d,w]  = max(L{1,t});
    fprintf('%i: %s\n',MDP.VOX, MDP.label.outcome{1}{w});
        

end

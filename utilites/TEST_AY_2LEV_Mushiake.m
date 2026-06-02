function   MDP=TEST_AY_2LEV_Mushiake(par)
% function MDP=TEST_AY_2LEV_Mushiake(par)
% par
%
% lowest level 1, higher level 2
% 13 -> time of execution T2 = 1, T1 = 3 
idsentence  = par.idsentence;
goal_state  = par.goal_state;
isfix       = par.isfix;
irng        = par.irng;
iMushiake   = par.iMushiake;
addSingleStepRecognitionLevel = true;
singleStepRecognitionMode = 'diagonal';

if isfield(par, 'addSingleStepRecognitionLevel') && ~isempty(par.addSingleStepRecognitionLevel)
    addSingleStepRecognitionLevel = par.addSingleStepRecognitionLevel;
end

if isfield(par, 'singleStepRecognitionMode') && ~isempty(par.singleStepRecognitionMode)
    singleStepRecognitionMode = par.singleStepRecognitionMode;
end

dictionary                          = 'DICTIONARY_AY_2LEV_Mushiake';
langparams                          = HAI_DefaultParams(dictionary);
langparams.level(1).maxT            = 5;
langparams.level(1).SaccadesLocation= false;
TestMaze                            = MAZE_Mushiake(iMushiake);
plan2D{1}                           = TestMaze.StatesB;
plan2D{2}                           = TestMaze.ActionsB;
langparams.level(1).plan2D          = plan2D;
langparams.level(1).Ht              = 0;

defaultRunner = str2func('spm_MDP_VB_X');
if isfield(par, 'runnerHandle') && ~isempty(par.runnerHandle)
    if isa(par.runnerHandle, 'function_handle')
        defaultRunner = par.runnerHandle;
    else
        defaultRunner = str2func(char(par.runnerHandle));
    end
end
langparams.spm_MDP_VB_H             = defaultRunner;

langparams.level(2).jump            = false;
langparams.level(2).maxT            = 1;
langparams.level(2).sX              = [1,1];
langparams                          = HAI_initialiseParams(langparams);

if ~isfix
    langparams.level(end).D{1}(:)          = 0;
    langparams.level(end).D{1}(idsentence) = 1;
end

obstresh                            = 0.3;
statetresh                          = 0.3;
if isfield(par, 'obsNoise') && ~isempty(par.obsNoise)
    obstresh = par.obsNoise;
end
if isfield(par, 'stateNoise') && ~isempty(par.stateNoise)
    statetresh = par.stateNoise;
end
langparams.level(1).obsnoise(1)     = obstresh;
langparams.level(1).obsnoise(2)     = obstresh;
langparams.level(1).statesnoise(1)  = statetresh;
langparams.level(1).statesnoise(2)  = statetresh;

if isfield(par, 'irng') && ~isempty(irng)
    langparams.irng = irng;
end

maxT                                = langparams.level(end).maxT;
langparams.level(end).s(1,:)        = ones(1,maxT) * idsentence;
langparams.debugmode                = false;

S_start                             = TestMaze.map2D(3,3);
langparams.level(1).s               = [S_start; 5];
Vset(:,:,1)                         = mushiake_get_all_state_sequences(TestMaze.transitions1D, S_start, 3, TestMaze.map2D);
Vset(:,:,2)                         = 1;
V                                   = zeros(4,16,2);
langparams.level(1).maxT            = size(V,1);
V(1:end-1,:,1)                      = Vset(:,:,1);
V(1:end-1,:,2)                      = Vset(:,:,1);
V(end,:,:)                          = 5;
langparams.level(1).V               = V;
langparams.level(1).chi             = 0;
langparams.level(1).tau             = 4*10^1;
langparams.level(1).sX              = [0,1];

langparams.level(1).C{1}            = zeros(size(TestMaze.StatesB,1),1);
langparams.level(1).C{1}(goal_state)= 4;
langparams.level(1).C{2}            = zeros(size(TestMaze.ActionsB,1),1);
langparams.level(1).C{2}(5)         = -8;

MDP                                 = run_hai_trial(langparams, dictionary);
if addSingleStepRecognitionLevel
    MDP = mushiake_attach_single_step_recognition_level(MDP, struct( ...
        'enabled', true, ...
        'mode', singleStepRecognitionMode));
end
MDP.iMushiake                       = iMushiake;

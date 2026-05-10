function MDP = run_mushiake_trial(pms)
%RUN_MUSHIAKE_TRIAL Build one Mushiake trial using the AY 2-level test.

trialIndex = pms.iTrial;
goalStates = [8, 4, 14, 18];
mazeIndices = ones(size(goalStates));
sentenceId = 0;

if isfield(pms, 'goalStates') && ~isempty(pms.goalStates)
    goalStates = pms.goalStates(:)';
end

if isfield(pms, 'mazeIndices') && ~isempty(pms.mazeIndices)
    mazeIndices = pms.mazeIndices(:)';
end

if isfield(pms, 'sentenceId') && ~isempty(pms.sentenceId)
    sentenceId = pms.sentenceId;
end

if trialIndex < 1 || trialIndex > numel(goalStates)
    error('%s:InvalidTrialIndex', mfilename, ...
        'Trial index %d is outside [1,%d].', trialIndex, numel(goalStates));
end

if numel(mazeIndices) < numel(goalStates)
    mazeIndices(end + 1:numel(goalStates)) = mazeIndices(end); %#ok<AGROW>
end

trialParams = struct();
trialParams.idsentence = sentenceId;
trialParams.goal_state = goalStates(trialIndex);
trialParams.isfix = pms.isfix;
trialParams.irng = pms.irng;
trialParams.iMushiake = mazeIndices(trialIndex);

if isfield(pms, 'obsNoise') && ~isempty(pms.obsNoise)
    trialParams.obsNoise = pms.obsNoise;
end

if isfield(pms, 'stateNoise') && ~isempty(pms.stateNoise)
    trialParams.stateNoise = pms.stateNoise;
end

MDP = TEST_AY_2LEV_Mushiake(trialParams);
end

function MDP = run_sensors(pms)
%RUN_SENSORS Run one ABCDEF neutral sensor trial and optionally save it.

if nargin < 1 || isempty(pms)
    pms = run_sensorsParams;
else
    pms = run_sensorsParams(pms);
end

fprintf('Entering %s\n', pms.executorName);
rng(pms.irng);

if ~isfield(pms, 'trialDescription') || isempty(pms.trialDescription)
    pms.trialDescription = build_sensor_trial_description(pms);
end

if isfield(pms, 'trialRunner') && ~isempty(pms.trialRunner)
    MDP = run_custom_sensor_trial(pms);
else
    langparams = HAI_DefaultParams(pms.dictionary);
    langparams.level(1).maxT = pms.level1MaxT;
    langparams.level(2).jump = pms.level2Jump;
    langparams.level(2).maxT = pms.level2MaxT;
    langparams = HAI_initialiseParams(langparams);
    
    if ~pms.isfix
        langparams.level(end).D{1}(:) = 0;
        langparams.level(end).D{1}(pms.iTrial) = 1;
    end
    
    langparams.level(1).maskval = pms.maskval;
    langparams.level(1).obsnoise(1) = pms.obsnoise;
    langparams.irng = pms.irng;
    langparams.spm_MDP_VB_H = str2func('VB_MDP_X');
    langparams.debugmode = pms.debugmode;
    langparams.level(1).s = 0;
    langparams.level(end).s(1, :) = ones(1, pms.level2MaxT) * pms.iTrial;
    langparams.level(end).s(2, :) = 1:pms.level2MaxT;
    
    sensorMDP = run_hai_trial(langparams, pms.dictionary);
    MDP = {sensorMDP};
end

if pms.saveOutput
    if ~isfolder(pms.saveDir)
        mkdir(pms.saveDir);
    end

    timestamp = char(datetime('now', 'Format', 'yyyyMMddHHmmss'));
    filename = fullfile(pms.saveDir, ['MDP_' pms.executorName '_' ...
        pms.trialDescription '_' timestamp]);

    fprintf('Saving %s\n', filename);
    save(filename, 'MDP', '-v7.3');
end
end

function MDP = run_custom_sensor_trial(pms)
% Run one custom sensor-style trial while keeping the standard save format.

runner = pms.trialRunner;
if ischar(runner) || isstring(runner)
    runner = str2func(char(runner));
end

trialOutput = runner(pms);
if isempty(trialOutput)
    error('%s:EmptyCustomTrial', mfilename, ...
        'Custom trial runner returned an empty output for trial %d.', pms.iTrial);
end

if iscell(trialOutput)
    MDP = trialOutput;
else
    MDP = {trialOutput};
end
end

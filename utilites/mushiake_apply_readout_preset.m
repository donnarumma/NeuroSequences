function collectPms = mushiake_apply_readout_preset(collectPms, presetName)
%MUSHIAKE_APPLY_READOUT_PRESET Apply one named firing-rate readout preset.
%
% Presets:
%   legacy_starting_spikes
%       Original spike-generation path from MAIN_HAI_Mushiake:
%       HAI_MDPtoFiringRates + flat prior + smooth(8)
%   snapshot_committed_mean
%       Saved fallback corresponding to the snapshot
%       20260421_030849_committed_average_mean
%   cumulative_mean
%       Incremental readout based on policy averages up to the current epoch

if nargin < 2 || isempty(presetName)
    presetName = 'cumulative_mean';
end

switch lower(char(presetName))
    case 'legacy_starting_spikes'
        collectPms.addFlatPrior = true;
        collectPms.smoothWindow = 8;
        collectPms.firingRateMode = 'legacy_hai';
        collectPms.policySharpness = 1;
        collectPms.policyWeightSource = 'final';
        collectPms.policyTimeWeightPower = 0;

    case 'snapshot_committed_mean'
        collectPms.addFlatPrior = false;
        collectPms.smoothWindow = 0;
        collectPms.firingRateMode = 'committed_average_expanded';
        collectPms.policySharpness = 1;
        collectPms.policyWeightSource = 'mean';
        collectPms.policyTimeWeightPower = 0;

    case 'cumulative_mean'
        collectPms.addFlatPrior = false;
        collectPms.smoothWindow = 0;
        collectPms.firingRateMode = 'cumulative_average_expanded';
        collectPms.policySharpness = 1;
        collectPms.policyWeightSource = 'mean';
        collectPms.policyTimeWeightPower = 0;

    otherwise
        error('%s:UnknownPreset', mfilename, ...
            'Unknown Mushiake readout preset: %s', char(presetName));
end

collectPms.readoutPreset = char(presetName);
end

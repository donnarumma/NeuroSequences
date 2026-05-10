function pms = extract_sequence_data_trialsParams(parSource)
%EXTRACT_SEQUENCE_DATA_TRIALSPARAMS Defaults for data_trials extraction/preparation.

pms.trialIndices        = [];                   % Optional subset of trials to load/use.
pms.trialNameTailLength = 3;                    % Keep only the last N symbols of each trial name.
pms.iFactor             = 1;                    % Hidden factor used to derive firing rates.
pms.Nnr                 = 4;                    % Number of duplicate neurons per population.
pms.dt                  = 1/64;                 % Duration of one DEM update.
pms.Nev                 = [];                   % Optional epoch-wise bin replication; empty falls back to ones(1,nLength).
pms.cap                 = 0.8;                  % Spike saturation parameter.
pms.th                  = 0.1;                  % Noise threshold for spike generation.
pms.noise               = 0;                    % Legacy alias for spikeNoise kept for backward compatibility.
pms.spikeNoise          = 0;                    % Additive probability noise used by the configurable spike generator. Suggested range: 0-0.05.
pms.SpT                 = 1/16;                 % Spike threshold.
pms.spikeGenerationMode = 'thresholded_refractory'; % Suggested default for realistic rasters.
                                                    % Modes:
                                                    %   'legacy'                 -> original dense Bernoulli rule with additive baseline.
                                                    %   'legacy_logit_noise'     -> original unreachable logit/noise variant.
                                                    %   'thresholded_bernoulli'  -> thresholded sparse Bernoulli generator.
                                                    %   'thresholded_refractory' -> thresholded Bernoulli plus refractory period.
pms.spikeMinProb        = 0.01;                 % Spontaneous floor probability for very low rates. Suggested range: 0-0.03.
                                                % Higher values make silent neurons spike occasionally but can add background haze.
pms.spikeMaxProb        = 0.25;                 % Maximum per-bin spike probability after thresholding. Suggested range: 0.15-0.4.
                                                % Lower values avoid black/flat rasters at high FR; higher values make peaks denser.
pms.spikeGamma          = 1.2;                  % Nonlinear contrast on suprathreshold FR. Suggested range: 0.8-2.
                                                % >1 compresses low-mid FR and highlights peaks; <1 makes low-mid activity more visible.
pms.refractoryBins      = 3;                    % Post-spike silent bins enforced only in 'thresholded_refractory'. Suggested range: 1-4.
                                                % Higher values prevent flat spike walls but can make very fast neurons too sparse.
pms.nActions            = 6;                    % Number of action/target categories.
pms.nLength             = 9;                    % Trial length used to rescale time axes.
pms.catNames            = {'A','B','C','D','E','F'}; % Symbolic target labels.
pms.percCenter          = 0.75;                 % Main cosine-tuning weight.
pms.usePreprocessedPopFR = false;               % If true, popFR is already smoothed/cosine-tuned before extension.

if nargin < 1 || isempty(parSource)
    return;
end

fieldNames = fieldnames(parSource);
for fieldIndex = 1:numel(fieldNames)
    pms.(fieldNames{fieldIndex}) = parSource.(fieldNames{fieldIndex});
end
end

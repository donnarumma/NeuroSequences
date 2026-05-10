function Spikes = firingRatesToSpikes(FiringRates, par)
%FIRINGRATESTOSPIKES Convert firing rates into binary spike rasters.
% The legacy generator is preserved exactly, while newer modes offer more
% realistic sparse rasters with explicit thresholding and refractoriness.

cap = resolve_spike_param(par, 'cap', 0.8);
th = resolve_spike_param(par, 'th', 0.1);
SpT = resolve_spike_param(par, 'SpT', 1/16);
spikeNoise = resolve_spike_noise(par);
mode = lower(strtrim(char(resolve_spike_param(par, 'spikeGenerationMode', 'legacy'))));
spikeMinProb = resolve_spike_param(par, 'spikeMinProb', 0.01);
spikeMaxProb = resolve_spike_param(par, 'spikeMaxProb', 0.35);
spikeGamma = resolve_spike_param(par, 'spikeGamma', 1.0);
refractoryBins = max(0, round(resolve_spike_param(par, 'refractoryBins', 2)));

switch mode
    case 'legacy'
        clippedRates = FiringRates;
        clippedRates(clippedRates > cap) = cap;
        Spikes = rand(size(clippedRates)) > clippedRates * (1 - SpT) + th;
        Spikes = ~Spikes;

    case 'legacy_logit_noise'
        clippedRates = min(max(FiringRates, 0), 1);
        scaledRates = clippedRates * (cap - th) + th;
        logit = log(scaledRates ./ (1 - scaledRates + eps));
        prob = 1 ./ (1 + exp(-(logit + spikeNoise * randn(size(logit)))));
        Spikes = rand(size(prob)) < prob;

    case {'thresholded_bernoulli', 'thresholded_refractory'}
        clippedRates = min(max(FiringRates, 0), cap);
        thresholdedRates = max(clippedRates - th, 0);
        denom = max(cap - th, eps);
        prob = thresholdedRates / denom;
        prob = prob .^ max(spikeGamma, eps);
        spikeMinProb = min(max(spikeMinProb, 0), 1);
        spikeMaxProb = min(max(spikeMaxProb, spikeMinProb), 1);
        prob = spikeMinProb + (spikeMaxProb - spikeMinProb) * prob;

        if spikeNoise > 0
            prob = prob + spikeNoise * randn(size(prob));
        end

        prob = min(max(prob, 0), 1);
        Spikes = rand(size(prob)) < prob;

        if strcmp(mode, 'thresholded_refractory') && refractoryBins > 0
            Spikes = apply_refractory_bins(Spikes, refractoryBins);
        end

    otherwise
        error('%s:InvalidSpikeGenerationMode', mfilename, ...
            'Unknown spikeGenerationMode: %s.', mode);
end
end

function value = resolve_spike_param(par, fieldName, defaultValue)
% Resolve one spike-generation parameter with a fallback default.

if isstruct(par) && isfield(par, fieldName) && ~isempty(par.(fieldName))
    value = par.(fieldName);
else
    value = defaultValue;
end
end

function spikeNoise = resolve_spike_noise(par)
% Resolve spike noise, keeping the legacy alias `noise` alive.

spikeNoise = resolve_spike_param(par, 'spikeNoise', []);
if ~isempty(spikeNoise)
    return;
end

spikeNoise = resolve_spike_param(par, 'noise', 0);
end

function Spikes = apply_refractory_bins(Spikes, refractoryBins)
% Enforce a minimum silent period after each emitted spike.

for iNeuron = 1:size(Spikes, 1)
    nextAllowedSpike = 1;
    for iTime = 1:size(Spikes, 2)
        if iTime < nextAllowedSpike
            Spikes(iNeuron, iTime) = false;
            continue;
        end

        if Spikes(iNeuron, iTime)
            nextAllowedSpike = iTime + refractoryBins + 1;
        end
    end
end
end

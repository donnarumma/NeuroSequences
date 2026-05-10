function pms = cosineTuneCircularBlocksParams(pmsOver)
%COSINETUNECIRCULARBLOCKSPARAMS Default parameters for cosineTuneCircularBlocks.
%
% This variant reuses the generic cosineTune parameters but applies the
% circular spread rule independently inside every block, regardless of the
% symbolic trial type. The most relevant parameters inherited from
% cosineTuneParams are:
%
%   blockSize
%     Number of neurons in each circular block.
%     Typical value here: 6.
%
%   centerRetention
%     Fraction of each neuron's own activity retained at its original
%     position before lateral spread.
%     Typical range: 0.70 - 0.90.
%
%   spreadGain
%     Gain on the residual activity redistributed across the block.
%     Typical range: 0.8 - 3.
%
%   kernelFloor
%     Adimensional floor added to the non-central distance kernel before
%     normalization. It is not a firing-rate unit and not a direct
%     probability. Positive values flatten the tuning and guarantee some
%     spread even to far units.
%     Typical range: 0 - 0.5.
%
%   kernelSharpness
%     Exponent controlling how much the cosine kernel concentrates on the
%     nearest neighbours.
%     Typical range: 5 - 40.
%
%   directionBias
%     Optional multiplicative bias applied to the distance kernel before
%     normalization.
%     Accepted sizes:
%       []                  no directional bias
%       [blockSize x 1]     same bias reused for every block
%       [numNeurons x 1]    explicit bias for every neuron in the full vector
%     Interpretation:
%       values > 1 amplify spread toward those positions
%       values < 1 attenuate spread toward those positions
%       values ~= 1 introduce mild asymmetry without changing the global
%       tuning recipe
%     Practical ranges:
%       1                   symmetric tuning
%       0.95 - 1.05         very mild asymmetry
%       0.8  - 1.2          visible directional preference
%     For reproducible small asymmetries, a vector close to ones(...) is
%     usually the safest choice.
%
% Suggested presets:
%   Similar to cosineTuningStep (center + two neighbours):
%     centerRetention = 0.75
%     spreadGain      = 1.0
%     kernelFloor     = 0
%     kernelSharpness = 40
%     directionBias   = []
%
%   Similar to cosineTune defaults:
%     centerRetention = 0.85
%     spreadGain      = 2.5
%     kernelFloor     = 0
%     kernelSharpness = 20
%     directionBias   = []

if nargin < 1 || isempty(pmsOver)
    pmsOver = struct();
end

pms = cosineTuneParams();

overFields = fieldnames(pmsOver);
for fieldIndex = 1:numel(overFields)
    fieldName = overFields{fieldIndex};
    pms.(fieldName) = pmsOver.(fieldName);
end
end

function pms = cosineTuneParams(pmsOver)
%COSINETUNEPARAMS Default parameters for cosineTune.

if nargin < 1 || isempty(pmsOver)
    pmsOver = struct();
end

% Number of neurons in each circular population.
% Typical range: positive integer, usually 6 in the sequence tasks here.
% Larger blocks make the circular distance kernel broader over more units.
pms.blockSize           = 6;

% Fraction of the preferred unit activity retained at the center.
% Units: fraction of the active neuron's own firing, in [0, 1].
% Typical range:
%   0.70 - 0.90  strong center with visible spread
%   0.90 - 0.98  very sharp tuning
% Lower values spread more residual activity to neighbours.
pms.centerRetention     = 0.85;
% Gain applied to the redistributed residual activity.
% Units: dimensionless multiplier on the residual (1-centerRetention).
% Typical range:
%   0.8 - 1.2    close to conservative redistribution
%   1.5 - 3      stronger lateral spread
% Values > 1 amplify the redistributed activity before clipping.
pms.spreadGain          = 2.5; %0.8 old version, very low tuning
% Positive floor added to the non-central distance kernel before normalization.
% Units: adimensional kernel offset, not firing-rate units.
% Typical range:
%   0           no extra baseline spread
%   0.01 - 0.1  mild flattening of the kernel
%   0.1 - 0.5   visible spread even to far units
% This makes tuning less selective by giving distant units a minimum weight.
pms.kernelFloor         = 0;
% Selectivity of the circular distance kernel.
% Units: adimensional exponent applied to the cosine kernel.
% Typical range:
%   5 - 15      broad, smooth tuning
%   20 - 40     sharper nearest-neighbour tuning
%   > 40        almost step-like concentration on adjacent units
% Larger values emphasize nearest neighbours and suppress distant units.
pms.kernelSharpness     = 20;

% pms.spreadGain         = 2; 
% pms.kernelFloor        = 0;%2.0;
% Whether to clip final firing rates to the [0, 1] range.
% Recommended: true for normalized population activity.
pms.clipToUnit          = true;
% Optional asymmetry/noise scale reserved for experimental variants.
% Units: standard deviation of the perturbation term.
% Typical range:
%   0           deterministic tuning
%   1e-5 - 1e-3 tiny numerical asymmetry
%   >= 1e-2     visible stochastic distortion
pms.asymmetrySigma     = 0;0.00005;%0.1; % standard deviation for asymmetric noise
overFields              = fieldnames(pmsOver);

for fieldIndex = 1:numel(overFields)
    fieldName = overFields{fieldIndex};
    pms.(fieldName) = pmsOver.(fieldName);
end
end

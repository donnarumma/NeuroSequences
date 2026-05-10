function [cosineFunction, cosinepms, cosineFunctionName, SpikeMode] = getCosineTuning(tunemode)

switch tunemode
    case 0
        % no tuning, i.e. identity function on the one-hot input vector
        cosineFunctionName              = [];
        cosinepms                       = [];
    case 1
        cosineFunctionName              = 'cosineTune';
        cosinepms                       = cosineTuneParams();
        cosinepms.cosinepms_perc_center = 0.75;
        cosinepms.cosinepms_perc_side   = (1-cosinepms.cosinepms_perc_center)/2;
    case 2
        cosineFunctionName              = 'cosineTuningStep';
        cosinepms.perc_center           = 0.75;
        cosinepms.perc_side             = (1-cosinepms.perc_center)/2;
    case 3
        cosineFunctionName              = 'cosineTuneCircularBlocks';
        cosinepms                       = cosineTuneCircularBlocksParams();
        % cosinepms.centerRetention       = 0.85;
    case 4
        cosineFunctionName              = 'cosineTuneCircularBlocks';
        cosinepms                       = cosineTuneCircularBlocksParams();
        cosinepms.blockSize       = 6;
        cosinepms.centerRetention = 0.60;   % prova 0.50–0.75
        cosinepms.spreadGain      = 2.5;    % prova 1.5–3.5
        cosinepms.kernelFloor     = 0;      % tienilo a zero
        cosinepms.kernelSharpness = 2;      % prova 1–6, non 20
        cosinepms.clipToUnit      = true;
end
if ~isempty(cosineFunctionName) 
    cosineFunction=str2func(cosineFunctionName);
else
    cosineFunction=[];
    cosineFunctionName='NoTuning';
    return;
end
nSteps = 3; % number of time steps to watch out 
%cosinepms.directionBias = directionNoise(cosinepms.blockSize*nSteps); 

%decay = 0.05;
%noiseLevel = 0.01; % small

%delta      = 0.6;
base       = 1.0;
decay      = 0.0;                
irng       = 1;
noiseLevel = 0.20 * ones(1,nSteps);
delta       = 0.6;

cosinepms.directionBias = dirBias(cosinepms.blockSize,nSteps,base,decay,noiseLevel,delta,irng);
cosinepms.biasMode = 'additive';
cosinepms.biasStrength = [0.00 0.20 0.40];
%cosinepms.directionBias = dirBias(cosinepms.blockSize,nSteps,base,decay,noiseLevel,delta,irng); 
% cosinepms.directionBias
SpikeMode= 'thresholded_refractory';
end

function dNoise = directionNoise(vecsize)
% rng( 10); fact = 6*10^(-14);     spreadGain  = 4;   %Giov1
% rng(100); fact = 10*10^-14*10^3; spreadGain  = 2.5; %Giov1.5
% rng(100); fact = 10*10^-14*10^3; spreadGain  = 2;   %Giov2
% rng(100); fact = 10*10^-14*10^3; spreadGain  = 0.8; %Giov3

rng(100); % fix the noise for the run
fact  = 10*10^-14*10^3;
dNoise  = ones(1, vecsize) + randn(1, vecsize) * fact; % 6*10^-14*10^3;
end


function dBias = dirBias(blocksize, nSteps, base, decay, noiseLevel, delta, irng)
% DIRBIAS Generate a direction-dependent bias vector across blocks.
%
% This function creates a 1 x (blocksize * nSteps) vector that modulates
% the circular tuning kernel. Each block (e.g., A(1)-F(1), A(2)-F(2), ...)
% receives a slightly different bias.
%
% The bias has two components:
%   1) A block-wise baseline (controlled by base and decay)
%   2) Within-block variability (controlled by noiseLevel)
%
% IMPORTANT:
% Since the kernel is normalized after applying the bias, a uniform scaling
% within a block has little effect. The key factor influencing dimensionality
% is the variability *within* each block (i.e., noiseLevel).
%
% INPUTS:
%   blocksize   - Number of neurons per block (e.g., 6 for A–F)
%   nSteps      - Number of blocks / time steps (e.g., 3 for (1),(2),(3))
%   base        - Base bias value for the first block (typically ~1.0)
%   decay       - Linear decrease of the base across blocks
%                 (block i gets base - (i-1)*decay)
%   noiseLevel  - Controls variability within each block
%                 Can be:
%                   scalar → same noise for all blocks
%                   1 x nSteps vector → different noise per block
%                 Higher noise → more asymmetry → higher dimensionality
%   delta       - Symmetric clamp around 1 to avoid extreme values
%
%   irng        - Random seed for reproducibility
%
% OUTPUT:
%   dBias       - 1 x (blocksize*nSteps) bias vector
%
% NOTE:
% To obtain decreasing dimensionality across blocks:
%   use decreasing noiseLevel, e.g. [0.04 0.02 0.005]

% -------------------------------------------------------------------------

% Set random seed
try
    rng(irng);
catch
    rng(1);
end

% Preallocate
directionBias = zeros(1, blocksize * nSteps);

% Handle noiseLevel (scalar or per-block vector)
if isscalar(noiseLevel)
    noiseByBlock = repmat(noiseLevel, 1, nSteps);
else
    noiseByBlock = noiseLevel;
end

% Generate bias block by block
for ib = 1:nSteps
    idx = (ib-1)*blocksize + (1:blocksize);

    % Baseline for this block
    blockBase = base - (ib-1)*decay;

    % Add within-block variability (critical for dimensionality)
    directionBias(idx) = blockBase + noiseByBlock(ib) * randn(1, blocksize);
end

% Symmetric clamp around 1 to avoid extreme values
dBias = min(max(directionBias, 1 - delta), 1 + delta);

end
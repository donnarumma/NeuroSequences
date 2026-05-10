function popFRmod = cosineTuneCircularBlocks(popFRt, ~, varargin)
%COSINETUNECIRCULARBLOCKS Apply circular tuning independently within each block.
%
% Parameters:
%   pms.blockSize
%   pms.centerRetention
%   pms.spreadGain
%   pms.kernelFloor
%   pms.kernelSharpness
%   pms.clipToUnit
%   pms.directionBias    - [] or vector length blockSize or numNeurons
%   pms.biasStrength     - scalar or 1 x nBlocks vector
%   pms.biasMode         - 'gain' or 'additive'
%
% Bias modes:
%   'gain':
%       blockOutput = blockOutput .* gainBias
%
%   'additive':
%       blockOutput = blockOutput + biasStrength * std(blockOutput) * noiseVec
%
% In additive mode, directionBias is converted into a zero-mean direction
% perturbation. This is more noise-like and less likely to collapse the
% representation into a few dominant gain directions.

pms = resolveFunctionParams('cosineTuneCircularBlocks', varargin{:});

if ~isfield(pms, 'biasMode') || isempty(pms.biasMode)
    pms.biasMode = 'gain';
end

popFRt = popFRt(:);
numNeurons = numel(popFRt);
blockSize = pms.blockSize;

if mod(numNeurons, blockSize) ~= 0
    error('cosineTuneCircularBlocks:InvalidBlockSize', ...
        'Number of neurons must be a multiple of pms.blockSize.');
end

nBlocks = numNeurons / blockSize;
localIdx = 1:blockSize;
popFRmod = popFRt;

for iBlock = 1:nBlocks
    blockStart = (iBlock - 1) * blockSize + 1;
    blockIdx = blockStart:(blockStart + blockSize - 1);
    blockValues = popFRt(blockIdx);

    blockBias = [];
    if ~isempty(pms.directionBias)
        directionBias = pms.directionBias(:);

        if numel(directionBias) == blockSize
            blockBias = directionBias(:);
        elseif numel(directionBias) == numNeurons
            blockBias = directionBias(blockIdx);
        else
            error('cosineTuneCircularBlocks:InvalidDirectionBias', ...
                'directionBias must have length blockSize or numNeurons.');
        end
    end

    if isfield(pms, 'biasStrength') && ~isempty(pms.biasStrength)
        if isscalar(pms.biasStrength)
            biasStrength = pms.biasStrength;
        elseif numel(pms.biasStrength) == nBlocks
            biasStrength = pms.biasStrength(iBlock);
        else
            error('cosineTuneCircularBlocks:InvalidBiasStrength', ...
                'biasStrength must be scalar or have length nBlocks.');
        end
    else
        biasStrength = 1;
    end

    spreadActivity = zeros(blockSize, 1);

    for centerNeuron = 1:blockSize
        circularDistance = abs(localIdx - centerNeuron);
        circularDistance = min(circularDistance, blockSize - circularDistance);

        distanceKernel = (cos(2*pi*circularDistance/blockSize) + 1) / 2;
        distanceKernel = distanceKernel .^ pms.kernelSharpness;

        distanceKernel(centerNeuron) = 0;

        distanceKernel = distanceKernel + pms.kernelFloor;
        distanceKernel(centerNeuron) = 0;

        normaliser = sum(distanceKernel);
        if normaliser <= 0
            continue;
        end

        residualActivity = (1 - pms.centerRetention) * blockValues(centerNeuron);

        spreadVector = pms.spreadGain * residualActivity * ...
            (distanceKernel(:) / normaliser);

        spreadActivity = spreadActivity + spreadVector;
    end

    retainedActivity = pms.centerRetention * blockValues;
    blockOutput = retainedActivity + spreadActivity;

    if ~isempty(blockBias) && biasStrength > 0
        gainBias = blockBias(:);

        if mean(gainBias) <= 0
            error('cosineTuneCircularBlocks:InvalidDirectionBiasMean', ...
                'directionBias must have positive mean within each block.');
        end

        gainBias = gainBias / mean(gainBias);

        switch lower(pms.biasMode)

            case 'gain'
                biasedOutput = blockOutput .* gainBias;

                blockOutput = (1 - biasStrength) * blockOutput + ...
                               biasStrength  * biasedOutput;

            case 'additive'
                noiseVec = gainBias - 1;
                noiseVec = noiseVec - mean(noiseVec);

                s = std(blockOutput);
                if s == 0
                    s = mean(abs(blockOutput));
                end
                if s == 0
                    s = 1;
                end

                blockOutput = blockOutput + biasStrength * s * noiseVec;

            otherwise
                error('cosineTuneCircularBlocks:InvalidBiasMode', ...
                    'biasMode must be ''gain'' or ''additive''.');
        end
    end

    popFRmod(blockIdx) = blockOutput;
end

if pms.clipToUnit
    popFRmod = min(max(popFRmod, 0), 1);
end

end
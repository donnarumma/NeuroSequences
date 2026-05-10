function popFRmod = cosineTune(popFRt, tuneType, varargin)
%COSINETUNE Spread central activity across a circular population.
%
% The preferred unit retains part of its activity, while a distance-dependent
% fraction of its activity is added to the other units in the same circular block.

pms = resolveFunctionParams('cosineTune', varargin{:});

popFRt = popFRt(:);
tuneType = tuneType(:);

numNeurons = numel(popFRt);
blockSize = pms.blockSize;

if numel(tuneType) ~= numNeurons
  %  error('cosineTune:InvalidInput', ...
 %       'popFRt and tuneType must have the same number of elements.');
end

if mod(numNeurons, blockSize) ~= 0
    error('cosineTune:InvalidBlockSize', ...
        'Number of neurons must be a multiple of pms.blockSize.');
end

popFRmod = popFRt;
centerIdx = find(tuneType == 1);

for centerNeuron = centerIdx(:)'

    blockNumber = ceil(centerNeuron / blockSize);
    blockStart = (blockNumber - 1) * blockSize + 1;
    blockIdx = blockStart:(blockStart + blockSize - 1);

    localCenter = centerNeuron - blockStart + 1;
    localIdx = 1:blockSize;

    circularDistance = abs(localIdx - localCenter);
    circularDistance = min(circularDistance, blockSize - circularDistance);

    distanceKernel = (cos(2*pi*circularDistance/blockSize) + 1) / 2;
    distanceKernel = distanceKernel .^ pms.kernelSharpness;

    distanceKernel(localCenter) = 0;
    distanceKernel = distanceKernel + pms.kernelFloor;
    distanceKernel(localCenter) = 0;

    % directionBias
    if ~isempty(pms.directionBias)

        directionBias = pms.directionBias(:);

        if numel(directionBias) == blockSize
            blockBias = directionBias(:)';
        elseif numel(directionBias) == numNeurons
            blockBias = directionBias(blockIdx)';
        else
            error('cosineTune:InvalidDirectionBias', ...
                'directionBias must have length blockSize or numNeurons.');
        end

        distanceKernel = distanceKernel .* blockBias;
    end

    distanceShare = distanceKernel ./ sum(distanceKernel);

    centerActivity = popFRt(centerNeuron);
    residualActivity = (1 - pms.centerRetention) * centerActivity;

    popFRmod(centerNeuron) = pms.centerRetention * centerActivity;

    popFRmod(blockIdx) = popFRmod(blockIdx) + ...
        pms.spreadGain * residualActivity * distanceShare(:);
end

if pms.clipToUnit
    popFRmod = min(max(popFRmod, 0), 1);
end

end
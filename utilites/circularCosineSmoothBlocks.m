function popFR_mod = circularCosineSmoothBlocks(popFRt, groupSize, kappa)
%CIRCULARCOSINESMOOTHBLOCKS Smooth all entries within each block circularly.

    if nargin < 2 || isempty(groupSize)
        groupSize = 8;
    end
    if nargin < 3 || isempty(kappa)
        kappa = 1;
    end

    popFRt = popFRt(:);
    N = numel(popFRt);

    if mod(N, groupSize) ~= 0
        error('Length of popFRt must be a multiple of groupSize.');
    end

    theta = 2*pi*(0:groupSize-1)'/groupSize;
    dtheta = angle(exp(1i*(theta - theta(1))));
    kernel = 1 + kappa*cos(dtheta);
    kernel(kernel < 0) = 0;
    kernel = kernel / sum(kernel);

    nGroups = N / groupSize;
    popFR_mod = zeros(size(popFRt));

    for g = 1:nGroups
        idx = (g-1)*groupSize + (1:groupSize);
        x = popFRt(idx);

        y = zeros(groupSize,1);
        for i = 1:groupSize
            for j = 1:groupSize
                shift = mod(i-j, groupSize) + 1;
                y(i) = y(i) + kernel(shift) * x(j);
            end
        end

        popFR_mod(idx) = y;
    end
end
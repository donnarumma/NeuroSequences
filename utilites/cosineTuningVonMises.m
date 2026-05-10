function popFR_mod = cosineTuningVonMises(popFRt, type, groupSize, beta)
%COSINETUNINGVONMISES Circular smooth tuning using exp(beta*cos(dtheta)).

    if nargin < 3 || isempty(groupSize)
        groupSize = 8;
    end
    if nargin < 4 || isempty(beta)
        beta = 1.5;
    end

    popFRt = popFRt(:);
    type   = type(:);

    N = numel(popFRt);

    if numel(type) ~= N
        error('popFRt and type must have the same length.');
    end

    if mod(N, groupSize) ~= 0
        error('Length of popFRt must be a multiple of groupSize.');
    end

    popFR_mod = popFRt;

    theta = 2*pi*(0:groupSize-1)'/groupSize;
    idxActive = find(type == 1);

    for ii = 1:numel(idxActive)
        center = idxActive(ii);

        groupStart = floor((center-1)/groupSize)*groupSize + 1;
        groupIdx   = groupStart:(groupStart + groupSize - 1);

        localCenter = center - groupStart + 1;
        theta0      = theta(localCenter);

        dtheta = angle(exp(1i*(theta - theta0)));

        weights = exp(beta*cos(dtheta));
        weights = weights / sum(weights);

        total = popFRt(center);

        popFR_mod(center) = popFR_mod(center) - total;
        popFR_mod(groupIdx) = popFR_mod(groupIdx) + total * weights;
    end
end
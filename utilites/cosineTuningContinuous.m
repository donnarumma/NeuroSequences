function popFR_mod = cosineTuningContinuous(popFRt, type, groupSize, kappa)
%COSINETUNINGCONTINUOUS Continuous circular cosine tuning within groups.
%
% popFR_mod = cosineTuningContinuous(popFRt, type, groupSize, kappa)
%
% INPUT
%   popFRt     : [N x 1] firing rates
%   type       : [N x 1] binary vector, 1 = active center to redistribute
%   groupSize  : size of each circular group (default = 8)
%   kappa      : cosine modulation strength in [0, 1]
%                0 -> uniform redistribution
%                1 -> strongest cosine-like redistribution
%
% OUTPUT
%   popFR_mod  : [N x 1] modulated firing rates
%
% NOTE
%   Redistribution is performed independently within each group.
%   No interaction occurs across different groups.

    if nargin < 3 || isempty(groupSize)
        groupSize = 8;
    end
    if nargin < 4 || isempty(kappa)
        kappa = 1;
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

    if kappa < 0 || kappa > 1
        error('kappa must be in [0, 1].');
    end

    popFR_mod = popFRt;

    % Equally spaced angles inside each group
    theta = 2*pi*(0:groupSize-1)'/groupSize;

    idxActive = find(type == 1);

    for ii = 1:numel(idxActive)
        center = idxActive(ii);

        % Identify the group containing this center
        groupStart = floor((center-1)/groupSize)*groupSize + 1;
        groupIdx   = groupStart:(groupStart + groupSize - 1);

        % Position of center inside the group
        localCenter = center - groupStart + 1;
        theta0      = theta(localCenter);

        % Circular angular distance within the group
        dtheta = angle(exp(1i*(theta - theta0)));

        % Cosine kernel
        weights = 1 + kappa*cos(dtheta);

        % Ensure non-negative and normalize
        weights(weights < 0) = 0;
        weights = weights / sum(weights);

        total = popFRt(center);

        % Remove original center contribution once
        popFR_mod(center) = popFR_mod(center) - total;

        % Redistribute over the whole block
        popFR_mod(groupIdx) = popFR_mod(groupIdx) + total * weights;
    end
end
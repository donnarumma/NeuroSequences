function [B_all, order_all] = SequenceTransitions(targets, sequences, explorations)
% Generate B transition matrices for each sequence and exploration order
% targets:     list of states (e.g., {'Neutral','A','B','C'})
% sequences:   [nSeq x nLen] matrix of target IDs (e.g., [2 3 4])
% explorations:[nPerm x nLen] matrix of exploration index orders (e.g., perms(1:nLen))

nS_target       = numel(targets);
[nSeq, nLen]    = size(sequences);
nPerm           = size(explorations, 1);

B_all           = zeros(nS_target, nS_target, nSeq * nPerm) + eps;
order_all       = zeros(nSeq * nPerm, nLen);

counter = 0;
for iPerm = 1:nPerm
    idx_order                   = explorations(iPerm, :);     % e.g., [3 2 1] steps
    for iSeq = 1:nSeq
        sequence                = sequences(iSeq, :);         % e.g., [2 3 4]
    
        counter                 = counter + 1;
        target_order            = sequence(idx_order);        % permuted sequence
        order_all(counter,:)    = idx_order;

        for iStep = 1:(nLen - 1)
            from = target_order(iStep);
            to   = target_order(iStep + 1);
            B_all(to, from, counter) = 1;
        end
    end
end
end

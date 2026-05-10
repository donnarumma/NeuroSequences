function   [transitions, expanded_seqs, labels] = expandedSequenceTransitions(targets, sequences, explorations)
% function [transitions, expanded_seqs, labels] = expandedSequenceTransitions(targets, sequences, explorations)
% Explodes target sequences into transitions over expanded representations (e.g., A1, C3, B2)
% 
% Inputs:
%   targets      - list of targets (e.g., 1:3 for A, B, C)
%   sequences    - [nSeq x nSteps] matrix (e.g., [1 3 2])
%   explorations - [nExpl x nSteps] matrix of index orders (e.g., [1 2 3])
%
% Outputs:

%   transitions     - [nExploded x nExploded x nSeqs * nExpl] transition matrices
%   expanded_seqs   - [nSeqs * nExpl x nSteps] expanded index representation (e.g., [A1, C3, B2])
%   labels          - [nExploded x 1] string labels (e.g., 'A1','A2','B1',...)

nTargets     = numel(targets);
[nSeqs, nSteps] = size(sequences);
nExpl        = size(explorations, 1);
nExpanded    = nTargets * nSteps;

transitions  = zeros(nExpanded, nExpanded, nSeqs * nExpl);
expanded_seqs = zeros(nSeqs * nExpl, nSteps);

% === Generate exploded labels (A1, A2, ..., C3)
labels = strings(nExpanded, 1);
for iTarget = 1:nTargets
    for iStep = 1:nSteps
        labels((iTarget-1)*nSteps + iStep) = sprintf('%s%d', char(64 + targets(iTarget)), iStep);
    end
end

% === Generate exploded transitions and sequences
counter = 0;
for iExpl = 1:nExpl
    idx_order = explorations(iExpl, :);  % e.g. [1 3 2]
    for iSeq = 1:nSeqs
        counter = counter + 1;
        seq = sequences(iSeq, :);        % e.g. [1 3 2]
        
        for iStep = 1:nSteps
            tgt      = seq(idx_order(iStep));
            exp_idx  = (tgt - 1)*nSteps + iStep;
            expanded_seqs(counter, iStep) = exp_idx;
        end
        
        % Transitions between exploded steps
        for iStep = 1:(nSteps - 1)
            from = expanded_seqs(counter, iStep);
            to   = expanded_seqs(counter, iStep + 1);
            transitions(to, from, counter) = 1;
        end
    end
end
end

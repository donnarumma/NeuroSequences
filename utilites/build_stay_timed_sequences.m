function [goSequences, goNeutrals, goEnds, stayTimeline, targetPositions] = ...
    build_stay_timed_sequences(goDirs, sequences, nSteps, anchorLength, nStayStates)
%BUILD_STAY_TIMED_SEQUENCES Build time-aligned GoToTarget rows with configurable stay states.
%
% The trial timeline is represented with one state per timestep. Non-target
% timesteps are assigned stay states. If fewer stay states than timesteps are
% available, the last stay state is reused for the remaining timesteps.

if nargin < 5 || isempty(nStayStates)
    nStayStates = nSteps;
end

if nStayStates < 1
    error('%s:InvalidStayCount', mfilename, ...
        'nStayStates must be at least 1.');
end

seqLen = size(sequences, 2);
nSeqs = size(sequences, 1);
nDirs = numel(goDirs);

initialNeutralCount = nSteps - anchorLength - 1;
if initialNeutralCount < 0
    error('%s:InvalidAnchorLength', mfilename, ...
        'anchorLength=%d is incompatible with nSteps=%d.', ...
        anchorLength, nSteps);
end

targetStart = initialNeutralCount + 1;
targetPositions = targetStart + (0:(seqLen - 1));
endPositions = (targetStart + seqLen):nSteps;

stayIndices = 1:min(nSteps, nStayStates);
stayTimeline = nDirs + stayIndices;

if nStayStates < nSteps
    stayTimeline = [stayTimeline, ...
        repmat(nDirs + nStayStates, 1, nSteps - nStayStates)];
end

goSequences = repmat(stayTimeline, nSeqs, 1);
goSequences(:, targetPositions) = sequences;

goNeutrals = stayTimeline(1:initialNeutralCount);
goEnds = stayTimeline(endPositions);
end

function   [goSequences, sequences, goNeutrals, goEnds] = Sequences1D(goDirs,maxLen,nStayStates)
% function [goSequences, sequences, goNeutrals, goEnds] = Sequences1D(goDirs,maxLen)
sequences   = goDirs';
nSeqs       = length(sequences);

if nargin < 3
    totalLength = nSeqs*2 + 3;
    goalls      = nSeqs+1:totalLength-1;
    goEnds      = goalls(end-maxLen+1:end);
    goNeutrals  = goalls(1:maxLen+2);
    goSequences = repmat([goNeutrals nan goEnds],nSeqs,1);
    iPlace       = length(goNeutrals)+1;
    for iSeq =1:nSeqs
        goSequences(iSeq,iPlace)=sequences(iSeq);
    end
else
    nSteps = (2 * maxLen) + 3;
    [goSequences, goNeutrals, goEnds] = build_stay_timed_sequences( ...
        goDirs, sequences, nSteps, maxLen, nStayStates);
end
end

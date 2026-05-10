function   [goSequences, sequences, goGenerator, goNeutrals, goEnds] = Sequences2D(goDirs,types,maxSeqLen,minLen,nStayStates)
% function [goSequences, sequences, goGenerator, goNeutrals, goEnds] = Sequences2D(goDirs,types,maxSeqLen,minLen)

try 
    minLen;
catch
    minLen=2;
end

nDirs       = length(goDirs);
sequences   = perms(goDirs);
% to change to have sequences of different lenghts
sequences   = sequences(:,1:2); %if 3D -> ABC, ACB etc
sequences   = unique(sequences,'rows');

if     maxSeqLen == 3
    nSteps = 9;
elseif maxSeqLen == 2
    nSteps = 7;
end

if nargin < 5
    goNeutrals  = (nDirs)+ (1:(nSteps-1-maxSeqLen));        % neutral successor states
    if nSteps<9
        goEnds  = goNeutrals(end)+1;
    else
        goEnds  = goNeutrals(end)+(1:2);
    end

    if minLen==1
        goEnds=goEnds+1;
    end
    goSequences = [repmat(goNeutrals,size(sequences,1),1), sequences, ...
        repmat(goEnds,size(sequences,1),1)];
else
    [goSequences, goNeutrals, goEnds] = build_stay_timed_sequences( ...
        goDirs, sequences, nSteps, maxSeqLen, nStayStates);
end

nTypes      = size(types,1);
goGenerator = zeros(nTypes,nSteps);
for iGen=1:size(goGenerator,1)
    if nSteps<9
        goGenerator(iGen,:) = [1:length(goNeutrals),length(goNeutrals)+types(iGen,:),nSteps];
    else
        goGenerator(iGen,:) = [1:length(goNeutrals),length(goNeutrals)+types(iGen,:),nSteps-1:nSteps];
    end
end

end

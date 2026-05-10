function   [goSequences, sequences, goGenerator, goNeutrals, goEnds] = Sequences3D(goDirs,types,minLen,nStayStates)
% function [goSequences, sequences, goGenerator, goNeutrals, goEnds] = Sequences3D(goDirs,types,minLen)

try 
    minLen;
catch
    minLen=2;
end

nDirs       = length(goDirs);
sequences   = perms(goDirs);
% to change to have sequences of different lenghts
sequences   = sequences(:,1:3); %if 3D -> ABC, ACB etc
sequences   = unique(sequences,'rows');
nSteps      = 9;

if nargin < 4
    goNeutrals  = (nDirs)+ (1:(nSteps-1-3));        % neutral successor states
    if minLen==2
        goEnds      = goNeutrals(end)+(1:2);
    elseif minLen==1
        goEnds      = goNeutrals(end)+(1:2)+1;
    end
    goSequences = [repmat(goNeutrals,size(sequences,1),1), sequences, ...
        repmat(goEnds(end),size(sequences,1),1)];
else
    [goSequences, goNeutrals, goEnds] = build_stay_timed_sequences( ...
        goDirs, sequences, nSteps, 3, nStayStates);
end

nTypes      = size(types,1);
goGenerator = zeros(nTypes,nSteps);
for iGen=1:size(goGenerator,1)
    goGenerator(iGen,:) = [1:length(goNeutrals),length(goNeutrals)+types(iGen,:),nSteps];
end

end

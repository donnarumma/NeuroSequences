function   labs=neuronLabels(nReps)
% function labs=neuronLabels(nReps)
try 
    reps;
catch
    reps=[1,1,1];
end
dictionary  = DICTIONARY_ABCDEF_2LEV();
nWords      = length(dictionary.Word);
levels      = 3;
labs        = cell(levels,1);
%% labs3
labs3       = cell(nReps(3),nWords);
nSteps3     = 3;
for istep=1:nSteps3
    for iw=1:nWords
        ind         =iw+nWords*(istep-1); 
        curlab      =(HAI_retrieveLevel(dictionary.Word{iw},''));
        curlab      =curlab([1,3,5]);
        curlab      =[curlab '(' num2str(istep) ')'];
        for irep3=1:nReps(3)
            labs3{irep3,ind}  = curlab;
        end
    end
end
labs3       = labs3(:);
%% labs2
cats        = 'A':'F';
nCats       = length(cats);
nSteps2      = 9;
tReset      = 5;
labs2       = cell(nReps(2),nSteps2*nCats);
for istep=1:nSteps2
    for icat=1:nCats
        curlab = [cats(icat) '(' num2str(istep-tReset) ')'];
        for irep2=1:nReps(2)
            labs2{irep2,icat+nCats*(istep-1)}=curlab;
        end
    end
end
labs2       = labs2(:);
%% labs1
labs1       = cell(nReps(1),nCats);
for icat    = 1:nCats
    curlab  = cats(icat);
    for irep1 = 1:nReps(1)
        labs1{irep1,icat} = curlab;
    end
end
labs1       = labs1(:);

labs{3}     = labs3;
labs{2}     = labs2;
labs{1}     = labs1;



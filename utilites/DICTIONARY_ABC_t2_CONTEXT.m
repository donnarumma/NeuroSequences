function DICTIONARY = DICTIONARY_ABC_t2_CONTEXT()
LETTERS=cell(0,0);
LETTERS{end+1,1}='A'; iL.(LETTERS{end})=length(LETTERS);
LETTERS{end+1,1}='B'; iL.(LETTERS{end})=length(LETTERS);
LETTERS{end+1,1}='C'; iL.(LETTERS{end})=length(LETTERS);
LETTERS{end+1,1}='O'; iL.(LETTERS{end})=length(LETTERS);

SYLLABLES=cell(0,0); D='';
SYLLABLES{end+1,1}  ={LETTERS{iL.A}}; iS.A=length(SYLLABLES);
SYLLABLES{end+1,1}  ={LETTERS{iL.B}}; iS.B=length(SYLLABLES); 
SYLLABLES{end+1,1}  ={LETTERS{iL.C}}; iS.C=length(SYLLABLES);
SYLLABLES{end+1,1}  ={LETTERS{iL.O}}; iS.F=length(SYLLABLES);

WORDS=cell(0,0); D='';
% A
WORDS{end+1,1}          ={SYLLABLES{iS.A},SYLLABLES{iS.B}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.A},SYLLABLES{iS.C}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
% B 
WORDS{end+1,1}          ={SYLLABLES{iS.B},SYLLABLES{iS.A}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.B},SYLLABLES{iS.C}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
% C
WORDS{end+1,1}          ={SYLLABLES{iS.C},SYLLABLES{iS.B}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.C},SYLLABLES{iS.A}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
%
DICTIONARY.STATES       = {   SYLLABLES,     WORDS};
DICTIONARY.OBS          = {     LETTERS, SYLLABLES};
DICTIONARY.CLASSES      = {          [],        []};
DICTIONARY.StateNames   = {'Syllable'       'Word'};
DICTIONARY.ObsNames     = {'Letter'    ,'Syllable'};
DICTIONARY.Word         = WORDS;
DICTIONARY.Syllable     = SYLLABLES;
DICTIONARY.Letter       = LETTERS;
DICTIONARY.NAME         = mfilename;
%
CLASSES         =cell(1,2);
CLASSES{1}{1,1} =[]; % class (time) 1, -> neuron 1
CLASSES{1}{2,1} =[];  % class (time) 2, -> neuron 2
CLASSES{1}{3,1} =[3];  % class (time) 3, -> neuron 3
CLASSES{1}{4,1} =[];  % class (time) 4, -> neuron 4
CLASSES{1}{5,1} =[];  % class (time) 5, -> neuron 5
CLASSES{1}{6,1} =[];  % class (time) 6, -> neuron 6
CLASSES{2}      =[];
DICTIONARY.CLASSES=CLASSES;

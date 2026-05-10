function DICTIONARY = DICTIONARY_ABCDEF_Neutral_2LEV()
LETTERS=cell(0,0);
LETTERS{end+1,1}='A'; iL.(LETTERS{end})=length(LETTERS);
LETTERS{end+1,1}='B'; iL.(LETTERS{end})=length(LETTERS);
LETTERS{end+1,1}='C'; iL.(LETTERS{end})=length(LETTERS);
LETTERS{end+1,1}='D'; iL.(LETTERS{end})=length(LETTERS);
LETTERS{end+1,1}='E'; iL.(LETTERS{end})=length(LETTERS);
LETTERS{end+1,1}='F'; iL.(LETTERS{end})=length(LETTERS);
LETTERS{end+1,1}='G'; iL.(LETTERS{end})=length(LETTERS); %0
LETTERS{end+1,1}='H'; iL.(LETTERS{end})=length(LETTERS); %1
LETTERS{end+1,1}='I'; iL.(LETTERS{end})=length(LETTERS); %2 
LETTERS{end+1,1}='L'; iL.(LETTERS{end})=length(LETTERS); %3
LETTERS{end+1,1}='M'; iL.(LETTERS{end})=length(LETTERS); %4
LETTERS{end+1,1}='N'; iL.(LETTERS{end})=length(LETTERS); %5 
LETTERS{end+1,1}='O'; iL.(LETTERS{end})=length(LETTERS); %6

SYLLABLES=cell(0,0); D='';
SYLLABLES{end+1,1}  ={LETTERS{iL.A},LETTERS{iL.A}}; iS.A=length(SYLLABLES); % iS.(HAI_retrieveLevel(SYLLABLES{end},D))=length(SYLLABLES);
SYLLABLES{end+1,1}  ={LETTERS{iL.B},LETTERS{iL.B}}; iS.B=length(SYLLABLES); % iS.(HAI_retrieveLevel(SYLLABLES{end},D))=length(SYLLABLES);
SYLLABLES{end+1,1}  ={LETTERS{iL.C},LETTERS{iL.C}}; iS.C=length(SYLLABLES); % iS.(HAI_retrieveLevel(SYLLABLES{end},D))=length(SYLLABLES);
SYLLABLES{end+1,1}  ={LETTERS{iL.D},LETTERS{iL.D}}; iS.D=length(SYLLABLES); % iS.(HAI_retrieveLevel(SYLLABLES{end},D))=length(SYLLABLES);
SYLLABLES{end+1,1}  ={LETTERS{iL.E},LETTERS{iL.E}}; iS.E=length(SYLLABLES); % iS.(HAI_retrieveLevel(SYLLABLES{end},D))=length(SYLLABLES);
SYLLABLES{end+1,1}  ={LETTERS{iL.F},LETTERS{iL.F}}; iS.F=length(SYLLABLES); % iS.(HAI_retrieveLevel(SYLLABLES{end},D))=length(SYLLABLES);
SYLLABLES{end+1,1}  ={LETTERS{iL.G},LETTERS{iL.G}}; iS.G=length(SYLLABLES); % iS.(HAI_retrieveLevel(SYLLABLES{end},D))=length(SYLLABLES);
SYLLABLES{end+1,1}  ={LETTERS{iL.H},LETTERS{iL.H}}; iS.H=length(SYLLABLES); % iS.(HAI_retrieveLevel(SYLLABLES{end},D))=length(SYLLABLES);
SYLLABLES{end+1,1}  ={LETTERS{iL.I},LETTERS{iL.I}}; iS.I=length(SYLLABLES); % iS.(HAI_retrieveLevel(SYLLABLES{end},D))=length(SYLLABLES);
SYLLABLES{end+1,1}  ={LETTERS{iL.L},LETTERS{iL.L}}; iS.L=length(SYLLABLES); % iS.(HAI_retrieveLevel(SYLLABLES{end},D))=length(SYLLABLES);
SYLLABLES{end+1,1}  ={LETTERS{iL.M},LETTERS{iL.M}}; iS.M=length(SYLLABLES); % iS.(HAI_retrieveLevel(SYLLABLES{end},D))=length(SYLLABLES);
SYLLABLES{end+1,1}  ={LETTERS{iL.N},LETTERS{iL.N}}; iS.N=length(SYLLABLES); % iS.(HAI_retrieveLevel(SYLLABLES{end},D))=length(SYLLABLES);
SYLLABLES{end+1,1}  ={LETTERS{iL.O},LETTERS{iL.O}}; iS.O=length(SYLLABLES); % iS.(HAI_retrieveLevel(SYLLABLES{end},D))=length(SYLLABLES);

WORDS=cell(0,0); D='';
% A
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.A},SYLLABLES{iS.B},SYLLABLES{iS.C},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.A},SYLLABLES{iS.B},SYLLABLES{iS.D},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.A},SYLLABLES{iS.B},SYLLABLES{iS.E},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.A},SYLLABLES{iS.B},SYLLABLES{iS.F},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);

WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.A},SYLLABLES{iS.C},SYLLABLES{iS.B},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.A},SYLLABLES{iS.C},SYLLABLES{iS.D},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.A},SYLLABLES{iS.C},SYLLABLES{iS.E},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.A},SYLLABLES{iS.C},SYLLABLES{iS.F},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);

WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.A},SYLLABLES{iS.D},SYLLABLES{iS.B},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.A},SYLLABLES{iS.D},SYLLABLES{iS.C},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.A},SYLLABLES{iS.D},SYLLABLES{iS.E},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.A},SYLLABLES{iS.D},SYLLABLES{iS.F},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);

WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.A},SYLLABLES{iS.E},SYLLABLES{iS.B},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.A},SYLLABLES{iS.E},SYLLABLES{iS.C},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.A},SYLLABLES{iS.E},SYLLABLES{iS.D},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.A},SYLLABLES{iS.E},SYLLABLES{iS.F},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);

WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.A},SYLLABLES{iS.F},SYLLABLES{iS.B},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.A},SYLLABLES{iS.F},SYLLABLES{iS.C},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.A},SYLLABLES{iS.F},SYLLABLES{iS.D},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.A},SYLLABLES{iS.F},SYLLABLES{iS.E},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
% B 
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.B},SYLLABLES{iS.A},SYLLABLES{iS.C},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.B},SYLLABLES{iS.A},SYLLABLES{iS.D},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.B},SYLLABLES{iS.A},SYLLABLES{iS.E},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.B},SYLLABLES{iS.A},SYLLABLES{iS.F},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);

WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.B},SYLLABLES{iS.C},SYLLABLES{iS.A},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.B},SYLLABLES{iS.C},SYLLABLES{iS.D},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.B},SYLLABLES{iS.C},SYLLABLES{iS.E},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.B},SYLLABLES{iS.C},SYLLABLES{iS.F},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);

WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.B},SYLLABLES{iS.D},SYLLABLES{iS.A},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.B},SYLLABLES{iS.D},SYLLABLES{iS.C},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.B},SYLLABLES{iS.D},SYLLABLES{iS.E},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.B},SYLLABLES{iS.D},SYLLABLES{iS.F},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);

WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.B},SYLLABLES{iS.E},SYLLABLES{iS.A},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.B},SYLLABLES{iS.E},SYLLABLES{iS.C},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.B},SYLLABLES{iS.E},SYLLABLES{iS.D},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.B},SYLLABLES{iS.E},SYLLABLES{iS.F},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);

WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.B},SYLLABLES{iS.F},SYLLABLES{iS.A},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.B},SYLLABLES{iS.F},SYLLABLES{iS.C},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.B},SYLLABLES{iS.F},SYLLABLES{iS.D},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.B},SYLLABLES{iS.F},SYLLABLES{iS.E},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
% C
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.C},SYLLABLES{iS.A},SYLLABLES{iS.B},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.C},SYLLABLES{iS.A},SYLLABLES{iS.D},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.C},SYLLABLES{iS.A},SYLLABLES{iS.E},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.C},SYLLABLES{iS.A},SYLLABLES{iS.F},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);

WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.C},SYLLABLES{iS.B},SYLLABLES{iS.A},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.C},SYLLABLES{iS.B},SYLLABLES{iS.D},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.C},SYLLABLES{iS.B},SYLLABLES{iS.E},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.C},SYLLABLES{iS.B},SYLLABLES{iS.F},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);

WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.C},SYLLABLES{iS.D},SYLLABLES{iS.A},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.C},SYLLABLES{iS.D},SYLLABLES{iS.B},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.C},SYLLABLES{iS.D},SYLLABLES{iS.E},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.C},SYLLABLES{iS.D},SYLLABLES{iS.F},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);

WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.C},SYLLABLES{iS.E},SYLLABLES{iS.A},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.C},SYLLABLES{iS.E},SYLLABLES{iS.B},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.C},SYLLABLES{iS.E},SYLLABLES{iS.D},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.C},SYLLABLES{iS.E},SYLLABLES{iS.F},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);

WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.C},SYLLABLES{iS.F},SYLLABLES{iS.A},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.C},SYLLABLES{iS.F},SYLLABLES{iS.B},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.C},SYLLABLES{iS.F},SYLLABLES{iS.D},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.C},SYLLABLES{iS.F},SYLLABLES{iS.E},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
% D
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.D},SYLLABLES{iS.A},SYLLABLES{iS.B},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.D},SYLLABLES{iS.A},SYLLABLES{iS.C},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.D},SYLLABLES{iS.A},SYLLABLES{iS.E},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.D},SYLLABLES{iS.A},SYLLABLES{iS.F},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);

WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.D},SYLLABLES{iS.B},SYLLABLES{iS.A},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.D},SYLLABLES{iS.B},SYLLABLES{iS.C},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.D},SYLLABLES{iS.B},SYLLABLES{iS.E},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.D},SYLLABLES{iS.B},SYLLABLES{iS.F},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);

WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.D},SYLLABLES{iS.C},SYLLABLES{iS.A},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.D},SYLLABLES{iS.C},SYLLABLES{iS.B},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.D},SYLLABLES{iS.C},SYLLABLES{iS.E},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.D},SYLLABLES{iS.C},SYLLABLES{iS.F},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);

WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.D},SYLLABLES{iS.E},SYLLABLES{iS.A},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.D},SYLLABLES{iS.E},SYLLABLES{iS.B},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.D},SYLLABLES{iS.E},SYLLABLES{iS.C},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.D},SYLLABLES{iS.E},SYLLABLES{iS.F},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);

WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.D},SYLLABLES{iS.F},SYLLABLES{iS.A},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.D},SYLLABLES{iS.F},SYLLABLES{iS.B},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.D},SYLLABLES{iS.F},SYLLABLES{iS.C},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.D},SYLLABLES{iS.F},SYLLABLES{iS.E},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
% E
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.E},SYLLABLES{iS.A},SYLLABLES{iS.B},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.E},SYLLABLES{iS.A},SYLLABLES{iS.C},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.E},SYLLABLES{iS.A},SYLLABLES{iS.D},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.E},SYLLABLES{iS.A},SYLLABLES{iS.F},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);

WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.E},SYLLABLES{iS.B},SYLLABLES{iS.A},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.E},SYLLABLES{iS.B},SYLLABLES{iS.C},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.E},SYLLABLES{iS.B},SYLLABLES{iS.D},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.E},SYLLABLES{iS.B},SYLLABLES{iS.F},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);

WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.E},SYLLABLES{iS.C},SYLLABLES{iS.A},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.E},SYLLABLES{iS.C},SYLLABLES{iS.B},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.E},SYLLABLES{iS.C},SYLLABLES{iS.D},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.E},SYLLABLES{iS.C},SYLLABLES{iS.F},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);

WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.E},SYLLABLES{iS.D},SYLLABLES{iS.A},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.E},SYLLABLES{iS.D},SYLLABLES{iS.B},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.E},SYLLABLES{iS.D},SYLLABLES{iS.C},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.E},SYLLABLES{iS.D},SYLLABLES{iS.F},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);

WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.E},SYLLABLES{iS.F},SYLLABLES{iS.A},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.E},SYLLABLES{iS.F},SYLLABLES{iS.B},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.E},SYLLABLES{iS.F},SYLLABLES{iS.C},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.E},SYLLABLES{iS.F},SYLLABLES{iS.D},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
% F
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.F},SYLLABLES{iS.A},SYLLABLES{iS.B},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.F},SYLLABLES{iS.A},SYLLABLES{iS.C},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.F},SYLLABLES{iS.A},SYLLABLES{iS.D},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.F},SYLLABLES{iS.A},SYLLABLES{iS.E},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);

WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.F},SYLLABLES{iS.B},SYLLABLES{iS.A},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.F},SYLLABLES{iS.B},SYLLABLES{iS.C},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.F},SYLLABLES{iS.B},SYLLABLES{iS.D},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.F},SYLLABLES{iS.B},SYLLABLES{iS.E},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);

WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.F},SYLLABLES{iS.C},SYLLABLES{iS.A},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.F},SYLLABLES{iS.C},SYLLABLES{iS.B},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.F},SYLLABLES{iS.C},SYLLABLES{iS.D},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.F},SYLLABLES{iS.C},SYLLABLES{iS.E},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);

WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.F},SYLLABLES{iS.D},SYLLABLES{iS.A},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.F},SYLLABLES{iS.D},SYLLABLES{iS.B},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.F},SYLLABLES{iS.D},SYLLABLES{iS.C},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.F},SYLLABLES{iS.D},SYLLABLES{iS.E},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);

WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.F},SYLLABLES{iS.E},SYLLABLES{iS.A},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.F},SYLLABLES{iS.E},SYLLABLES{iS.B},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.F},SYLLABLES{iS.E},SYLLABLES{iS.C},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.F},SYLLABLES{iS.E},SYLLABLES{iS.D},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
% seq 2 starting with A
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.A},SYLLABLES{iS.B},SYLLABLES{iS.G},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.A},SYLLABLES{iS.C},SYLLABLES{iS.G},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.A},SYLLABLES{iS.D},SYLLABLES{iS.G},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.A},SYLLABLES{iS.E},SYLLABLES{iS.G},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);
WORDS{end+1,1}          ={SYLLABLES{iS.G},SYLLABLES{iS.A},SYLLABLES{iS.F},SYLLABLES{iS.G},SYLLABLES{iS.H}}; iS.(HAI_retrieveLevel(WORDS{end},D))=length(WORDS);


DICTIONARY.STATES       = {   SYLLABLES,     WORDS};
DICTIONARY.OBS          = {     LETTERS, SYLLABLES};
DICTIONARY.CLASSES      = {          [],        []};
DICTIONARY.StateNames   = {'Syllable'       'Word'};
DICTIONARY.ObsNames     = {'Letter'    ,'Syllable'};
DICTIONARY.Word         = WORDS;
DICTIONARY.Syllable     = SYLLABLES;
DICTIONARY.Letter       = LETTERS;
DICTIONARY.NAME         = mfilename;

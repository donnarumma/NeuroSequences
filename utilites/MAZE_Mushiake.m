function out = MAZE_Mushiake(transMode)
%MAZE_MUSHIAKE Build one constrained Mushiake maze and its deterministic transitions.

% rectangular MAZE
MAZE = [...
        0 1 1 1 0;
        1 1 1 1 1;
        1 1 1 1 1;
        1 1 1 1 1;
        0 1 1 1 0;
        ];

[nRows, nCols]          = size(MAZE);
% Actions: [up down left right]
% 1 = open transition, 0 = closed transition
transitions             = ones(nRows, nCols, 4);

% Example (manual configuration):
if     transMode==1
    transitions(3,3,:)      = [1 1 0 0];  % state (3,3): open   up and down
    transitions(1,1,:)      = [0 0 0 0];  % state (1,1): close all
    transitions(1,5,:)      = [0 0 0 0];  % state (1,5): close all
    transitions(5,1,:)      = [0 0 0 0];  % state (5,1): close all
    transitions(5,5,:)      = [0 0 0 0];  % state (5,5): close all
elseif transMode==2
    transitions(3,3,:)      = [0 0 1 1];  % state (3,3): open left and right
    transitions(1,1,:)      = [0 0 0 0];  % state (1,1): close all
    transitions(1,5,:)      = [0 0 0 0];  % state (1,5): close all
    transitions(5,1,:)      = [0 0 0 0];  % state (5,1): close all
    transitions(5,5,:)      = [0 0 0 0];  % state (5,5): close all
elseif transMode==3
    transitions(3,2,:)      = [0 0 1 1];  % state (1,1): open left and right
    transitions(3,4,:)      = [0 0 1 1];  % state (1,1): open left and right
    transitions(1,1,:)      = [0 0 0 0];  % state (1,1): close all
    transitions(1,5,:)      = [0 0 0 0];  % state (1,5): close all
    transitions(5,1,:)      = [0 0 0 0];  % state (5,1): close all
    transitions(5,5,:)      = [0 0 0 0];  % state (5,5): close all
end

transitions             = HAI_makeTransitionsSymmetric(transitions);

% convert to one dimensional transitions, with a unique id
% map2D the remapping
[transitions1D,map2D]   = HAI_convertTransitionsTo1D(MAZE, transitions);

[StatesB, ActionsB]     = mushiake_compute_transition_probabilities(transitions1D, map2D, 1);
out.MAZE                = MAZE;
out.transitions         = transitions;
out.transitions1D       = transitions1D;
out.map2D               = map2D;
out.StatesB             = StatesB;
out.ActionsB            = ActionsB;

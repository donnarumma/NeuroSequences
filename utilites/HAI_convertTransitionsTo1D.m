function   [transitions1D, state_map] = HAI_convertTransitionsTo1D(MAZE, transitions)
% function [transitions1D, state_map] = HAI_convertTransitionsTo1D(MAZE, transitions)
% Converts a 2D maze state-transition representation to a 1D enumerated state representation
%
% Inputs:
%   MAZE: binary matrix indicating valid (1) and blocked (0) states
%   transitions: (nRows x nCols x 4) transitions matrix
%
% Outputs:
%   transitions1D: (nStates x nStates) adjacency matrix
%   state_map: mapping from 2D (row,col) coordinates to enumerated state indices

[nRows, nCols, nActions]   = size(transitions);

state_map           = zeros(nRows, nCols);

% Map valid states
for iRow = 1:nRows
    for iCol = 1:nCols
        if MAZE(iRow,iCol) == 1
            state_map(iRow,iCol) = sum(MAZE(1:(iRow-1),:),'all') + sum(MAZE(iRow,1:iCol));
        end
    end
end

nStates         = max(state_map(:));
transitions1D   = zeros(nStates);

% Directions [up down left right]
dRow            = [-1,1, 0,0];
dCol            = [ 0,0,-1,1];

for iRow = 1:nRows
    for iCol = 1:nCols
        if state_map(iRow,iCol)==0, continue; end
        current_state = state_map(iRow,iCol);

        for iDir=1:nActions
            nr = iRow + dRow(iDir);
            nc = iCol + dCol(iDir);
            if nr >= 1 && nr <= nRows && nc >= 1 && nc <= nCols && state_map(nr,nc) > 0
                if transitions(iRow,iCol,iDir)
                    neigh_State      = state_map(nr,nc);
                    transitions1D(current_state,neigh_State) = 1;
                end
            end
        end
    end
end

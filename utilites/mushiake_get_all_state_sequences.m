function [action_sequence, state_sequence] = mushiake_get_all_state_sequences(transitions1D, start_state, K, state_map)
%MUSHIAKE_GET_ALL_STATE_SEQUENCES Enumerate valid maze paths with consistent action codes.

state_coords = build_state_coordinates(state_map);

[state_sequence, action_sequence] = explore_paths(transitions1D, start_state, K, [start_state], [], state_coords);
end

function [seqStates, seqActions] = explore_paths(T, current, stepsLeft, path, actions, state_coords)
if stepsLeft == 0
    seqStates = path';
    seqActions = actions';
    return;
end

seqStates = [];
seqActions = [];

next_states = find(T(current, :) > 0);
next_states = setdiff(next_states, path);

for ns = next_states
    action = transition_to_action(state_coords(current, :), state_coords(ns, :));
    [newSeqStates, newSeqActions] = explore_paths(T, ns, stepsLeft - 1, [path, ns], [actions, action], state_coords);
    seqStates = [seqStates, newSeqStates]; %#ok<AGROW>
    seqActions = [seqActions, newSeqActions]; %#ok<AGROW>
end
end

function action = transition_to_action(current_coord, next_coord)
% Use the same row/column convention as the deterministic maze B matrix.
rowDelta = next_coord(1) - current_coord(1);
colDelta = next_coord(2) - current_coord(2);

if rowDelta == -1 && colDelta == 0
    action = 1; % up
elseif rowDelta == 1 && colDelta == 0
    action = 2; % down
elseif rowDelta == 0 && colDelta == -1
    action = 3; % left
elseif rowDelta == 0 && colDelta == 1
    action = 4; % right
else
    action = 0;
end
end

function state_coords = build_state_coordinates(state_map)
% Map each 1D state id back to its [row, col] position in the maze.

nStates = max(state_map(:));
state_coords = zeros(nStates, 2);

for iRow = 1:size(state_map, 1)
    for iCol = 1:size(state_map, 2)
        stateId = state_map(iRow, iCol);
        if stateId == 0
            continue;
        end
        state_coords(stateId, :) = [iRow, iCol];
    end
end
end

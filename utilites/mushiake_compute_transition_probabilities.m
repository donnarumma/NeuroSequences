function [nextStateProb, nextActionProb] = mushiake_compute_transition_probabilities(transitions1D, state_map, addstay)
%MUSHIAKE_COMPUTE_TRANSITION_PROBABILITIES Build deterministic maze B factors.

nActions = 4; % [up down left right]
if addstay
    nActions = nActions + 1; % add stay
end

[nStates, ~] = size(transitions1D);
nextStateProb = zeros(nStates, nStates, nActions);

% Directions [up down left right]
dRow = [-1, 1, 0, 0];
dCol = [0, 0, -1, 1];
[nRows, nCols] = size(state_map);

for iRow = 1:nRows
    for iCol = 1:nCols
        currentState = state_map(iRow, iCol);
        if currentState == 0
            continue;
        end

        for currentAction = 1:4
            nr = iRow + dRow(currentAction);
            nc = iCol + dCol(currentAction);
            if nr < 1 || nr > nRows || nc < 1 || nc > nCols
                continue;
            end

            nextState = state_map(nr, nc);
            if nextState > 0 && transitions1D(currentState, nextState)
                nextStateProb(nextState, currentState, currentAction) = 1;
            end
        end
    end
end

if addstay
    for iState = 1:nStates
        nextStateProb(iState, iState, nActions) = 1;
    end
end

for currentState = 1:nStates
    for currentAction = 1:nActions
        total = sum(nextStateProb(:, currentState, currentAction));
        if total > 0
            nextStateProb(:, currentState, currentAction) = ...
                nextStateProb(:, currentState, currentAction) / total;
        else
            % Invalid maze actions keep the agent in place instead of
            % introducing a uniform transition over all states.
            nextStateProb(currentState, currentState, currentAction) = 1;
        end
    end
end

nextActionProb = zeros(nActions, nActions, nActions) + eps;
for nextActionState = 1:nActions
    for currentAction = 1:nActions
        if nextActionState == currentAction
            nextActionProb(nextActionState, :, currentAction) = 1;
        end
    end
end

for currentActionState = 1:nActions
    for currentAction = 1:nActions
        total = sum(nextActionProb(:, currentActionState, currentAction));
        if total > 0
            nextActionProb(:, currentActionState, currentAction) = ...
                nextActionProb(:, currentActionState, currentAction) / total;
        end
    end
end
end

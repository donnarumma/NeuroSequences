function B = build_transition_matrices( ...
    goTransitions, targetTransitions, typeIndexPerTask, nTypes, nEffectiveTypes)
%BUILD_TRANSITION_MATRICES Assemble the hidden-state transition model B.
%
% B{1}: transitions over latent GoToTarget/action states
% B{2}: transitions over latent target states unfolded over time
% B{3}: transitions over latent sequence type/order
%
% The final type state is reserved for the initial unknown-type state ('idk').

taskCount = size(goTransitions, 3);

B = cell(1, 3);
B{1} = goTransitions;
B{2} = targetTransitions;

% Type factor:
% for each policy/task, the transition dynamics force the model toward the
% type consistent with that task. The last state is reserved for 'idk'.
B{3} = zeros(nTypes, nTypes, taskCount) + eps;
for typeIndex = 1:nEffectiveTypes
    B{3}(typeIndex, :, typeIndexPerTask == typeIndex) = 1;
end
end

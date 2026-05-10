function A = build_likelihood_matrices( ...
    pms, nObs, nGoToTargets, nTargets, nTypes, nSteps, typeInfo)
%BUILD_LIKELIHOOD_MATRICES Assemble the observation model A.
%
% A{1}: observation of GoToTarget (action) states
%       - directional actions (1:nDirs) are noisy with confusion across
%         neighboring directions
%       - neutral/end states are deterministic
%
% A{2}: observation of Target states (expanded in time)
%       - each target is represented as (target × timestep), e.g. A3
%       - confusion occurs across neighboring targets at same timestep
%       - auxiliary/delay states are deterministic
%
% A{3}: observation of Type (fw, bw, ...)
%       - deterministic mapping

A = cell(1, 3);

% =====================================================================
% PARAMETERS
% =====================================================================
mainProbGoToTargets = 1;
mainProbTargets     = 1;

if isfield(pms, 'mainProb')
    if numel(pms.mainProb) >= 1
        mainProbGoToTargets = pms.mainProb(1);
    end
    if numel(pms.mainProb) >= 2
        mainProbTargets = pms.mainProb(2);
    end
end

sideProbGoToTargets = (1 - mainProbGoToTargets) / 2;
if sideProbGoToTargets == 0
    sideProbGoToTargets = eps;
end

sideProbTargets = (1 - mainProbTargets) / 2;
if sideProbTargets == 0
    sideProbTargets = eps;
end

% =====================================================================
% A{1} : GoToTarget observation
% =====================================================================
A{1} = zeros(nObs(1), nGoToTargets, nTargets, nTypes) + eps;

% Directional targets (circular confusion)
for i = 1:pms.nDirs
    left  = mod(i - 2, pms.nDirs) + 1;
    right = mod(i,     pms.nDirs) + 1;

    A{1}(i,     i, :, :) = mainProbGoToTargets;
    A{1}(left,  i, :, :) = sideProbGoToTargets;
    A{1}(right, i, :, :) = sideProbGoToTargets;
end

% Neutral / terminal states → deterministic
for i = (pms.nDirs + 1):nGoToTargets
    A{1}(i, i, :, :) = 1;
end

% =====================================================================
% A{2} : Target observation (expanded target × time)
% =====================================================================
A{2} = zeros(nObs(2), nGoToTargets, nTargets, nTypes) + eps;

% Expanded structure:
% index = (target_id - 1)*nSteps + timestep

for iTarget = 1:(pms.nDirs * nSteps)

    t  = mod(iTarget - 1, nSteps) + 1;
    id = floor((iTarget - 1) / nSteps) + 1;

    left_id  = mod(id - 2, pms.nDirs) + 1;
    right_id = mod(id,     pms.nDirs) + 1;

    center = (id - 1)      * nSteps + t;
    left   = (left_id - 1) * nSteps + t;
    right  = (right_id - 1)* nSteps + t;

    A{2}(center, :, center, :) = mainProbTargets;
    A{2}(center, :, left,   :) = sideProbTargets;
    A{2}(center, :, right,  :) = sideProbTargets;
end

% Auxiliary (delay / neutral target states)
for i = (pms.nDirs * nSteps + 1):nTargets
    A{2}(i, :, i, :) = 1;
end

% =====================================================================
% A{3} : Type observation
% =====================================================================
A{3} = zeros(nObs(3), nGoToTargets, nTargets, nTypes) + eps;

for i = 1:(nTypes - 1)
    A{3}(i, :, :, i) = 1;
end

% last state = idk
A{3}(nTypes, :, :, nTypes) = 1;

% Warning if no directional types
if isempty(typeInfo.forwardTypeIndex) && isempty(typeInfo.backwardTypeIndex)
    warning('%s:NoDirectionalCue', mfilename, ...
        'No fw/bw types available in the observation model.');
end
end

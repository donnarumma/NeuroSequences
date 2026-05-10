function [childMDP, callInfo] = vb_infer_lower_level(mdp, OPTIONS, mode, runnerHandle)
% Externalised lower-level call so SPM-style and fork-style recursion can be
% compared explicitly.

if nargin < 3 || isempty(mode)
    mode = 'fork';
end

if nargin < 4 || isempty(runnerHandle)
    switch lower(mode)
        case 'spm'
            runnerHandle = str2func('spm_MDP_VB_X');
        otherwise
            runnerHandle = str2func('VB_MDP_X');
    end
end

callInfo = vb_describe_lower_level_call(mdp, OPTIONS, runnerHandle);

switch lower(mode)
    case 'spm'
        childMDP = runnerHandle(mdp);
    case 'fork'
        childMDP = runnerHandle(mdp, OPTIONS);
    otherwise
        error('vb_infer_lower_level:UnknownMode', ...
            'Unknown lower-level mode "%s". Use "spm" or "fork".', mode);
end

function varargout = VB_MDP_C(command, varargin)
% VB_MDP_C
% Modular controller for exploring hierarchical MDP calls from the outside.
%
% This does not replace the original SPM runner. Instead, it exposes the
% lower-level preparation/call/integration steps explicitly so levels can be
% launched from outside without recursive calls in the controller layer.
%
% Usage:
%   session = VB_MDP_C('initialize', mdp, OPTIONS)
%   info    = VB_MDP_C('describe_lower', mdpLower, OPTIONS, runnerHandle)
%   [childMDP, Orow, info] = VB_MDP_C('prepare_lower', parentMDP, iTime, A_lk, xq, Orow)
%   [childMDP, callInfo]   = VB_MDP_C('infer_lower', mdpLower, OPTIONS, mode, runnerHandle)
%   [parentMDP, Orow, info]= VB_MDP_C('integrate_lower', parentMDP, childMDP, Orow, iTime)
%   session = VB_MDP_C('advance_time', session)

switch lower(command)
    case 'initialize'
        varargout{1} = local_initialize(varargin{:});
    case 'describe_lower'
        varargout{1} = vb_describe_lower_level_call(varargin{:});
    case 'prepare_lower'
        [varargout{1:nargout}] = vb_prepare_lower_level_mdp(varargin{:});
    case 'infer_lower'
        [varargout{1:nargout}] = vb_infer_lower_level(varargin{:});
    case 'integrate_lower'
        [varargout{1:nargout}] = vb_integrate_lower_level_outcomes(varargin{:});
    case 'advance_time'
        varargout{1} = local_advance_time(varargin{:});
    otherwise
        error('VB_MDP_C:UnknownCommand', ...
            'Unknown command "%s".', command);
end

function session = local_initialize(mdp, OPTIONS, varargin)
session = struct();
session.MDP = mdp;
session.OPTIONS = OPTIONS;
session.currentTime = 1;
session.TimeHorizon = local_get_time_horizon(mdp);
session.mode = 'spm';
session.runnerHandle = local_default_runner(OPTIONS);
session.history = struct( ...
    'preparedLower', {{}}, ...
    'callInfo', {{}}, ...
    'integrated', {{}});

if ~isempty(varargin)
    for iArg = 1:2:numel(varargin)
        key = varargin{iArg};
        value = varargin{iArg + 1};
        switch lower(key)
            case 'mode'
                session.mode = value;
            case 'runnerhandle'
                session.runnerHandle = value;
            case 'currenttime'
                session.currentTime = value;
            otherwise
                error('VB_MDP_C:UnknownOption', ...
                    'Unknown initialize option "%s".', key);
        end
    end
end

function session = local_advance_time(session, varargin)
step = 1;
if ~isempty(varargin)
    step = varargin{1};
end
session.currentTime = min(session.currentTime + step, session.TimeHorizon);

function runnerHandle = local_default_runner(OPTIONS)
if isstruct(OPTIONS) && isfield(OPTIONS, 'spm_MDP_VB_H')
    runnerHandle = OPTIONS.spm_MDP_VB_H;
else
    runnerHandle = str2func('spm_MDP_VB_X');
end

function nTimes = local_get_time_horizon(mdp)
if isfield(mdp, 'V') && ~isempty(mdp.V)
    nTimes = size(mdp.V, 1) + 1;
elseif isfield(mdp, 'U') && ~isempty(mdp.U)
    nTimes = size(mdp.U, 1) + 1;
elseif isfield(mdp, 'T') && ~isempty(mdp.T)
    nTimes = mdp.T;
else
    nTimes = 1;
end

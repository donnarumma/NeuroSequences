function par = plotNeuronPolarByConditionParams(parSource)
% plotNeuronPolarByConditionParams
% Defaults for plotNeuronPolarByCondition.
%
% PARAMETERS
%   TypeField       : field containing one-hot condition labels.
%   DataField       : field containing neural data, e.g. 'Spikes'.
%   TimeField       : field containing time vector matched to DataField.
%   TimeWindow      : [tMin tMax] interval for averaging. Empty = all times.
%   ErrorType       : 'none', 'sem', or 'std'.
%   RLimits         : radial limits, e.g. [0 1]. Empty = automatic.
%   Normalize       : whether to normalize mean response to max = 1.
%   Ax              : existing polaraxes. Empty = create new figure.
%   Visible         : 'on' or 'off'.
%   FontSize        : title/tick font size.
%   LineWidth       : tuning curve line width.
%   MarkerSize      : marker size.
%   ShowTitle       : whether to show title.
%   ShowGrid        : whether to show polar grid.
%   ConditionLabels : custom condition labels. Empty = 1:nCond.
%   FigurePosition  : figure position in pixels.
%   DoSave          : whether to save figure.
%   SaveDir         : folder for saving.
%   FigurePrefix    : filename/title prefix.

par.TypeField       = 'type1';
par.DataField       = 'Spikes';
par.TimeField       = 'timeSpikes';
par.TimeWindow      = [];
par.ErrorType       = 'none';   % 'none' | 'sem' | 'std'
par.RLimits         = [];
par.Normalize       = false;

par.Ax              = [];
par.Visible         = 'on';
par.FontSize        = 8;
par.LineWidth       = 1.5;
par.MarkerSize      = 4;
par.ShowTitle       = true;
par.ShowGrid        = true;
par.ConditionLabels = [];

par.FigurePosition  = [100 100 500 450];
par.DoSave          = false;
par.SaveDir         = '';
par.FigurePrefix    = 'NeuronPolar';

if nargin < 1 || isempty(parSource)
    return;
end

fieldNames = fieldnames(parSource);
for fieldIndex = 1:numel(fieldNames)
    par.(fieldNames{fieldIndex}) = parSource.(fieldNames{fieldIndex});
end
end
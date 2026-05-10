function h = tileNeuronPolarByTypes(sampleTrials, neuronIdxList, typeFields, pms, varargin)
% tileNeuronPolarByTypes
% Tile polar plots for multiple neurons and multiple type fields.
%
% h = tileNeuronPolarByTypes(sampleTrials, neuronIdxList, typeFields, pms, varargin)
%
% PARAMETERS
%   Uses plotNeuronPolarByConditionParams defaults.
%   Precedence:
%       defaults < pms struct < name-value pairs
%
% EXAMPLE
%   pms = plotNeuronPolarByConditionParams();
%   pms.DataField  = 'Spikes';
%   pms.TimeField  = 'timeSpikes';
%   pms.TimeWindow = [0.9 1];
%   pms.ErrorType  = 'sem';
%   pms.RLimits    = [0 1];
%
%   h = tileNeuronPolarByTypes(sampleTrials, 1:6, ...
%       {'type1','type2','type3'}, pms);

if nargin < 4
    pms = struct();
end

pms = plotNeuronPolarByConditionParams(pms);

for i = 1:2:numel(varargin)
    pms.(varargin{i}) = varargin{i+1};
end

nNeurons = numel(neuronIdxList);
nTypes   = numel(typeFields);

h = struct();
h.fig = figure('Color','w', ...
    'Visible', pms.Visible, ...
    'Position', pms.FigurePosition);

h.tl = tiledlayout(nNeurons, nTypes, ...
    'TileSpacing','compact', ...
    'Padding','compact');

h.ax = gobjects(nNeurons, nTypes);
h.plot = cell(nNeurons, nTypes);

for iN = 1:nNeurons
    neuronIdx = neuronIdxList(iN);

    for iT = 1:nTypes
        ax                  = polaraxes(h.tl);
        ax.Layout.Tile      = (iN-1)*nTypes + iT;

        pmsLocal            = pms;
        pmsLocal.Ax         = ax;
        pmsLocal.TypeField  = typeFields{iT};

        % Avoid saving each single subplot separately from the inner function
        pmsLocal.DoSave = false;

        h.ax(iN,iT)     = ax;
        h.plot{iN,iT}   = plotNeuronPolarByCondition( ...
            sampleTrials, neuronIdx, pmsLocal);
    end
end

% Optional global title
if isfield(pms, 'TileTitle') && ~isempty(pms.TileTitle)
    title(h.tl, pms.TileTitle, 'Interpreter','none', ...
        'FontSize', pms.FontSize + 2);
end

% Optional save for whole tiled figure
h.files = {};

if pms.DoSave
    if isempty(pms.SaveDir)
        pms.SaveDir = pwd;
    end
    if ~exist(pms.SaveDir, 'dir')
        mkdir(pms.SaveDir);
    end

    fname = fullfile(pms.SaveDir, sprintf('%s_tilePolar.png', pms.FigurePrefix));
    exportgraphics(h.fig, fname, 'Resolution', 300);
    h.files{1} = fname;
end
end
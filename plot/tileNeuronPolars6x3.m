function h = tileNeuronPolars6x3(sampleTrials, neuronIdxList, typeFields, pms, varargin)
% tileNeuronPolars6x3
% Tile 18 neuron polar plots into a fixed 6x3 layout.
%
% h = tileNeuronPolars6x3(sampleTrials, neuronIdxList, typeFields, pms, varargin)
%
% INPUTS
%   sampleTrials   collected trial struct array
%   neuronIdxList  18 neuron indices
%   typeFields     18 type-field names, one for each neuron slot
%   pms            plotNeuronPolarByConditionParams-compatible struct
%
% LAYOUT
%   Slots 1:6   -> first column
%   Slots 7:12  -> second column
%   Slots 13:18 -> third column

if nargin < 4
    pms = struct();
end

pms = plotNeuronPolarByConditionParams(pms);

for i = 1:2:numel(varargin)
    pms.(varargin{i}) = varargin{i+1};
end

if numel(neuronIdxList) ~= 18
    error('%s:InvalidNeuronCount', mfilename, ...
        'neuronIdxList must contain exactly 18 indices.');
end

if numel(typeFields) ~= 18
    error('%s:InvalidTypeCount', mfilename, ...
        'typeFields must contain exactly 18 entries.');
end

h = struct();
h.fig = figure('Color', 'w', ...
    'Visible', pms.Visible, ...
    'Position', pms.FigurePosition);

h.tl = tiledlayout(6, 3, ...
    'TileSpacing', 'compact', ...
    'Padding', 'compact');

h.ax = gobjects(6, 3);
h.plot = cell(6, 3);

for iSlot = 1:18
    iRow = mod(iSlot - 1, 6) + 1;
    iCol = floor((iSlot - 1) / 6) + 1;
    tileIndex = (iRow - 1) * 3 + iCol;

    ax = polaraxes(h.tl);
    ax.Layout.Tile = tileIndex;

    pmsLocal = pms;
    pmsLocal.Ax = ax;
    pmsLocal.TypeField = typeFields{iSlot};
    pmsLocal.DoSave = false;

    h.ax(iRow, iCol) = ax;
    h.plot{iRow, iCol} = plotNeuronPolarByCondition( ...
        sampleTrials, neuronIdxList(iSlot), pmsLocal);
end

if isfield(pms, 'TileTitle') && ~isempty(pms.TileTitle)
    title(h.tl, pms.TileTitle, 'Interpreter', 'none', ...
        'FontSize', pms.FontSize + 2);
end

h.files = {};

if pms.DoSave
    if isempty(pms.SaveDir)
        pms.SaveDir = pwd;
    end
    if ~exist(pms.SaveDir, 'dir')
        mkdir(pms.SaveDir);
    end

    fname = fullfile(pms.SaveDir, sprintf('%s_tilePolar6x3.png', pms.FigurePrefix));
    exportgraphics(h.fig, fname, 'Resolution', 300);
    h.files{1} = fname;
end
end

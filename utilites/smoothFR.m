function [FR_out, W, meta] = smoothFR(FR, V, neu, opts)
%SMOOTH_FR_WITH_INCREASING_WINDOW
% Smooth N x T firing rates using an increasing (ramp) window derived from a
% binary mask V, selecting neurons via neu.
%
% INPUTS
%   FR   : (N x T) matrix of firing rates or counts
%   V    : (1 x T) logical or 0/1 mask defining the "active" region(s)
%   neu  : (N x 1) logical or 0/1 neuron selector; [] => all neurons
%   opts : struct (all optional)
%       .extendLR     = [1 1]   % extend the contiguous 1-runs by L samples on the left
%                               % and R samples on the right (e.g., 1→ previous index, 1→ next)
%       .winShape     = 'linear'% 'linear' | 'halfcos' (shape of the increasing window)
%       .fillOutside  = 'keep'  % 'keep' | 'nan' | 'zero' (values outside extended segments)
%       .norm.type    = 'none'  % 'none' | 'zscore' | 'minmax' | 'demean'
%       .norm.useMask = true    % compute normalization stats only inside extended segments
%       .keepAllNeurons = false % keep unselected neurons (rows) unchanged (true) or drop (false)
%
% OUTPUTS
%   FR_out : processed FR (size depends on keepAllNeurons)
%   W      : (1 x T) composite window (0 outside, increasing in each extended segment)
%   meta   : struct with details (segments, indices, window lengths, etc.)
%
% Example:
%   V = [0 0 0 1 1 1 1 0 0 0 0];
%   -> extended segment = 3:8 when extendLR = [1 1]
%
% Author: Francesco Donnarumma
% -------------------------------------------------------------------------

    % ---------- defaults ----------
    if nargin < 4 || isempty(opts), opts = struct(); end
    if ~isfield(opts, 'extendLR')     || isempty(opts.extendLR),     opts.extendLR     = [1 1]; end
    if ~isfield(opts, 'winShape')     || isempty(opts.winShape),     opts.winShape     = 'linear'; end
    if ~isfield(opts, 'fillOutside')  || isempty(opts.fillOutside),  opts.fillOutside  = 'keep'; end
    if ~isfield(opts, 'norm')         || isempty(opts.norm),         opts.norm         = struct(); end
    if ~isfield(opts.norm, 'type')    || isempty(opts.norm.type),    opts.norm.type    = 'none'; end
    if ~isfield(opts.norm, 'useMask') || isempty(opts.norm.useMask), opts.norm.useMask = true; end
    if ~isfield(opts, 'keepAllNeurons') || isempty(opts.keepAllNeurons), opts.keepAllNeurons = false; end
    [N, T] = size(FR);
    if nargin < 3 || isempty(neu), neu = true(N,1); end
    neu = logical(neu(:));
    V   = logical(V(:)).';  % row

    % Select neurons
    idx_neu = find(neu);
    FR_sel  = FR(idx_neu, :);

    % Find contiguous 1-runs in V
    segs1 = contiguous_segments(V);  % [start end] indices where V==1
    % Extend each run by opts.extendLR = [L R]
    Lext = opts.extendLR(1);
    Rext = opts.extendLR(2);
    segs = zeros(size(segs1));
    for k = 1:size(segs1,1)
        segs(k,1) = max(1, segs1(k,1) - Lext);
        segs(k,2) = min(T, segs1(k,2) + Rext);
    end

    % Build composite window W (0 outside; in each segment: strictly increasing 0->1)
    W = zeros(1, T);
    for k = 1:size(segs,1)
        idx = segs(k,1):segs(k,2);
        L   = numel(idx);
        switch lower(opts.winShape)
            case 'linear'
                wseg = linspace(0, 1, L);  % strictly increasing
            case 'halfcos'
                wseg = 0.5 * (1 - cos(linspace(0, pi, L)));
            otherwise
                error('Unknown winShape: %s', opts.winShape);
        end
        % If segments overlap, keep the maximum contribution
        W(idx) = max(W(idx), wseg);
    end

    % Ramp-based smoothing: convolve inside each extended segment with a normalized
    % increasing kernel that matches that segment's length. No leakage across segments.
    FR_s = FR_sel;
    for k = 1:size(segs,1)
        idx = segs(k,1):segs(k,2);
        L   = numel(idx);
        switch lower(opts.winShape)
            case 'linear'
                ker = (1:L);  % increasing weights
            case 'halfcos'
                ker = 0.5 * (1 - cos(linspace(0, pi, L)));
                % shift to strictly increasing (ensure last > first)
                if ker(1) == ker(end), ker = ker + linspace(0, 1e-6, L); end
            otherwise
                error('Unknown winShape: %s', opts.winShape);
        end
        ker = ker / sum(ker); % normalize
        FR_s(:, idx) = conv2(FR_sel(:, idx), ker, 'same');   % along time only ker is 1xL row vector
    end

    % Outside-mask handling
    switch lower(opts.fillOutside)
        case 'nan'
            % set outside of extended segments to NaN
            outside = true(1, T);
            for k = 1:size(segs,1)
                outside(segs(k,1):segs(k,2)) = false;
            end
            FR_s(:, outside) = NaN;
        case 'zero'
            outside = true(1, T);
            for k = 1:size(segs,1)
                outside(segs(k,1):segs(k,2)) = false;
            end
            FR_s(:, outside) = 0;
        case 'keep'
            % do nothing
        otherwise
            error('Unknown fillOutside: %s', opts.fillOutside);
    end

    % Optional normalization over time
    FR_n = FR_s;
    normType = lower(opts.norm.type);
    if ~strcmp(normType, 'none')
        maskForStats = true(1, T);
        if opts.norm.useMask
            % use extended segments as mask
            maskForStats(:) = false;
            for k = 1:size(segs,1)
                maskForStats(segs(k,1):segs(k,2)) = true;
            end
        end
        switch normType
            case 'demean'
                mu = mean(FR_s(:, maskForStats), 2, 'omitnan');
                FR_n = FR_s - mu;
            case 'zscore'
                mu = mean(FR_s(:, maskForStats), 2, 'omitnan');
                sd = std(FR_s(:, maskForStats), 0, 2, 'omitnan');
                sd(sd < 1e-12) = 1e-12;
                FR_n = (FR_s - mu) ./ sd;
            case 'minmax'
                mn = min(FR_s(:, maskForStats), [], 2, 'omitnan');
                mx = max(FR_s(:, maskForStats), [], 2, 'omitnan');
                rng = mx - mn; rng(rng < 1e-12) = 1e-12;
                FR_n = (FR_s - mn) ./ rng;
            otherwise
                error('Unknown opts.norm.type: %s', opts.norm.type);
        end
    end

    % Reassemble output size
    if opts.keepAllNeurons
        FR_out = FR;                 % original size N x T
        FR_out(idx_neu, :) = FR_n;   % place processed rows
    else
        FR_out = FR_n;               % only selected neurons
    end

    % Meta
    meta = struct();
    meta.idx_neu        = idx_neu;
    meta.V              = V;
    meta.runs_ones      = segs1;
    meta.segments_ext   = segs;
    meta.window         = W;
    meta.winShape       = opts.winShape;
    meta.extendLR       = opts.extendLR;
    meta.normType       = normType;
end

% ---------------- helpers ----------------
function segs = contiguous_segments(mask)
    mask = logical(mask(:)).';
    d = diff([false mask false]);
    starts = find(d == 1);
    ends   = find(d == -1) - 1;
    segs   = [starts(:) ends(:)];
end
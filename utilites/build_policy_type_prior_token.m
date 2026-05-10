function priorToken = build_policy_type_prior_token(pms, typeLabels)
%BUILD_POLICY_TYPE_PRIOR_TOKEN Build a compact token for policy-type priors.
%
% Example:
%   pms.policyTypeWeights = [10, 1]
%   typeLabels = {'fw', 'bw'}
%   -> 'PTfw10_bw1'

priorToken = '';

if ~isfield(pms, 'policyTypeWeights') || isempty(pms.policyTypeWeights)
    return;
end

weights = pms.policyTypeWeights(:)';
if all(abs(weights - weights(1)) < 1e-12)
    return;
end

if nargin < 2 || isempty(typeLabels)
    typeInfo = build_type_info(pms.typeMask3D);
    typeLabels = typeInfo.TypeLabels;
end

if numel(weights) ~= numel(typeLabels)
    priorToken = 'PTcustom';
    return;
end

parts = cell(1, numel(weights));
for typeIndex = 1:numel(weights)
    label = regexprep(char(typeLabels{typeIndex}), '[^A-Za-z0-9]', '');
    if isempty(label)
        label = sprintf('T%d', typeIndex);
    end
    parts{typeIndex} = sprintf('%s%s', ...
        label, format_policy_weight_token(weights(typeIndex)));
end

priorToken = ['PT' strjoin(parts, '_')];
end

function token = format_policy_weight_token(weight)
%FORMAT_POLICY_WEIGHT_TOKEN Convert one numeric weight into a filename-safe token.

token = sprintf('%.3g', weight);
token = strrep(token, '.', 'p');
token = strrep(token, '+', '');
token = strrep(token, '-', 'm');
end

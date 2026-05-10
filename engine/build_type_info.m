function typeInfo = build_type_info(typeMask3D)
%BUILD_TYPE_INFO Build the admissible temporal-order templates.
%
% All permutations of [1 2 3] are generated as candidate order templates.
% Two special labels are reserved:
%   [1 2 3] -> 'fw'
%   [3 2 1] -> 'bw'
%
% typeMask3D selects which 3-item order templates remain active.
%
% OUTPUT
%   typeInfo.selectedTypes3D   Selected permutations
%   typeInfo.TypeLabels        Labels of selected permutations
%   typeInfo.nEffectiveTypes   Number of selected types
%   typeInfo.forwardTypeIndex  Index of 'fw' among selected types, if present
%   typeInfo.backwardTypeIndex Index of 'bw' among selected types, if present

allTypes3D = sortrows(perms(1:3));
allTypeLabels = cell(1, size(allTypes3D, 1));

for typeIndex = 1:size(allTypes3D, 1)
    if isequal(allTypes3D(typeIndex, :), 1:3)
        allTypeLabels{typeIndex} = 'fw';
    elseif isequal(allTypes3D(typeIndex, :), 3:-1:1)
        allTypeLabels{typeIndex} = 'bw';
    else
        allTypeLabels{typeIndex} = sprintf('%d%d%d', allTypes3D(typeIndex, :));
    end
end

selectedMask    = logical(typeMask3D);
selectedTypes   = allTypes3D(selectedMask, :);
selectedLabels  = allTypeLabels(selectedMask);

if isempty(selectedTypes)
    error('%s:NoTypesSelected', mfilename, ...
        'typeMask3D must enable at least one 3D temporal-order type.');
end

typeInfo = struct();
typeInfo.selectedTypes3D    = selectedTypes;
typeInfo.TypeLabels         = selectedLabels;
typeInfo.nEffectiveTypes    = size(selectedTypes, 1);
typeInfo.forwardTypeIndex   = find(strcmp(selectedLabels, 'fw'), 1);
typeInfo.backwardTypeIndex  = find(strcmp(selectedLabels, 'bw'), 1);
end

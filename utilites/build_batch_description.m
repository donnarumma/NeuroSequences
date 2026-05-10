function description = build_batch_description(pms)
%BUILD_BATCH_DESCRIPTION Build a compact folder name for a batch configuration.

targetLabel = char('A' - 1 + (1:pms.nDirs));
familyLabel = build_batch_family_label(pms);
directionLabel = build_batch_direction_label_from_mask(pms.typeMask3D);
priorToken = build_policy_type_prior_token(pms);

descriptionParts = { ...
    pms.experimentLabel, ...
    'SEQUENCES', ...
    targetLabel, ...
    familyLabel, ...
    directionLabel ...
    };

if ~isempty(priorToken)
    descriptionParts{end + 1} = priorToken; %#ok<AGROW>
end

description = sprintf('%s_COS(%g,%g)', ...
    strjoin(descriptionParts, '_'), ...
    pms.mainProb(1) * 100, ...
    pms.mainProb(2) * 100);
end

function familyLabel = build_batch_family_label(pms)
% Build a compact label for active sequence families.

familyTokens = {};

if pms.include1D
    familyTokens{end + 1} = 'S1'; %#ok<AGROW>
end

if pms.include2D
    familyTokens{end + 1} = 'S2'; %#ok<AGROW>
end

if pms.include3D && ~pms.only2D
    familyTokens{end + 1} = 'S3'; %#ok<AGROW>
end

if isempty(familyTokens)
    familyLabel = 'NoSeq';
else
    familyLabel = strjoin(familyTokens, '');
end
end

function directionLabel = build_batch_direction_label_from_mask(typeMask3D)
% Keep only canonical forward/backward information in the folder name.

typeInfo = build_type_info(typeMask3D);
hasForward = ~isempty(typeInfo.forwardTypeIndex);
hasBackward = ~isempty(typeInfo.backwardTypeIndex);

if hasForward && hasBackward
    directionLabel = 'FwdBwd';
elseif hasForward
    directionLabel = 'Fwd';
elseif hasBackward
    directionLabel = 'Bwd';
else
    directionLabel = 'Ord';
end
end

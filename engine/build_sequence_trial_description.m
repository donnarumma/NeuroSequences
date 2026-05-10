function trialDescription = build_sequence_trial_description(sequenceModel, pms)
%BUILD_SEQUENCE_TRIAL_DESCRIPTION Build the canonical description for one trial.

experimentLabel = pms.experimentLabel;
targetLabel = char('A' - 1 + (1:pms.nDirs));
familyLabel = build_family_label(pms);
directionLabel = build_direction_label(sequenceModel);
priorToken = build_policy_type_prior_token(pms, sequenceModel.effectiveTypeLabels);

descriptionParts = { ...
    experimentLabel, ...
    targetLabel, ...
    familyLabel, ...
    directionLabel ...
    };

if ~isempty(priorToken)
    descriptionParts{end + 1} = priorToken; %#ok<AGROW>
end

descriptionParts{end + 1} = sprintf('Pol%g', sequenceModel.nTasks); %#ok<AGROW>
descriptionParts{end + 1} = sprintf('%s%g', pms.namefor, pms.iTrial); %#ok<AGROW>

trialDescription = strjoin(descriptionParts, '_');
end

function familyLabel = build_family_label(pms)
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

function directionLabel = build_direction_label(sequenceModel)
% Build a compact label for the canonical forward/backward availability.

hasForward = ~isempty(sequenceModel.forwardTypeIndex);
hasBackward = ~isempty(sequenceModel.backwardTypeIndex);

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

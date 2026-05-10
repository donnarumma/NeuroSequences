function actionLabels = extract_action_labels_from_mdp(MDP)
%EXTRACT_ACTION_LABELS_FROM_MDP Derive simple action labels from the MDP structure.

actionLabels = {};

if iscell(MDP)
    root = MDP{1};
else
    root = MDP;
end

if isfield(root, 'sname') && numel(root.sname) >= 1
    labels = root.sname{1};
elseif isfield(root, 'mdp') && ~isempty(root.mdp) && isfield(root.mdp(1), 'sname')
    labels = root.mdp(1).sname{1};
else
    return;
end

actionLabels = labels;
for iLabel = 1:numel(actionLabels)
    currentLabel = char(actionLabels{iLabel});
    actionLabels{iLabel} = currentLabel(end);
end
end

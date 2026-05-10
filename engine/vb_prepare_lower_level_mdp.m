function [childMDP, Orow, info] = vb_prepare_lower_level_mdp(parentMDP, iTime, A_lk, xq, Orow)
% Prepare the subordinate MDP exactly as the hierarchical block does,
% but without calling the lower-level runner. This is the "external launch"
% entry point for modular experiments.

if ~isscalar(parentMDP)
    error('vb_prepare_lower_level_mdp:ScalarParent', ...
        'parentMDP must be a scalar trial/model structure.');
end

childMDP = local_reuse_or_init_child(parentMDP, iTime);
childMDP.factor = [];

info = struct();
info.preparedFactors = [];
info.initialStateSource = {};
info.preferenceSource = {};
info.policyPriorSource = {};

if ~isfield(parentMDP, 'link')
    return;
end

for iHfactor = 1:size(parentMDP.link, 1)
    for iOfactor = 1:size(parentMDP.link, 2)
        if isempty(parentMDP.link{iHfactor, iOfactor})
            continue;
        end

        childMDP.factor(end + 1) = iHfactor; %#ok<AGROW>
        info.preparedFactors(end + 1) = iHfactor; %#ok<AGROW>

        Orow{iOfactor, iTime} = spm_dot(A_lk{iOfactor}, xq);
        childMDP.D{iHfactor} = parentMDP.link{iHfactor, iOfactor} * Orow{iOfactor, iTime};

        stateSource = 'predicted_outcome';
        if isfield(parentMDP, 'n') && size(parentMDP.n, 2) >= iTime && parentMDP.n(iOfactor, iTime)
            nModel = parentMDP.n(iOfactor, iTime);
            if nModel == 1
                ps = parentMDP.link{iHfactor, iOfactor}(:, parentMDP.o(iOfactor, iTime));
                childMDP.s(iHfactor, 1) = find(ps);
                stateSource = 'generated_by_same_model';
            else
                childMDP.s(iHfactor, 1) = parentMDP.mdp(iTime).s(iHfactor, 1);
                stateSource = 'copied_from_other_model';
            end
        end

        try
            childMDP.s(iHfactor, 1) = childMDP.s(iHfactor, 1);
        catch
            ps = parentMDP.link{iHfactor, iOfactor}(:, parentMDP.o(iOfactor, iTime));
            childMDP.s(iHfactor, 1) = find(ps);
        end

        info.initialStateSource{end + 1, 1} = struct( ...
            'hiddenFactor', iHfactor, ...
            'outcomeFactor', iOfactor, ...
            'source', stateSource); %#ok<AGROW>
    end
end

if isfield(parentMDP, 'linkC')
    for iHfactor = 1:size(parentMDP.linkC, 1)
        for iOfactor = 1:size(parentMDP.linkC, 2)
            if isempty(parentMDP.linkC{iHfactor, iOfactor})
                continue;
            end
            Orow{iOfactor, iTime} = spm_dot(A_lk{iOfactor}, xq);
            childMDP.C{iHfactor} = spm_log(parentMDP.linkC{iHfactor, iOfactor} * Orow{iOfactor, iTime});
            info.preferenceSource{end + 1, 1} = struct( ...
                'hiddenFactor', iHfactor, ...
                'outcomeFactor', iOfactor, ...
                'source', 'linkC_from_parent'); %#ok<AGROW>
        end
    end
end

if isfield(parentMDP, 'linkE')
    childMDP.factorE = [];
    for iOfactor = 1:size(parentMDP.linkE, 2)
        if isempty(parentMDP.linkE{iOfactor})
            continue;
        end
        Orow{iOfactor, iTime} = spm_dot(A_lk{iOfactor}, xq);
        childMDP.E = parentMDP.linkE{iOfactor} * Orow{iOfactor, iTime};
        info.policyPriorSource{end + 1, 1} = struct( ...
            'outcomeFactor', iOfactor, ...
            'source', 'linkE_from_parent'); %#ok<AGROW>
    end
end

function childMDP = local_reuse_or_init_child(parentMDP, iTime)
try
    childMDP = parentMDP.mdp(iTime);
catch
    try
        childMDP = spm_MDP_update(parentMDP.MDP(iTime), parentMDP.mdp(iTime - 1));
    catch
        try
            childMDP = spm_MDP_update(parentMDP.MDP(1), parentMDP.mdp(iTime - 1));
        catch
            childMDP = parentMDP.MDP(1);
        end
    end
end

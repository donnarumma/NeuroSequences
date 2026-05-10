function [parentMDP, Orow, info] = vb_integrate_lower_level_outcomes(parentMDP, childMDP, Orow, iTime)
% Push inferred subordinate outcomes/preferences/policies back to the parent.

if ~isscalar(parentMDP)
    error('vb_integrate_lower_level_outcomes:ScalarParent', ...
        'parentMDP must be a scalar trial/model structure.');
end

info = struct();
info.updatedOutcomeFactors = [];
info.linkCApplied = false;
info.linkEApplied = false;
info.updatedDEM = false;

if ~isfield(parentMDP, 'link')
    return;
end

for iHfactor = 1:size(parentMDP.link, 1)
    for iOfactor = 1:size(parentMDP.link, 2)
        if isempty(parentMDP.link{iHfactor, iOfactor})
            continue;
        end
        Orow{iOfactor, iTime} = parentMDP.link{iHfactor, iOfactor}' * childMDP.X{iHfactor}(:,1);
        info.updatedOutcomeFactors(end + 1, :) = [iHfactor, iOfactor]; %#ok<AGROW>
    end
end

if isfield(parentMDP, 'linkC')
    for iHfactor = 1:size(parentMDP.linkC, 1)
        for iOfactor = 1:size(parentMDP.linkC, 2)
            if isempty(parentMDP.linkC{iHfactor, iOfactor})
                continue;
            end
            indC = sparse(childMDP.o(iHfactor,:)', ...
                1:length(childMDP.o(iHfactor,:)), ...
                ones(length(childMDP.o(iHfactor,:)), 1), ...
                size(childMDP.C{iHfactor}, 1), ...
                size(childMDP.C{iHfactor}, 2));
            Orow{iOfactor, iTime} = spm_softmax( ...
                spm_log(Orow{iOfactor, iTime}) + ...
                parentMDP.linkC{iHfactor, iOfactor}' * sum((indC .* childMDP.C{iHfactor}), 2));
            info.linkCApplied = true;
        end
    end
end

if isfield(parentMDP, 'linkE')
    for iOfactor = 1:size(parentMDP.linkE, 2)
        if isempty(parentMDP.linkE{iOfactor})
            continue;
        end
        Orow{iOfactor, iTime} = spm_softmax( ...
            spm_log(Orow{iOfactor, iTime}) + ...
            spm_log(parentMDP.linkE{iOfactor}' * childMDP.R(:, end)));
        info.linkEApplied = true;
    end
end

if isfield(parentMDP, 'MDP') && isfield(parentMDP.MDP, 'demi')
    parentMDP.MDP.DEM.G(1).x = childMDP.dem(end).pU.x{1}(:,end);
    parentMDP.MDP.DEM.M(1).x = childMDP.dem(end).qU.x{1}(:,end);
    info.updatedDEM = true;
end

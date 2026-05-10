function   popFR_mod = cosineTuning(popFRt, type, perc_center, perc_side)
% function popFR_mod = cosineTuning(popFRt, type, scale_center, scale_side)
    try
        perc_center=perc_center.perc_center;
        perc_side  =perc_center.perc_side;
    end
    nPops       = numel(popFRt);
    popFR_mod   = popFRt;               % copy original
    
    idx = find(type == 1);           % positions with event

    for iType = 1:length(idx)
        center = idx(iType);
        left   = mod(center - 2, nPops) + 1;   % wrap-around left
        right  = mod(center,     nPops) + 1;   % wrap-around right

        total = popFRt(center);
        % Apply cosine-style modulation redistribution
        popFR_mod(center) = perc_center * total;
        popFR_mod(left)   = popFR_mod(left)   + perc_side * total;
        popFR_mod(right)  = popFR_mod(right)  + perc_side * total;
        
        % popFR_mod(center) = popFRt(center) * perc_center;
        % popFR_mod(left)   = popFRt(left)   * perc_side;
        % popFR_mod(right)  = popFRt(right)  * perc_side;
    end
end
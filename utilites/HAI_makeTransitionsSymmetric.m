function   transitions = HAI_makeTransitionsSymmetric(transitions)
% function transitions = HAI_makeTransitionsSymmetric(transitions)

[nRows, nCols, nActions]   = size(transitions);
% actions             = {'up', 'down', 'left', 'right'};
dRow                = [-1, 1, 0, 0]; % up, down, left, right
dCol                = [0, 0, -1, 1];
opposite_dirs       = [2, 1, 4, 3]; % opposite directions explicitly defined

for iRow = 1:nRows
    for iCol = 1:nCols
        for iDir = 1:nActions
            niRow = iRow + dRow(iDir);
            niCol = iCol + dCol(iDir);

            if niRow < 1 || niRow > nRows || niCol < 1 || niCol > nCols
                transitions(iRow,iCol,iDir) = 0; % Close invalid borders
                continue;
            end

            oppDir = opposite_dirs(iDir);
            if (transitions(iRow,iCol,iDir) ~= transitions(niRow,niCol,oppDir))  && ...
               (~transitions(iRow,iCol,iDir) || ~transitions(niRow,niCol,oppDir))
                % If asymmetric, close both sides
                % fprintf('S%g%g,u:%s, val=%g vs ',iRow,iCol,actions{iDir},transitions(iRow,iCol,iDir))
                % fprintf('S%g%g,u:%s, val=%g\n',niRow,niCol,actions{oppDir},transitions(niRow,niCol,oppDir))
                transitions(iRow,iCol,iDir)      = 0;
                transitions(niRow,niCol,oppDir) = 0;
            end
        end
    end
end

end

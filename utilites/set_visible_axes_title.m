function set_visible_axes_title(hfig, trialTitle)
%SET_VISIBLE_AXES_TITLE Set the title on the first visible axes of a figure.

axesHandles = findall(hfig, 'Type', 'axes');

for axisIndex = 1:numel(axesHandles)
    if strcmp(get(axesHandles(axisIndex), 'Visible'), 'on')
        title(axesHandles(axisIndex), trialTitle, 'Interpreter', 'none');
        return;
    end
end
end

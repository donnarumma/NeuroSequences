function set_visible_axes_title(hfig, trialTitle, titleInterpreter)
%SET_VISIBLE_AXES_TITLE Set the title on the first visible axes of a figure.

if nargin < 3 || isempty(titleInterpreter)
    titleInterpreter = 'none';
end

axesHandles = findall(hfig, 'Type', 'axes');

for axisIndex = 1:numel(axesHandles)
    if strcmp(get(axesHandles(axisIndex), 'Visible'), 'on')
        title(axesHandles(axisIndex), trialTitle, 'Interpreter', titleInterpreter);
        return;
    end
end
end

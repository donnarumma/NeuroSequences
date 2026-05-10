function   par = plot_MAZEParams(parSource)
% function par = plot_MAZEParams(parSource)
par.exec        = true;
par.hfig        = [];
par.bordercol   = [0.9,0.2,0.2];% color of the border of rooms
par.doorWidth   = 0.3;          % width of the open door
par.lw          = 7;            % line width of the walls
par.textcol     = 'k';          % color of text
par.fs          = 20;           % font size of states
par.labelsmode  = 2;
try
    fnames=fieldnames(parSource);
    for in=1:length(fnames)
        par.(fnames{in})=parSource.(fnames{in});
    end
catch
end
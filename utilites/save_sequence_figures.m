function save_sequence_figures(hfg, figureDescription, saveDir)
%SAVE_SEQUENCE_FIGURES Save a struct of figure handles using hfigPrint helpers.

if ~exist('hfigPrintParams', 'file') || ~exist('hfigPrint', 'file')
    warning('%s:MissingFigureSaveHelpers', mfilename, ...
        'Skipping figure saving because hfigPrint helpers are not on path.');
    return;
end
par.hfigPrint = hfigPrintParams();
par.wm = 100; % Set a large width multiplier to ensure high resolution output.
par.hfigPrint.save_dir = saveDir;
par.hfigPrint.pdf_file = fullfile(saveDir, [figureDescription '.pdf']);
fprintf('Saving figures to %s\n', par.hfigPrint.pdf_file);
drawnow;
hfigPrint(hfg, par.hfigPrint);
end

function outputs = Chen02_Fig05_Movie(options)
%CHEN02_FIG05_MOVIE Animate the three Figure 5 examples from saved figures.
%   outputs = Chen02_Fig05_Movie()
%   outputs = Chen02_Fig05_Movie(struct('caseName', 'AB_Backward'))
%   outputs = Chen02_Fig05_Movie(struct('caseName', 'BA_Backward'))
%   outputs = Chen02_Fig05_Movie(struct('sourceDir', repDir))
%   outputs = Chen02_Fig05_Movie(struct('previewOnly', true))
%
% Reads the selected raster, firing-rate and condition-level PCA figures
% exported by MAIN_Chen02_S2_FwBw_Exp. No model or readout is recomputed.
% The task display is schematic; the original panel time offsets, colours,
% smoothing and numerical coordinates are retained. Requires MATLAB and
% ffmpeg (libx264). Files are saved in Movies/output by default.

if nargin < 1
    options = struct();
end
sourceDir = '/TESTS/HAI_SEQUENCES/Chen02/Chen02_SEQUENCES_ABCDEF_S2_FwdBwd_PTfw10_bw1_COS(100,100)/Rep01';
p = chen_sequence_movie_options(options, 'AB_Forward', sourceDir);
scenario = movie_scenario(p.caseName);
p.caseName = scenario.caseName;
files = source_files(p.sourceDir, scenario);
outputs = chen_sequence_movie_render(p, scenario, files);
end

function scenario = movie_scenario(caseName)
caseName = validatestring(caseName, {'AB_Forward', 'AB_Backward', 'BA_Backward'}, ...
    mfilename, 'caseName');
scenario.caseName = caseName;
scenario.stem = ['Chen02_Fig05_' caseName];
scenario.label = strrep(caseName, '_', ' ');
scenario.label = [scenario.label(1:2), lower(scenario.label(3:end))];
scenario.sequence = caseName(1:2);
switch caseName
    case 'AB_Forward'
        scenario.trialIndex = 1;
        scenario.direction = 'forward';
        scenario.directionTag = 'Fwd';
        scenario.pcaTag = 'PCAForward';
        scenario.plan = 'AB';
        scenario.panels = {'D', 'E', 'F'};
    case 'AB_Backward'
        scenario.trialIndex = 31;
        scenario.direction = 'backward';
        scenario.directionTag = 'Bwd';
        scenario.pcaTag = 'PCABackward';
        scenario.plan = 'BA';
        scenario.panels = {'G', 'H', 'I'};
    case 'BA_Backward'
        scenario.trialIndex = 36;
        scenario.direction = 'backward';
        scenario.directionTag = 'Bwd';
        scenario.pcaTag = 'PCABackward';
        scenario.plan = 'AB';
        scenario.panels = {'J', 'K', 'L'};
end
scenario.planLabel = sprintf('%c(1)  then  %c(2)', scenario.plan);
scenario.figureNumber = 5;
scenario.nRanks = 2;
scenario.readoutRole = 'memory';
scenario.taskLabel = 'Fixed-length sequence memory';
scenario.pcaTitlePrefix = 'Rank';
scenario.pcaSubtitle = 'Condition-level PCA: targets A-F';
scenario.footer = 'Presentation and working memory; saccade execution is outside this interval.';
scenario.entryPoint = 'Chen02_Fig05_Movie';
scenario.simulationMain = 'MAIN_Chen02_S2_FwBw_Exp';
end

function files = source_files(sourceDir, scenario)
if isfolder(fullfile(sourceDir, 'FIG'))
    sourceDir = fullfile(sourceDir, 'FIG');
end
sampleSuffix = sprintf('Chen02_ABCDEF_S2_%s_Trial%d.fig', scenario.directionTag, scenario.trialIndex);
files.raster = fullfile(sourceDir, ['Raster_' sampleSuffix]);
files.firingRate = fullfile(sourceDir, ['FiringRate_' sampleSuffix]);
files.pca = fullfile(sourceDir, ['PcaTime_Chen02_ABCDEF_S2_FwdBwd_' scenario.pcaTag '.fig']);
paths = struct2cell(files);
for k = 1:numel(paths)
    if ~isfile(paths{k})
        error('Chen02_Fig05_Movie:MissingSource', ...
            ['Missing saved figure: %s\nRun MAIN_Chen02_S2_FwBw_Exp first, ' ...
             'or set sourceDir to the corresponding Rep01/FIG directory.'], paths{k});
    end
end
end

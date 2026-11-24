function outputs = Chen01_Fig04_Movie(options)
%CHEN01_FIG04_MOVIE Animate ABC forward, backward and sensory Figure 4 panels.
%   outputs = Chen01_Fig04_Movie()
%   outputs = Chen01_Fig04_Movie(struct('caseName', 'ABC_Backward'))
%   outputs = Chen01_Fig04_Movie(struct('caseName', 'ABC_Sensory'))
%   outputs = Chen01_Fig04_Movie(struct('previewOnly', true))
%
% Reuses saved trial-1 figures and three condition-level PCA panels. Task
% direction is known before S1; there is no late cue. Requires MATLAB and
% ffmpeg for MP4 encoding. Default output is Movies/output/<case stem>.
if nargin < 1
    options = struct();
end
p = chen_sequence_movie_options(options, 'ABC_Forward', '');
scenario = movie_scenario(p.caseName);
p.caseName = scenario.caseName;
if isempty(p.sourceDir)
    p.sourceDir = fullfile('/TESTS/HAI_SEQUENCES/Chen01', scenario.sourceFolder, 'Rep01');
end
figureDir = p.sourceDir;
if isfolder(fullfile(figureDir, 'FIG'))
    figureDir = fullfile(figureDir, 'FIG');
end
files.raster = fullfile(figureDir, ['Raster_' scenario.sourceSuffix '_Trial1.fig']);
files.firingRate = fullfile(figureDir, ['FiringRate_' scenario.sourceSuffix '_Trial1.fig']);
files.pca = fullfile(figureDir, ['PcaTime_' scenario.sourceSuffix '.fig']);
outputs = chen_sequence_movie_render(p, scenario, files);
end

function scenario = movie_scenario(caseName)
caseName = validatestring(caseName, {'ABC_Forward', 'ABC_Backward', 'ABC_Sensory'}, ...
    mfilename, 'caseName');
scenario.caseName = caseName;
scenario.stem = ['Chen01_Fig04_' caseName];
scenario.label = [caseName(1:3), ' ', lower(caseName(5:end))];
scenario.sequence = 'ABC';
scenario.trialIndex = 1;
scenario.figureNumber = 4;
scenario.nRanks = 3;
scenario.taskLabel = 'Variable-length sequence task';
scenario.readoutRole = 'memory';
scenario.pcaTitlePrefix = 'Rank';
scenario.pcaSubtitle = 'Condition-level PCA: targets A-F';
scenario.footer = 'Rule known before S1; presentation and memory are shown, before saccade execution.';
scenario.entryPoint = 'Chen01_Fig04_Movie';
switch caseName
    case 'ABC_Forward'
        scenario.direction = 'forward';
        scenario.plan = 'ABC';
        scenario.panels = {'F', 'G', 'H'};
        scenario.sourceFolder = 'Chen01_SEQUENCES_ABCDEF_S1S2S3_Fwd_COS(100,100)';
        scenario.sourceSuffix = 'Chen01_ABCDEF_S1S2S3_Fwd';
        scenario.simulationMain = 'MAIN_Chen01_S1S2S3_Forward_Exp';
    case 'ABC_Backward'
        scenario.direction = 'backward';
        scenario.plan = 'CBA';
        scenario.panels = {'I', 'J', 'K'};
        scenario.sourceFolder = 'Chen01_SEQUENCES_ABCDEF_S1S2S3_Bwd_COS(100,100)';
        scenario.sourceSuffix = 'Chen01_ABCDEF_S1S2S3_Bwd';
        scenario.simulationMain = 'MAIN_Chen01_S1S2S3_Backward_Exp';
    case 'ABC_Sensory'
        scenario.direction = 'sensory';
        scenario.plan = '';
        scenario.panels = {'L', 'M', 'N'};
        scenario.readoutRole = 'sensory';
        scenario.pcaTitlePrefix = 'Sensory epoch';
        scenario.pcaSubtitle = 'Sensory PCA: peak-response hulls';
        scenario.footer = 'Level 1 sensory responses to the same ABC inputs in both task directions.';
        scenario.sourceFolder = 'Chen01_SEQUENCES_ABCDEF_Sensors_Ord_COS(80,100)';
        scenario.sourceSuffix = 'Chen01_ABCDEF_Sensors_Ord';
        scenario.simulationMain = 'MAIN_Chen01_S1S2S3_Sensors_Exp';
end
scenario.planLabel = '';
if ~isempty(scenario.plan)
    scenario.planLabel = sprintf('%c(1)  then  %c(2)  then  %c(3)', scenario.plan);
end
end

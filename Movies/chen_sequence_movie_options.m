function p = chen_sequence_movie_options(options, defaultCase, defaultSource)
%CHEN_SEQUENCE_MOVIE_OPTIONS Validate common movie options without side effects.
p.caseName = defaultCase;
p.sourceDir = defaultSource;
p.outputDir = '';
p.pixelSize = [1920, 1080];
p.frameRate = 20;
p.playbackSpeed = 0.25;
p.holdStartSeconds = 1;
p.holdEndSeconds = 5;
p.previewOnly = false;
p.keepFrames = false;
p.overwrite = false;
validateattributes(options, {'struct'}, {'scalar'});
names = fieldnames(options);
for k = 1:numel(names)
    assert(isfield(p, names{k}), 'chen_sequence_movie_options:UnknownOption', ...
        'Unknown option: %s', names{k});
    p.(names{k}) = options.(names{k});
end
validateattributes(p.pixelSize, {'numeric'}, {'numel', 2, 'integer', '>=', 640});
validateattributes(p.frameRate, {'numeric'}, {'scalar', 'integer', 'positive'});
validateattributes(p.playbackSpeed, {'numeric'}, {'scalar', 'finite', 'positive'});
validateattributes(p.holdStartSeconds, {'numeric'}, {'scalar', 'finite', 'nonnegative'});
validateattributes(p.holdEndSeconds, {'numeric'}, {'scalar', 'finite', 'nonnegative'});
for name = {'previewOnly', 'keepFrames', 'overwrite'}
    validateattributes(p.(name{1}), {'logical'}, {'scalar'});
end
p.sourceDir = expand_home(p.sourceDir);
p.outputDir = expand_home(p.outputDir);
end

function path = expand_home(path)
path = char(path);
if startsWith(path, '~/') || startsWith(path, '~\')
    path = fullfile(char(java.lang.System.getProperty('user.home')), path(3:end));
end
end

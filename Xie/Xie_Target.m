function hfg = Xie_Target(targetIds, pathDir, ifplot)
%XIE_TARGET Generate Xie target cue figures and save them with hfigPrint.
%
% hfg = Xie_Target(targetIds, pathDir, ifplot)
%
% INPUT
%   targetIds : vector of target indices to render. Use 0 for Target0
%               with all peripheral circles gray. Default = 1:6
%   pathDir   : output directory for hfigPrint. Default = /TESTS/HAI_SEQUENCES/Xie/
%   ifplot    : when true, keep figures visible and skip saving. Default = false
%
% OUTPUT
%   hfg       : struct of figure handles with fields Target1, Target2, ...

if nargin < 1 || isempty(targetIds)
    targetIds = 1:6;
end
if nargin < 2 || isempty(pathDir)
    pathDir = '/TESTS/HAI_SEQUENCES/Xie/';
end
if nargin < 3 || isempty(ifplot)
    ifplot = false;
end

labels = {'$\uparrow$', '$\nearrow$', '$\searrow$', '$\downarrow$', '$\swarrow$', '$\nwarrow$'};
targetIds = unique(targetIds(:).', 'stable');
nTargets = numel(labels);

if any(targetIds < 0) || any(targetIds > nTargets) || any(targetIds ~= floor(targetIds))
    error('Xie_Target:InvalidTargetIds', ...
        'targetIds must contain integer values between 0 and %d.', nTargets);
end

if ~ifplot
    assert_hfigprint_dependency();
    pathDir = expanduser_local(pathDir);
    if ~endsWith(pathDir, filesep)
        pathDir = [pathDir filesep];
    end
    if ~isfolder(pathDir)
        mkdir(pathDir);
    end
end

visibleFlag = 'off';
if ifplot
    visibleFlag = 'on';
end

hfg = struct();
par = struct();
par.labels = labels;

for iTarget = targetIds
    par.hfig = figure('Visible', visibleFlag, 'Color', 'w');
    par.target = iTarget;
    hfg.(sprintf('Target%d', iTarget)) = plotCircles(par);
    if iTarget == 0
        title('Target0', 'FontSize', 16);
    else
        title(sprintf('Step %d', iTarget), 'FontSize', 16);
    end
end

if ~ifplot
    description = 'Xie_Target';
    printPms = hfigPrintParams();
    printPms.pdf_file = [pathDir description '.pdf'];
    printPms.save_dir = pathDir;
    hfigPrint(hfg, printPms);
end

end

function assert_hfigprint_dependency()
if exist('hfigPrint', 'file') ~= 2 || exist('hfigPrintParams', 'file') ~= 2
    error('Xie_Target:MissingDependency', ...
        ['hfigPrint and hfigPrintParams are required on the MATLAB path. ' ...
         'Run setup_HAI_DEV or add the relevant utilities folder first.']);
end
end

function pathStr = expanduser_local(pathStr)
if startsWith(pathStr, '~')
    homeDir = getenv('HOME');
    if isempty(homeDir)
        homeDir = char(java.lang.System.getProperty('user.home'));
    end
    pathStr = fullfile(homeDir, pathStr(2:end));
end
end

function [A, figs] = prototype(f)
%% perpVars: daily preparation of important variables for today
% Make sure you're in the correct directory when you run me!
% See conv2vars for commands to load variables into workspace

%% Figure handles
if max(contains(who, 'f'))
    f = 0;
else
    f = 1;
end

%
if f
    figs = [];
    fnms = {};
    figs(1) = figure; % Example of manually-drawn contour
    fnms{1} = sprintf('%s_DrawnContour', datestr(now, 'yymmdd'));
    figs(2) = figure; % Check array of manually-drawn contours
    fnms{2} = sprintf('%s_ContourGallery', datestr(now, 'yymmdd'));
    
    set(figs, 'Color', 'w');
    
else
    cla(figs);
    clf(figs);
end

%% Today's code brought to you by Thor god of Thunder
do_this_once = true;
verbosity    = true;

% Constants
m     = @(x) randi([1 length(x)], 1);
M     = @(x) x(m(x));
ptime = 0.005;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Test on 3 genotypes as a smaller dataset
lab     = '/home/jbustamante/Dropbox/EdgarSpalding/labdata/guosheng_wu/hypocotyl_growth';
dataset = 'small_sort_blue';
folder  = sprintf('%s/%s', lab, dataset);

% Create Experiment with all Genotypes in Blue Experiment
tExp = cputime;
ex = Experiment(folder);
ex.AddGenotypes;
fprintf('Added %d genotypes to Experiment %s\n%.02f sec\n', ...
    ex.NumberOfGenotypes, ex.ExperimentName, cputime-tExp);

clear lab dataset folder;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Get PreHypocotyls from all Seedlings for all Genotypes
% Extract Seedlings
tSeeds = cputime;
ex.FindSeedlingAllGenotypes(verbosity);
fprintf('Extracted %d seeldlings from %d genotypes in %s [%.02f sec]\n\n', ...
    numel(ex.combineSeedlings), ex.NumberOfGenotypes, ...
    ex.ExperimentName, cputime-tSeeds);

% Extract Hypocotyls 
tHyps = cputime;
ex.FindHypocotylAllGenotypes(verbosity);
fprintf('Extracted %d hypocotyls from %d genotypes in %s [%.02f sec]\n\n', ...
    numel(ex.combineHypocotyls), ex.NumberOfGenotypes, ...
    ex.ExperimentName, cputime-tHyps);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Clean bad frames and prune dataset to reduce matfile size
% Removes RawSeedlings from Genotypes and PreHypocotyls from Seedlings
g = ex.combineGenotypes;
s = ex.combineSeedlings;
h = ex.combineHypocotyls;

tPrune = cputime;
ex.SaveExperiment;
fprintf('[%.02f sec] Pruned %d Seedlings and %d Hypocotyls\n', ...
    cputime-tPrune, numel(s), numel(h));

% Runs quality checks to remove bad frames
tCheck = cputime;
arrayfun(@(x) x.RemoveBadFrames, s, 'UniformOutput', 0);
fprintf('[%.02f sec] Cleaned bad frames from %d Seedlings\n', ...
    cputime-tCheck, numel(s));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Load full dataset
folder  = '/home/jbustamante/Dropbox/EdgarSpalding/labdata/hypoquantyl';
dataset = '181129/181128_small_sort_blue_3Genotypes.mat';
load(sprintf('%s/%s', folder, dataset));

clear folder dataset;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generate training set of CircuitJB objects
set(0, 'CurrentFigure', figs(1));
cla;clf;
num = 3;
typ = 1;
flp = 1;
sv  = 1;
vis = 1;

crcs = randomCircuits(ex, num, typ, flp, sv, vis);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Process manually-drawn contours
% Generate Curve objects and convert between reference frames
C = ex.combineContours;
c = M(C);

arrayfun(@(x) x.CreateCurves, C, 'UniformOutput', 0);
D = arrayfun(@(x) x.Curves, C, 'UniformOutput', 0);
D = cat(1, D{:});
B = arrayfun(@(x) x.getProperty('Contour'), H, 'UniformOutput', 0);
B = cat(2, B{:});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Display gallery of manually-drawn contours 
set(0, 'CurrentFigure', figs(2));
cla;clf;

if do_this_once
    for n  = 1 : g1.TotalImages
        ttl = sprintf('Genotype\n%s', fixTitle(g1.GenotypeName));
        title(ttl);
        pause(ptime);
    end
    %     do_this_once = false;
else
    ttl = sprintf('Genotype\n%s', fixTitle(g1.GenotypeName));
    title(ttl);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save Experiment data
tSave = cputime;
nm = sprintf('%s_%s_%dGenotypes', ...
    datestr(now, 'yymmdd'), ex.ExperimentName, ex.NumberOfGenotypes);
save(nm, '-v7.3', 'ex');
fprintf('[%.02f sec] Saved dataset %s\n', cputime-tSave, nm);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save Figures
% currDir = pwd;
for g = 1 : numel(figs)
    savefig(figs(g), fnms{g});
    saveas(figs(g), fnms{g}, 'tiffn');
end

A = ex;

end

function ttl = fixTitle(str)
%% Fix names of titles for plotting
ttl = strrep(str, '_', '|');
ttl = strrep(ttl, '^', '|');
end

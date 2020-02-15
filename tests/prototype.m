function [A, figs] = prototype(dataDir, doonce, verbose, par)
%% prototype: daily preparation of important variables for today
% Make sure you're in the correct directory when you run me!
% See conv2vars for commands to load variables into workspace

%% Today's code brought to you by Thor god of Thunder
% Constants
m     = @(x) randi([1 length(x)], 1);
M     = @(x) x(m(x));
ptime = 0.005;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create Experiment with all Genotypes in Blue Experiment
tExp = tic;
ex   = Experiment(dataDir);
ex.AddGenotypes;
fprintf('Added %d genotypes to Experiment %s\n%.02f sec\n', ...
    ex.NumberOfGenotypes, ex.ExperimentName, toc(tExp));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Get PreHypocotyls from all Seedlings for all Genotypes
% Extract Seedlings
tSeeds = tic;
ex.FindSeedlingAllGenotypes(verbose, par);
fprintf('Extracted %d seeldlings from %d genotypes in %s [%.02f sec]\n\n', ...
    numel(ex.combineSeedlings), ex.NumberOfGenotypes, ...
    ex.ExperimentName, toc(tSeeds));

%% Extract Hypocotyls
tHyps = tic;
ex.FindHypocotylAllGenotypes(verbose);
fprintf('Extracted %d hypocotyls from %d genotypes in %s [%.02f sec]\n\n', ...
    numel(ex.combineHypocotyls), ex.NumberOfGenotypes, ...
    ex.ExperimentName, toc(tHyps));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Clean bad frames and prune dataset to reduce matfile size
% Removes RawSeedlings from Genotypes and PreHypocotyls from Seedlings
g = ex.combineGenotypes;
s = ex.combineSeedlings;
h = ex.combineHypocotyls;

tPrune = tic;
ex.SaveExperiment;
fprintf('[%.02f sec] Pruned %d Seedlings and %d Hypocotyls\n', ...
    toc(tPrune), numel(s), numel(h));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generate training set of CircuitJB objects
set(0, 'CurrentFigure', figs(1));
cla;clf;
num = 2;
typ = 1;
flp = 1;
sv  = 1;
vis = 1;

CRCS = randomCircuits(ex, num, typ, flp, sv, vis);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Process manually-drawn contours
% Generate Curve objects and convert between reference frames
C = ex.combineContours;

arrayfun(@(x) x.CreateCurves('redo', par), C, 'UniformOutput', 0);
D = arrayfun(@(x) x.Curves, C, 'UniformOutput', 0);
D = cat(1, D{:});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Display gallery of manually-drawn contours
set(0, 'CurrentFigure', figs(2));
cla;clf;

g1 = g(1);
if doonce
    for n  = 1 : g1.TotalImages
        myimagesc(g1.getImage(n));
        ttl = sprintf('%s Frame %d', fixtitle(g1.GenotypeName), n);
        title(ttl);
        pause(ptime);
    end
%     doonce = false;
else
    n = M(1 : g1.TotalImages);
    myimagesc(g1.getImage(n));
    ttl = sprintf('%s Frame %d', fixtitle(g1.GenotypeName), n);
    title(ttl);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save Experiment data
tSave = tic;
nm = sprintf('%s_%s_%dGenotypes', ...
    datestr(now, 'yymmdd'), ex.ExperimentName, ex.NumberOfGenotypes);
save(nm, '-v7.3', 'ex');
fprintf('[%.02f sec] Saved dataset %s\n', toc(tSave), nm);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save Figures
% currDir = pwd;
for g = 1 : numel(figs)
    savefig(figs(g), fnms{g});
    saveas(figs(g), fnms{g}, 'tiffn');
end

A = ex;

end


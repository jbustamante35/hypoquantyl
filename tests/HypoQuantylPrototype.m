function [ex, g, s, h] = HypoQuantylPrototype(dataDir, verbose, par)
%% HypoQuantylPrototype: perform test runs of HypoQuantyl
% This function
%
% Usage:
%   ex = HypoQuantylPrototype(dataDir, verbose, par)
% Input:
%   dataDir:
%   verbose: 
%   par:
%
% Output:
%   ex: full Experiment after image processing
%

%% Create Experiment with all Genotypes in data directory
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
fprintf('[%.02f sec] Pruned %d Seedlings and %d Hypocotyls from %d Genotypes\n', ...
    toc(tPrune), numel(s), numel(h),  numel(g));

end


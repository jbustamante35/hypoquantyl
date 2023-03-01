function ex = HypoQuantylPrototype(edir, eset, mth, sav, toExclude, vrb, fidxs, vmth, opts)
%% HypoQuantylPrototype: test runs of HypoQuantyl
% This function loads a directory of images
%
% Usage:
%   [ex, eg, es, eh] = HypoQuantylPrototype(edir, eset, mth, ...
%       sav, toExclude, vrb, fidxs, vmth, opts)
%
% Input:
%   edir: path to main directory of data
%   eset: subset from main directory to analyze
%   mth: method with/without colission detection [new|old] (default 'new')
%   sav: save results into .mat file (default 0)
%   toExclude: genotypes-seedlings to exclude (default [])
%   vrb: verbosity through pipeline (default 0)
%   fidxs: show number of example hypocotyl images (default 0)
%   vmth: visualization  method (default 'Hypocotyls')
%   opts: various options (default [])
%
% Output:
%   ex: full Experiment after image processing
%   eg: Genotype objects
%   es: Seedling objects
%   eh: Hypocotyl objects

if nargin < 3; mth       = 'new';        end
if nargin < 4; sav       = 0;            end
if nargin < 5; toExclude = [];           end
if nargin < 6; vrb       = 0;            end
if nargin < 7; fidxs     = 0;            end
if nargin < 8; vmth      = 'Hypocotyls'; end
if nargin < 9; opts      = [];           end

%% Create Experiment and add Genotypes
% Genotypes are sub-directories from Experiment path
tExp = tic;
epth = sprintf('%s/%s', edir, eset);
ex   = Experiment('ExperimentPath', epth);
if ~isempty(opts); ex.setProperty(opts{1}, opts{2}); end
ex.AddGenotypes;
fprintf('Added %d genotypes to Experiment %s\n%.02f sec\n', ...
    ex.NumberOfGenotypes, ex.ExperimentName, toc(tExp));

%% Extract raw unsorted Seedlings from each Genotype
% Seedlings are individual objects in each image per Genotype
tSeeds = tic;
ex.FindSeedlingAllGenotypes(vrb, mth);
es     = ex.combineSeedlings;
fprintf('Extracted %d seeldlings from %d genotypes in %s [%.02f sec]\n\n', ...
    numel(es), ex.NumberOfGenotypes, ex.ExperimentName, toc(tSeeds));

%% Extract Hypocotyls
tHyps = tic;
ex.FindHypocotylAllGenotypes(vrb);
fprintf('Extracted %d hypocotyls from %d genotypes in %s [%.02f sec]\n\n', ...
    numel(ex.combineHypocotyls), ex.NumberOfGenotypes, ...
    ex.ExperimentName, toc(tHyps));

%% Exclude Seedlings
% Format as [ [gidxN1 , sidxM1] , [gidxN2 , sidxM2] ];
% toExclude = [ [4 , 2] ; [7 , 1] ; [10 , 1] ];

%% Concatenate and Save Results
if sav; ex.SaveExperiment; end

% ---------------------------------------------------------------------------- %
%% Show Examples
if fidxs; showExperimentExamples(ex, vmth, fidxs); end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% Create Experiment with all Genotypes in data directory
% tExp = tic;
% ex   = Experiment('ExperimentPath', dataDir);
% ex.AddGenotypes;
% fprintf('Added %d genotypes to Experiment %s\n%.02f sec\n', ...
%     ex.NumberOfGenotypes, ex.ExperimentName, toc(tExp));
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Get PreHypocotyls from all Seedlings for all Genotypes
% % Extract Seedlings
% tSeeds = tic;
% ex.FindSeedlingAllGenotypes(vrb, par);
% fprintf('Extracted %d seeldlings from %d genotypes in %s [%.02f sec]\n\n', ...
%     numel(ex.combineSeedlings), ex.NumberOfGenotypes, ...
%     ex.ExperimentName, toc(tSeeds));
%
% %% Extract Hypocotyls
% tHyps = tic;
% ex.FindHypocotylAllGenotypes(vrb);
% fprintf('Extracted %d hypocotyls from %d genotypes in %s [%.02f sec]\n\n', ...
%     numel(ex.combineHypocotyls), ex.NumberOfGenotypes, ...
%     ex.ExperimentName, toc(tHyps));
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% Clean bad frames and prune dataset to reduce matfile size
% % Removes RawSeedlings from Genotypes and PreHypocotyls from Seedlings
% g = ex.combineGenotypes;
% s = ex.combineSeedlings;
% h = ex.combineHypocotyls;
%
% if sav
%     tPrune = tic;
%     ex.SaveExperiment;
%     fprintf('[%.02f sec] Pruned %d Seedlings and %d Hypocotyls from %d Genotypes\n', ...
%         toc(tPrune), numel(s), numel(h),  numel(g));
% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
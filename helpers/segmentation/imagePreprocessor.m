function ex = imagePreprocessor(edir, eset, mth, sav, toExclude, vrb, fidxs, vmth, opts, odir)
%% imagePreprocessor: preprocessor for images to pipe into HypoQuantyl
%
% Usage:
%   ex = imagePreprocessor( ...
%       edir, eset, mth, sav, toExclude, vrb, fidxs, vmth, opts)
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

if nargin < 3;  mth       = 'new';        end
if nargin < 4;  sav       = 0;            end
if nargin < 5;  toExclude = [];           end
if nargin < 6;  vrb       = 0;            end
if nargin < 7;  fidxs     = 0;            end
if nargin < 8;  vmth      = 'Hypocotyls'; end
if nargin < 9;  opts      = [];           end
if nargin < 10; odir      = [];           end

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
ex.combineGenotypes;
ex.combineSeedlings;

%% Concatenate and Save Results
if sav; ex.SaveExperiment(odir); end

% ---------------------------------------------------------------------------- %
%% Show Examples
if fidxs; showExperimentExamples(ex, vmth, fidxs); end
end

function [A, figs] = prototype(varargin)
%% prototype:
%
% Usage:
%   [A, figs] = prototype(varargin)
%
% Input:
%   dataDir
%   doonce
%   doTraining
%   verbose
%   par
%   save_data
%   save_figs
%   mth
%
% Output:
%   A:
%   figs:
%

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

%% Today's code brought to you by Thor god of Thunder
% Constants
m     = @(x) randi([1 length(x)], 1);
M     = @(x) x(m(x));
ptime = 0.005;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create Experiment with all Genotypes in Blue Experiment
tExp = tic;
ex   = Experiment('ExperimentPath', dataDir);
ex.AddGenotypes;
fprintf('Added %d genotypes to Experiment %s\n%.02f sec\n', ...
    ex.NumberOfGenotypes, ex.ExperimentName, toc(tExp));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Get PreHypocotyls from all Seedlings for all Genotypes
% Extract Seedlings
tSeeds = tic;
ex.FindSeedlingAllGenotypes(verbose, par, mth);
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
%% Generate training set of CircuitJB objects
if doTraining
    figclr(figs(1));
    num = 2;
    typ = 1;
    flp = 1;
    sv  = 1;
    vis = 1;
    
    CRCS = randomCircuits(ex, num, typ, flp, sv, vis);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Process manually-drawn contours
    % Generate Curve objects and convert between reference frames
    C = ex.combineContours;
    
    arrayfun(@(x) x.CreateCurves('redo', par), C, 'UniformOutput', 0);
    D = arrayfun(@(x) x.Curves, C, 'UniformOutput', 0);
    D = cat(1, D{:});
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Display gallery of manually-drawn contours
    g  = ex.combineGenotypes;
    g1 = g(1);
    
    figclr(figs(2));
    if doonce
        % Just check the first image of first Genotype
        for n  = 1 : g1.TotalImages
            myimagesc(g1.getImage(n));
            ttl = sprintf('%s Frame %d', fixtitle(g1.GenotypeName), n);
            title(ttl);
            pause(ptime);
        end
    else
        % Iterate through all images of first Genotype
        n = M(1 : g1.TotalImages);
        myimagesc(g1.getImage(n));
        ttl = sprintf('%s Frame %d', fixtitle(g1.GenotypeName), n);
        title(ttl);
    end
else
    [figs , fnms] = deal([]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save Experiment data
if save_data
    ex.SaveExperiment;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save Figures
if save_figs
    saveFiguresJB(figs, fnms);
end

A = ex;
end


function args = parseInputs(varargin)
%% Parse input parameters
% Need descriptions for all these parameters
% pcaX, pcaY, dim2chg, mns, eigs, scrs, pc2chg, upFn, dwnFn, stp, f

p = inputParser;
p.addRequired('dataDir');
p.addOptional('doonce', 1);
p.addOptional('doTraining', 0);
p.addOptional('verbose', 1);
p.addOptional('par', 0);
p.addOptional('figs', 1:2);
p.addOptional('save_data', 0);
p.addOptional('save_figs', 0);
p.addOptional('mth', 'new');

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end

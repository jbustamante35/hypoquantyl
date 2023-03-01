function I = getTrainingIndex(Ein, N, rng, minf)
%% getTrainingIndex: returns matrix of indices to serve as training data input
% This function takes in an Experiment object and randomly extracts a matrix of
% indices to serve as input for the trainCircuits function. It searches through
% the data in the Experiment and extracts N random genotypes and seedlings
% within the percentage range defined in the R parameter.
%
% Usage:
%   I = getTrainingIndex(Ein, N, rng, minf)
%
% Input:
%   Ein: Experiment object with Genotype and Seedling objects
%   N: total number of objects to train (default 12)
%   rng: range within lifetime to extract frames (default [0.2 , 0.8])
%   minf: minimum number of frames in Lifetime to draw from (default 20)
%
% Output:
%   I: [N x 3] matrix representing [Genotype Seedling frame] to train
%

if nargin < 2; N    = 12;          end
if nargin < 3; rng  = [0.2 , 0.8]; end
if nargin < 4; minf = 20;          end

%% Convert range to decimals first
if sum(rng >= 2); rng = rng / 10; end

% Function handles to get random index
m = @(x) randi([1 , length(x)], 1);
M = @(x) x(m(x));

%% Filter out Genotypes with too few images and draw random set
gg   = arrayfun(@(x) x.TotalImages > minf, Ein.combineGenotypes);
gIdx = pullRandom(gg, N)';
g    = Ein.getGenotype(gIdx);

%% Filter out Seedlings with too few frames and draw random set
sg   = arrayfun(@(y) ...
    cell2mat(arrayfun(@(x) y.getSeedling(x).Lifetime >= minf, ...
    1 : y.NumberOfSeedlings, 'UniformOutput', 0)), g, 'UniformOutput', 0);
sIdx = cellfun(@(x) pullRandom(x, 1), sg);
s    = arrayfun(@(x) g(x).getSeedling(sIdx(x)), 1 : N, 'UniformOutput', 0);

%% Get random frames within range of percentages for each Seedling
% Get array of untrained frames within selected range in lifetime
hIdx = cellfun(@(x) x.MyHypocotyl.getUntrainedFrames, s, 'UniformOutput', 0)';
rIdx = cellfun(@(x) ceil(rng(1) * x.Lifetime) : ceil(rng(2) * x.Lifetime), ...
    s, 'UniformOutput', 0)';

% Select a random untrained frame
fIdx = cell2mat(cellfun(@(r,h) M(r(ismember(r, h))), ...
    rIdx, hIdx, 'UniformOutput', 0));

%% Combine indices to get final output matrix
I = unique(sortrows([gIdx , sIdx , fIdx]), 'rows', 'stable');
end
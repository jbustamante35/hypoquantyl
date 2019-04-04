function I = getTrainingIndex(Ein, N, rng)
%% getTrainingIndex: returns matrix of indices to serve as training data input
% This function takes in an Experiment object and randomly extracts a matrix of
% indices to serve as input for the trainCircuits function. It searches through
% the data in the Experiment and extracts N random genotypes and seedlings 
% within the percentage range defined in the R parameter. 
%
% Usage:
%   I = getTrainingIndex(Ein, N, rng)
%
% Input:
%   Ein: Experiment object with Genotype and Seedling objects
%   N: total number of objects to train
%   rng: percentage range within a Seedling's lifetime to extract frame numbers
%   
% Output:
%   I: [N x 3] matrix representing [Genotype Seedling frame] to train
%

%% Function handles to get random index
m = @(x) randi([1 length(x)], 1);
M = @(x) x(m(x));

%% Get random Genotypes from Experiment
gIdx = randi([1 Ein.NumberOfGenotypes], [N 1]);
g    = Ein.getGenotype(gIdx);

%% Get random Seedling from each Genotype
sIdx = arrayfun(@(x) m(x.getSeedling(':')), g, 'UniformOutput', 0);
sIdx = cat(1, sIdx{:});
s    = arrayfun(@(x) g(x).getSeedling(sIdx(x)), 1:N, 'UniformOutput', 0);

%% Get random frames within range of percentages for each Seedling
fIdx = cellfun(@(x) M(ceil(rng(1) * x.Lifetime) : ceil(rng(2) * x.Lifetime)), ...
    s, 'UniformOutput', 0);
fIdx = cat(1, fIdx{:});

%% Combine indices to get final output matrix
I = [gIdx sIdx fIdx];

end
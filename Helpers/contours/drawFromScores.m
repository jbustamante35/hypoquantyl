function [R, rIdx] = drawFromScores(S)
%% drawFromScores: returns random PCA scores from a distribution of the inputted scores
% This function takes in an [N x m] matrix of m principal components from an N-sized training set.
% For each PC, a new distribution of 100 scores is generated to reflect the distribution of the
% original dataset. 
%
% For example, in an array of 20 scores from -0.2 to 1.1, the distribution to randomly draw from
% would be an array of 100 scores from -0.2 to 1.1 where the values still follow the trend of the
% original array. This means there are more values to draw from, but the probability of taking
% outliers are unchanged. 
% 
% Usage:
%   [R, rIdx] = drawFromScores(S)
%
% Input:
%   S: [N x m] matrix of m principal components from training set of N data
%
% Output:
%   R: vector of PCA scores drawn from distribution of inputted scores S
%

%% Determine total number of principal components and generate normal distribution
numComps   = size(S, 2);
drawRandom = @(x) randi([1 length(x)], 1, numComps);
makeDistrb = @(x) linspace(min(S(:,x)), max(S(:,x)))';

%% Draw random index from distribution of all PCs
rDst = arrayfun(@(x) makeDistrb(x), 1:numComps, 'UniformOutput', 0);
rDst = cat(2,rDst{:});
rIdx = drawRandom(rDst);
R    = arrayfun(@(x) rDst(rIdx(x), x), 1:numComps, 'UniformOutput', 0);
R    = cat(2, R{:});

end
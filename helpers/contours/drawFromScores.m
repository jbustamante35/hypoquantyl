function [R, rIdx] = drawFromScores(X, len)
%% drawFromScores: randomly draw from a distribution of PC scores
% This function takes in an [N x m] matrix of m principal components from an 
% N-sized training set. For each PC, a new distribution of 100 scores is 
% generated to reflect the distribution of the original dataset. 
%
% For example, in an array of 20 scores from -0.2 to 1.1, the distribution to 
% randomly draw from would be an array of 100 scores from -0.2 to 1.1 where the 
% values still follow the trend of the original array. This means there are more 
% values to draw from, but the probability of taking outliers are unchanged. 
%
% NOTE [02-11-2019]
% This only draws a random number from the total range of scores, and does not
% draw randomly draw from the scores' distribution. 
% 
% NOTE [02-11-2019]
% I fixed it by using my interpolateOutline function instead of the function
% handle that used linspace. 
%
% Usage:
%   [R, rIdx] = drawFromScores(X, len)
%
% Input:
%   X: [N x m] matrix of m principal components from training set of N data
%   len: length of the distribution to generate
%
% Output:
%   R: vector of PCA scores drawn from distribution of inputted scores S
%   rIdx: indices of where R was chosen
%

%% Determine total number of principal components and generate normal distribution
numComps   = size(X, 2);
drawRandom = @(x) randi([1 size(x,1)], 1, numComps);

%% Draw random index from distribution of all PCs
rDst = interpolateOutline(X, len);
rIdx = drawRandom(rDst);
R    = arrayfun(@(x) rDst(rIdx(x), x), 1:numComps, 'UniformOutput', 0);
R    = cat(2, R{:});

end
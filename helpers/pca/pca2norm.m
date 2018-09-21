function N = pca2norm(S, V, M)
%% pca2norm: convert PCA scores to estimated original values
% This function converts PCA scores to an estimate of the original value by taking the dot product
% of the scores with the transpose of the corresponding eigenvector, then adding the mean. The 
% function is illustrated as so:
%   N = (S * V') + M
% 
% Usage:
%   N = pca2norm(S, V, M)
%
% Input:
%   S: [N x m] array representing N scores of m principal components 
%   V: [d x m] array representing the eigenvectors in d dimensions of m principal components
%   M: [1 x d] array representing mean values of d dimensions
%
% Output:
%   N: [N x d] array representing the estimated conversion of N data in d dimensions
%

N = (S * V') + M;

end
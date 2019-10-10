function [V, T] = variance_explained(E, P)
%% variance_explained: calculate variance explained from given data set D
% This function takes the eigenvalues of a dataset after PCA to assess the
% variance explained by each principal component. Eigenvalues should be inputted
% as a diagonal matrix.
%
% Usage:
%   [V, T] = variance_explained(E, P)
%
% Input:
%   E: eigenvalues from the dataset to assess variance
%   P: percentage of explained variance to cut-off
%
% Output:
%   V: variance explained from eigenvalues of dataset E
%   T: number of components equaling the cutoff percentage P
%

%% Cumulative sum of each variance over the sum of all the variances 
V = cumsum(diag(E) / sum(diag(E)));
T = numel(find(V <= P)) + 1;

end
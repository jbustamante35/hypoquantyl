function [V, T] = variance_explained(D, P)
%% variance_explained: calculate variance explained from given data set D
% This function
% does some stuff.
%
% Usage:
%   [V, T] = variance_explained(D, P)
%
% Input:
%   D: dataset to assess variance
%   P: percentage of explained variance to cut-off
%
% Output:
%   V: variance explained from dataset D
%   T: number of components equaling the cutoff percentage P
%

%% Cumulative sum of each variance over the sum of all the variances 
V = cumsum(diag(D) / sum(diag(D)));
T = numel(find(V <= P)) + 1;
end
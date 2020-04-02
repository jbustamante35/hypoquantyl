function [V, T] = variance_explained(E, P)
%% variance_explained: compute variance explained from PCA
% This function takes the eigenvalues from PCA to compute the variance
% explained by each principal component. Eigenvalues should be inputted as a
% diagonal matrix, and not as a vector.
%
% Usage:
%   [V, T] = variance_explained(E, P)
%
% Input:
%   E: eigenvalues from PCA
%   P: cut-off percentage to cpmute explained variance
%
% Output:
%   V: variance explained
%   T: number of PCs at the cut-off percentage
%

%% Cumulative sum of each variance over the sum of all the variances
% Default to 100% variance explained
if nargin < 2
    P = 1;
end

V = cumsum(diag(E) / sum(diag(E)));
T = numel(find(V <= P)) + 1;

end

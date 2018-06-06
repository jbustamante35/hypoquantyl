function PC = multiPCAgetoptimal(V, P)
%% multiPCAgetoptimal: get optimal number of PCs using variance explained cutoff
%
%
% Usage:
%   PC = multiPCAgetoptimal(V, P)
%
% Input:
%   V: array of eigenvalues for both x-/y-coordinates
%   P: cutoff percentage of variance explained
%
% Output:
%   PC: number of Principal Components corresponding to variance explained P
%
[~, PC] = variance_explained(V.EigValues, P);
end
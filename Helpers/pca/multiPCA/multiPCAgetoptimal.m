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
szA     = size(V,1);
szB     = size(V,2);
[~, PC] = variance_explained(V.EigValues, P);
% [~, PC] = arrayfun(@(x) variance_explained(x.EigValues, P), V, 'UniformOutput', 0);
% PC      = cat(1, PC{:});
% PC      = reshape(PC, [szB szA]);
end
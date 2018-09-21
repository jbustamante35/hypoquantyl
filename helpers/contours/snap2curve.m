function snp = snap2curve(pts, crd)
%% snap2curve: snap coordinates to closest point along curve
% This function takes [m x n] coordinate positions, finds the index along [p x n] coordinate matrix,
% and returns an [m x n] matrix, where coordinates are replaced by nearest coordinates in crds. 
%
% Usage:
%   snp = snap2curve(pts, crd)
% 
% Input:
%   pts: [m x n] matrix of coordinates near curve 
%   crd: [p x n] matrix of coordinates on curve to search along
%
% Output:
%   snp: [m x n] matrix of coordinates corresponding to nearest point from pts on curve crd
%

%% Find indices corresponding to nearest distance from coordinates in pts
idx = dsearchn(crd, pts);
snp = crd(idx, :);
end


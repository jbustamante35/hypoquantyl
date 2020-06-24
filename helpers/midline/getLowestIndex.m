function [lowIdx , lowVal] = getLowestIndex(X)
%% getLowestIndex: return row index in image with lowest y-coordinate
% This
%
% Usage:
%   [lowIdx , lowVal] = getLowestIndex(X)
%
% Input:route
%   X: matrix of x-/y-coordinates
%
% Output:
%   lowIdx: row index of coordinate with lowest y-coordinate
%   lowVal: coordinates corresponding to lowest index
%

[~ , maxRowIdxs] = max(X);
lowIdx           = maxRowIdxs(2);
lowVal           = X(lowIdx,:);

end
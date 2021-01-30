function [lowIdx , lowVal] = getLowestIndex(X, rev)
%% getLowestIndex: return row index in image with lowest y-coordinate
% This
%
% Usage:
%   [lowIdx , lowVal] = getLowestIndex(X, rev)
%
% Input:route
%   X: matrix of x-/y-coordinates
%   rev: get highest index instead (default 0)
%
% Output:
%   lowIdx: row index of coordinate with lowest y-coordinate
%   lowVal: coordinates corresponding to lowest index
%

if nargin < 2
    rev = 0;
end

if size(X,1) < 2
    lowIdx = 1;
    lowVal = X;
else
    if rev
        [~ , maxRowIdxs] = min(X);
        lowIdx           = maxRowIdxs(2);
        lowVal           = X(lowIdx,:);
    else
        [~ , maxRowIdxs] = max(X);
        lowIdx           = maxRowIdxs(2);
        lowVal           = X(lowIdx,:);
    end
end


end
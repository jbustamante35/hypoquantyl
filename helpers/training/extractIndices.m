function [I, D] = extractIndices(idx, ttlSegs, spltData)
%% extractIndicies: extract indices of contour by splitting by segments
% This function
%
% Usage:
%   [I, D] = extractIndices(idx, ttlSegs, spltData)
%
% Input:
%   idx: index to extract coordinates from
%   ttlSegs: total number of segments to split full dataset by
%   spltData: data to actually split dateset, set to 0 to return only indicies
%
% Output:
%   I: array of indices corresponding to idx
%   D: subset of splitData corresponding to indices from I
%

splitIdx = @(c,s) (((s * c) - s) + 1) : ((s * (c+1)) - s);
getIdx   = @(x)   splitIdx(x, ttlSegs);

I = getIdx(idx);

if nargin > 2 && ~isempty(spltData)
    D = spltData(I,:);
else
    D = [];
end

end
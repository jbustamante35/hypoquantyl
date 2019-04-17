function [D, I] = extractIndices(idx, ttlSegs, spltData)
%% extractIndicies: extract indices of contour by splitting by segments
% This function
%
% Usage:
%   [D, I] = extractIndices(idx, ttlSegs, spltData)
%
% Input:
%   idx: index to extract coordinates from
%   ttlSegs: total number of segments to split full dataset by
%   spltData: data to actually split dateset, set to 0 to return only indicies
%
% Output:
%   D: subset of splitData corresponding to indices from I
%   I: array of indices corresponding to idx
%

splitIdx = @(c,s) (((s * c) - s) + 1) : ((s * (c+1)) - s);
getIdx   = @(x)   splitIdx(x, ttlSegs);

I = getIdx(idx);

if ~isempty(spltData)
    D = spltData(I,:)';
else
    D = [];
end

end
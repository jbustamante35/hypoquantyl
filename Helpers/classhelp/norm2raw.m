function raw = norm2raw(nrm, apt, aid)
%% norm2raw: function to convert normalized-reindexed coordinates to original coordinates
% This function takes coordinates that were normalized in the way ContourJB objects are normalized
% and converts them back to their original image coordinates. The general strategy is to add back
% the AnchorPoint apt parameter then shift by that AnchorPoint's index aid parameter.
%
% Usage:
%   raw = norm2raw(nrm, apt, aid)
%
% Input:
%   nrm: x-/y-coordinates in normalized indices
%   apt: AnchorPoint in original coordinates in which normalization set to [0 0]
%   aid: AnchorPoint index in original coordinates in which normalization set to index 0
%
% Output:
%   raw: x-/y-coordinates in original image coordinates
%

%% Shift to original coordinates then add back origin
shft = circshift(nrm, aid-1);
raw  = shft + apt;

end
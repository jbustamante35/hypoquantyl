function [Y , segs] = prepareTargets(cntr, len, stp, mth, toCenter)
%% prepareTargets: get initial displacement vectors
%
%
% Usage:
%   Y = prepareTargets(cntr, len, step)
%
% Input:
%   cntr: ground truth contour to serve as target for displacement vectors
%   len: length of segments to split contour
%   stp: size of steps between splitting segments
%   mth: splitting method to use (default 1)
%   toCenter: index to set new center point for each segment (default 1)
%
% Output:
%   Y: middle index of all segments
%   segs: segments from split contour
%

if nargin < 4
    mth      = 1;
    toCenter = 1;
end

segs   = split2Segments(cntr, len, stp, mth, toCenter);
hlfIdx = ceil(size(segs,1) / 2);
Y      = [squeeze(segs(hlfIdx,:,:))' , ones(size(segs,3), 1)];

end


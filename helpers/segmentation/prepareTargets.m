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
%   stp: size of steps between splitting segments (default 1)
%   mth: splitting method to use (default 1)
%   toCenter: index to set new center point for each segment (default len / 2)
%
% Output:
%   Y: middle index of all segments
%   segs: segments from split contour
%

switch nargin
    case 2
        stp      = 1;
        mth      = 1;
        toCenter = round(len / 2);
    case 3
        mth      = 1;
        toCenter = round(len / 2);
    case 4
        toCenter = round(len / 2);
end

segs = split2Segments(cntr, len, stp, mth, toCenter);

switch size(cntr,2)
    case 2
        Y = [squeeze(segs(toCenter,:,:))' , ones(size(segs,3), 1)];
    case 3
        Y = squeeze(segs(toCenter,:,:))';
end


end


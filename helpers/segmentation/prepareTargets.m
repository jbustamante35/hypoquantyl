function [Y , segs] = prepareTargets(cntr, len, stp, mth, toCenter)
%% prepareTargets: get initial displacement vectors
%
%
% Usage:
%   [Y , segs] = prepareTargets(cntr, len, stp, mth, toCenter)
%
% Input:
%   cntr: ground truth contour to serve as target for displacement vectors
%   len: length of segments to split contour (default 25)
%   stp: size of steps between splitting segments (default 1)
%   mth: splitting method to use (default 1)
%   toCenter: index to set new center point for each segment (default len / 2)
%
% Output:
%   Y: middle index of all segments
%   segs: segments from split contour

if nargin < 2; len      = 25;             end
if nargin < 3; stp      = 1;              end
if nargin < 4; mth      = 1;              end
if nargin < 5; toCenter = round(len / 2); end

segs = split2Segments(cntr, len, stp, mth, toCenter);

switch size(cntr,2)
    case 2
        Y = [squeeze(segs(toCenter,:,:))' , ones(size(segs,3), 1)];
    case 3
        Y = squeeze(segs(toCenter,:,:))';
end
end
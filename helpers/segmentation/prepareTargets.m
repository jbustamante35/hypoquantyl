function Y = prepareTargets(cntr, len, stp)
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
%

segs   = split2Segments(cntr, len, stp, 2);
hlfIdx = ceil(size(segs,1) / 2);
Y      = [squeeze(segs(hlfIdx,:,:))' , ones(size(segs,3), 1)];

end


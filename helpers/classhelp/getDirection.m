function [drc1 , drc2] = getDirection(trc, seg_lengths)
%% getDirection: determine direction of curve
%
% Usage:
%   [drc1 , drc2] = getDirection(trc, seg_lengths)
%
% Input:
%   trc: curve
%   seg_lengths: segment lengths
%
% Output:
%   drc1: left-facing (-1) or right-facing (2)
%   drc2: left-facing ('left') or right-facing ('right')

if nargin < 2; seg_lengths = [53 , 52 , 53 , 51]; end

l1 = getSegmentLength(trc, 1, seg_lengths);
l3 = getSegmentLength(trc, 3, seg_lengths);

if l3 > l1
    drc1 = -1;
    drc2 = 'left';
else
    drc1 = 1;
    drc2 = 'right';
end
end

function lng = getSegmentLength(trc, num, seg_lengths)
%% getSegmentLength
seg = getSegment(trc, num, seg_lengths);
lng = sum(sum(diff(seg, 1, 1).^2, 2).^0.5);
end
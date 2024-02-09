function [seg , crd] = getSegment(trc, idx, slens, iadd)
%% getSegment: get top, bottom, left, or right of a clipped contour
%
% Usage:
%   [seg , crd] = getSegment(trc, idx, slens, iadd)
%
% Input:
%   trc: curve must be closed loop
%   idx: segment index [1:left|2:top|3:right|4:bottom] (default 4)
%   slens: segment lengths (default [53 , 52 , 53 , 51])
%   iadd: additional indices to grab from ends of segment (default [0 , 0])
%
% Output:
%   seg: segment coordinates
%   crd: segment indices

if nargin < 2; idx   = 4;                   end
if nargin < 3; slens = [53 , 52 , 53 , 51]; end
if nargin < 4; iadd  = [0 , 0];             end

switch idx
    case 1
        % Left Segment
        str = getIndex(1, slens) + iadd(1);
        stp = getIndex(2, slens) - 1 + iadd(2);
    case 2
        % Top Segment
        str = getIndex(2, slens) + iadd(1);
        stp = getIndex(3, slens) - 1 + iadd(2);
    case 3
        % Right Segment
        str = getIndex(3, slens) + iadd(1);
        stp = getIndex(4, slens) - 1 + iadd(2);
    case 4
        % Bottom Segment
        str = getIndex(4, slens) + iadd(1);
        stp = getIndex(5, slens) - 1 + iadd(2);
    otherwise
        fprintf(2, '');
        seg = [];
        return;
end

crd = str : stp;
seg = trc(crd,:);
end

function idx = getIndex(num, slens)
%%
L   = cumsum([1 , slens]);
idx = L(num);
end
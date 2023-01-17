function apts = bwAnchorPoints(bw, ln, bgap)
%% bwAnchorPoints: return anchor points from bw image
% Dammit I wrote this a long time ago and forgot how it works.
%
% Usage:
%   apts = bwAnchorPoints(bw, ln, bgap)
%
% Input:
%   bw: inputted bw image
%   ln: cutoff length for lowest anchorpoint
%   bgap: distance to set [top , bottom , left , right] crop buffer [default 0]
%
% Output:
%   apts: [p x 2] vector defining x-/y-coordinates of p anchor points
%

if nargin < 3; bgap = 0; end

dd    = bwconncomp(bw);
p     = 'PixelList';
props = regionprops(dd, p);
pList = props.PixelList;
apts  = calcAnchorPoints(pList, ln, bgap);
end

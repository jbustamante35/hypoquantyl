function apts = bwAnchorPoints(bw, ln)
%% bwAnchorPoints: return anchor points from bw image
% Dammit I wrote this a long time ago and forgot how it works.
%
% Usage:
%   apts = bwAnchorPoints(bw, ln)
%
% Input:
%   bw: inputted bw image
%   ln: cutoff length for lowest anchorpoint
%
% Output:
%   apts: [p x 2] vector defining x-/y-coordinates of p anchor points
%

bw      = imcomplement(bw);
dd      = bwconncomp(bw);
p       = 'PixelList';
props   = regionprops(dd, p);
pList   = props.PixelList;
apts = calcAnchorPoints(pList, ln);

end

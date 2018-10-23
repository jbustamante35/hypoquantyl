function APoints = bwAnchorPoints(bw, ln)
%% bwAnchorPoints: return anchor points from bw image
% Dammit I wrote this a long time ago and forgot how it works.
%
% Usage:
%   APoints = bwAnchorPoints(bw, ln)
%
% Input:
%   bw: inputted bw image
%   ln: cutoff length for lowest anchorpoint 
%
% Output:
%   APoints: [p x 2] vector defining x-/y-coordinates of p anchor points
%

bw     = imcomplement(bw);
dd      = bwconncomp(bw);
p       = 'PixelList';
props   = regionprops(dd, p);
pList   = props.PixelList;
APoints = calcAnchorPoints(pList, ln);

end
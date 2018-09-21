function APoints = bwAnchorPoints(bw, ln)
%% bwAnchorPoints: return anchor points from bw image
%
%
% 
% Input:
%   bw: inputted bw image
%   ln: cutoff length for lowest anchorpoint 

dd      = bwconncomp(bw);
p       = 'PixelList';
props   = regionprops(dd, p);
pList   = props.PixelList;
APoints = calcAnchorPoints(pList, ln);

end
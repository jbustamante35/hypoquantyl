function [btrc , tidx , bcrd, bcrds] = resetContourBase(trc, nrm)
%% resetContourBase: normalize curve to set center of base to origin
%
%
% Usage:
%   [btrc , ridx , bcrd, bcrds] = resetContourBase(trc)
%
% Input:
%   trc: a curve
%   nrm: re-center to new origin (1) or keep in same frame (0) (default 1)
%
% Output:
%   btrc: curve with re-centered origin
%   tidx: index of base coordinate
%   bcrd: coordinate of midpoint of base
%   bcrds: all coordinates of base
%

%%
if nargin < 2
    nrm = 1;
end

% Open curve and get base
trc(1,:) = [];
lbl      = labelContour(trc);

% Find vector halfway between end points and snap to closest point on curve
bcrds = trc(lbl,:);
[~ , i1] = max(bcrds(:,1));
[~ , i2] = min(bcrds(:,1));
v1       = bcrds(i1,:);
v2       = bcrds(i2,:);
vhlf  = ((v1 - v2) * 0.5) + v2;

% Snap half-way vector to curve then re-center coordinates
[bcrd , tidx] = snap2curve(vhlf, trc);
if nrm
    trc = trc - bcrd;
end

bshft = -tidx + 1;
btrc  = circshift(trc, bshft);
btrc  = [btrc ; btrc(1,:)];

end
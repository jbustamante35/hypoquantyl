function showZPatch(zpatch, zdata, cIdx, sIdx, img, mids, f)
%% showZPatch: visualize a Z-Patch from a Z-Vector slice
%
%
% Usage:
%   showZPatch(zpatch, zdata, cIdx, sIdx, img, mids, f)
%
% Input:
%   zpatch: image patch outputted from setZPatch function
%   zdata: extra data outputted from setZPatch function
%   cIdx: index of the Curve from the dataset
%   sIdx: index of the segment of the Curve
%   img: corresponding image of the Curve
%   mids: midpoint coordinates from the Z-Vector
%   f: index of figure handles to show data
%
% Output: n/a
%

%% Extract data to show
boxT = zdata.CropBoxFwd;
boxB = zdata.CropBoxRev;
mid  = boxT(1:2);
tngT = boxT(3:4);
nrmT = boxT(5:6);
tngB = boxB(3:4);
nrmB = boxB(5:6);
envT = zdata.Envelope.UpperPoints;
envB = zdata.Envelope.LowerPoints;

%% Show slice and patch
set(0, 'CurrentFigure', f);
cla;clf;

% Image with midpoint coordinates plotted
subplot(121);
imagesc(img);
colormap gray;
axis image;
hold on;
plt(mids, 'y.', 8);

% Reversed and scaled vectors
plt([tngB ; tngT], 'r--', 2);
plt([nrmB ; nrmT], 'b--', 2);
plt([mid ; tngT], 'r-', 2);
plt([mid ; nrmT], 'b-', 2);
plt(mid, 'go', 5);
plt(envT, 'g.', 2);
plt(envB, 'm.', 2);
ttl = sprintf('Z-Vector Box\nHypocotyl %d | Segment %d', cIdx, sIdx);
title(ttl);

% The Patch
subplot(122);
imagesc(zpatch);
colormap gray;
axis image;
ttl = sprintf('Z-Patch\nHypocotyl %d | Segment %d', cIdx, sIdx);
title(ttl);

hold off;
drawnow;

end
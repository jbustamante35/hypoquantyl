function showSPatch(spatch, sdata, cIdx, sIdx, img, seg, cntr, f)
%% showSPatch: vizualize S-Vector with corresponding S-Patches
%
%
% Usage:
%   showSPatch(spatch, sdata, cIdx, sIdx, img, seg, cntr, f)
%
% Input:
%   spatch: resulting image patch from setSPatch function
%   sdata: resulting extra data structure from setSPatch function
%   cIdx: index of curve from dataset [for figure title]
%   sIdx: index of segmetn from curve [for figure title]
%   img: corresponding image from segment and spatch
%   seg: x-/y-coordinates of segment corresponding to spatch
%   cntr: x-/y-coordinates of full contour
%   f: index of figure handle
%
% Output: n/a
%

%% Extract data to be shown
envOut = sdata.OuterData.eCrds;
envInn = sdata.InnerData.eCrds;

%% Show slice and patch
set(0, 'CurrentFigure', f);
cla;clf;

% Segment and envelope on image
subplot(121);
imagesc(img);
colormap gray;
axis image;
hold on;
plt(cntr, 'y.', 5);
plt(envOut, 'm.', 2);
plt(envInn, 'g.', 2);
plt(seg, 'b-', 1);
plt(seg(1,:), 'b.', 10);
plt(seg(end,:), 'r.', 10);
hold off;
ttl = sprintf('Envelope Structure\nHypocotyl %d | Segment %d', cIdx, sIdx);
title(ttl);

% The Patch
subplot(122);
imagesc(spatch);
colormap gray;
axis image;
ttl = sprintf('S-Patch\nHypocotyl %d | Segment %d', cIdx, sIdx);
title(ttl);

end


function showSPatch(spatch, sdata, seg, img, cIdx, sIdx, f)
%% showSPatch: vizualize S-Vector with corresponding S-Patches
% 
% 
% Usage:
%   showSPatch(spatch, sdata, seg, img, cIdx, sIdx, f)
%
% Input:
%   spatch: resulting image patch from setSPatch function
%   sdata: resulting extra data structure from setSPatch function
%   seg: x-/y-cordinates of segment corresponding to spatch
%   img: corresponding image from segment and spatch
%   cIdx: index of curve from dataset [for figure title]
%   sIdx: index of segmetn from curve [for figure title]
%   f: index of figure handle
%

%%
set(0, 'CurrentFigure', f);
cla;clf;

% Segment and envelope on image
subplot(121);
imagesc(img);
colormap gray;
axis image;
hold on;
plt(sdata.OuterData.eCrds, 'g.', 2);
plt(sdata.InnerData.eCrds, 'y.', 2);
plt(seg, 'm-', 1);
plt(seg(1,:), 'b.', 10);
plt(seg(end,:), 'r.', 10);
ttl = sprintf('Envelope Structure\nHypocotyl %d | Segment %d', cIdx, sIdx);
title(ttl);

% Image patch
subplot(122);
imagesc(spatch);
colormap gray;
axis image;
ttl = sprintf('S-Patch\nHypocotyl %d | Segment %d', cIdx, sIdx);
title(ttl);

end
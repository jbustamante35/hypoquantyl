function showPatches(spatch, zpatch, sdata, zdata, cIdx, sIdx, img, mids, seg, cntr, f)
%% showPatches: vizualize both Z and S Patches on image
%
%
% Usage:
%   showPatches(spatch, zpatch, sdata, zdata, cIdx, sIdx, img, mids, seg, cntr, f)
%
% Input:
%
%
% Output: n/a
%

%% Extract data to be shown
% Normals-Tangents
boxTop = zdata.CropBoxTop;
boxBot = zdata.CropBoxBot;
mid    = boxTop(1:2);
tngTop = boxTop(3:4);
nrmTop = boxTop(5:6);
tngBot = boxBot(3:4);
nrmBot = boxBot(5:6);

% Envelopes
envTop = zdata.Envelope.UpperPoints;
envBot = zdata.Envelope.LowerPoints;
envOut = sdata.OuterData.eCrds;
envInn = sdata.InnerData.eCrds;

%% Show Z-/S-Patches envelopes and slices
set(0, 'CurrentFigure', f);
cla;clf;

% Image with coordinates and envelope plotted
subplot(121);
imagesc(img);
colormap gray;
axis image;
hold on;

plt(cntr, 'y.', 5);
plt(mids, 'rv', 1);

plt(envOut, 'm.', 10);
plt(envInn, 'g.', 10);

plt(seg, 'y-', 1);
plt(seg(1,:), 'b.', 15);
plt(seg(end,:), 'r.', 15);

plt(envTop, 'r.', 10);
plt(envBot, 'b.', 10);

plt([tngBot ; tngTop], 'r--', 2);
plt([nrmBot ; nrmTop], 'b--', 2);
plt([mid ; tngTop], 'r-', 2);
plt([mid ; nrmTop], 'b-', 2);
plt(mid, 'go', 5);

ttl = sprintf('Envelope Structures\nHypocotyl %d | Segment %d', cIdx, sIdx);
title(ttl);
hold off;

% S-Patch
subplot(222);
imagesc(spatch);
colormap gray;
axis image;
ttl = sprintf('S-Patch');
title(ttl);

% Z-Patch
subplot(224);
imagesc(zpatch);
colormap gray;
axis image;
ttl = sprintf('Z-Patch');
title(ttl);

end
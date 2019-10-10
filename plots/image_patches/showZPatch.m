function fig = showZPatch(zpatch, zdata, cIdx, sIdx, img, mids, f, VER, scls)
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

if nargin < 8
    VER = 1;
end

switch VER
    case 1
        % Visualize using old version of Z-Patch and Z-Data
        fig = showVersion1(zpatch, zdata, cIdx, sIdx, img, mids, f);
        
    case 2
        % Visualize using method with structured functions as Z-Data
        fig = showVersion2(zdata, cIdx, sIdx, img, mids, f, scls);
        
    otherwise
        fprintf(2, 'Version should be [1|2]\n');
        fig = [];
end

end

function fig = showVersion1(zpatch, zdata, cIdx, sIdx, img, mids, f)
%% Extract data to be shown
boxT = zdata.CropBoxTop;
boxB = zdata.CropBoxBot;
mid  = boxT(1:2);
tngT = boxT(3:4);
nrmT = boxT(5:6);
tngB = boxB(3:4);
nrmB = boxB(5:6);
envT = zdata.Envelope.UpperPoints;
envB = zdata.Envelope.LowerPoints;

%% Show slice and patch
fig = figure(f);
set(0, 'CurrentFigure', f);
cla;clf;

% Image with midpoint coordinates plotted
subplot(121);
imagesc(img);
colormap gray;
axis image;
hold on;
plt(mids, 'y.', 5);
plt(envT, 'g.', 2);
plt(envB, 'm.', 2);
plt([tngB ; tngT], 'r--', 2);
plt([nrmB ; nrmT], 'b--', 2);
plt([mid ; tngT], 'r-', 2);
plt([mid ; nrmT], 'b-', 2);
plt(mid, 'go', 5);
hold off;
ttl = sprintf('Z-Vector Box\nHypocotyl %d | Segment %d', cIdx, sIdx);
title(ttl);

% The Patch
subplot(122);
imagesc(zpatch);
colormap gray;
axis image;
ttl = sprintf('Z-Patch\nHypocotyl %d | Segment %d', cIdx, sIdx);
title(ttl);

end

function fig = showVersion2(zdata, cIdx, sIdx, img, mids, f, scls)
%%

nscls = size(scls,1);
dCrds = arrayfun(@(x) zdata.domCrds(sIdx,x), 1:nscls, 'UniformOutput', 0);

% Setup figure
fig = figure(f);
set(0, 'CurrentFigure', fig);
cla;clf;

%% Image with Midpoints and Domain Coordinates
% Image
subplot(121);
imagesc(img);
colormap gray;
axis image;
axis off;
hold on;

% Plot Midpoints, Tangents, and Normals 
% I can't believe how long I spent on this
plt(mids, 'g.', 3);
plt(mids(sIdx,:), 'ro', 10);

% ptcSize = cellfun(@(x) size(x,1), dCrds, 'UniformOutput', 0);
% domSize = cellfun(@(x) ceil(sqrt(size(x,1))), dCrds, 'UniformOutput', 0);
% midCrd  = cellfun(@(c,p) c(ceil(p / 2),:), dCrds, ptcSize, 'UniformOutput', 0);
% 
% rgtTng = cellfun(@(p,d) (round(p / 2) + round(d / 2))-1, ptcSize, domSize, 'UniformOutput', 0);
% lftTng = cellfun(@(p,d) (round(p / 2) - round(d / 2))+1, ptcSize, domSize, 'UniformOutput', 0);
% topNrm = cellfun(@(p,d) p - round(d / 2) + 1, ptcSize, domSize, 'UniformOutput', 0);
% dwnNrm = cellfun(@(d)   round(d / 2), domSize, 'UniformOutput', 0);
% 
% rtng = cellfun(@(c,x) c(x,:), dCrds, rgtTng, 'UniformOutput', 0);
% ltng = cellfun(@(c,x) c(x,:), dCrds, lftTng, 'UniformOutput', 0);
% tnrm = cellfun(@(c,x) c(x,:), dCrds, topNrm, 'UniformOutput', 0);
% dnrm = cellfun(@(c,x) c(x,:), dCrds, dwnNrm, 'UniformOutput', 0);
% 
% cellfun(@(m,x) plt([m ; x], 'b-', 1), midCrd, rtng, 'UniformOutput', 0);
% cellfun(@(m,x) plt([m ; x], 'r-', 1), midCrd, ltng, 'UniformOutput', 0);
% cellfun(@(m,x) plt([m ; x], 'y-', 1), midCrd, tnrm, 'UniformOutput', 0);
% cellfun(@(m,x) plt([m ; x], 'g-', 1), midCrd, dnrm, 'UniformOutput', 0);

% Plot domain coordinates
hlf   = ceil(size(dCrds{1},1) / 2);
cellfun(@(x) plt(x(1:hlf,:), '.', 3), dCrds, 'UniformOutput', 0);
cellfun(@(x) plt(x(hlf+1:end,:), '.', 3), dCrds, 'UniformOutput', 0);

ttl = sprintf('Z-Patch Domain\nHypocotyl %d | Segment %d', cIdx, sIdx);
title(ttl);

%% The Patches
rows = nscls;

for scl = 1 : nscls
    subplot(rows, 2, scl*2);
    ptch = zdata.vec2patch(sIdx,scl);
    imagesc(ptch);
    axis image;
    axis off;
    ttl = sprintf('Scale %s', num2str(scls(scl,:)));
    title(ttl);
end

end




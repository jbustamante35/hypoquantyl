function figs = plotNormalizationMethod(crv, segIdx, sav)
%% plotNormalizationMethod: show normalization method used for training
%
%
% Usage:
%   fig = plotNormalizationMethod(crv)
%
% Input:
%   crv: Curve object to show data
%   segIdx: index of segment to show
%
% Output:
%   fig: handle to figures
%
%

%%
%
figs = 1 : 3;
fnms = {sprintf('%s_SegmentOnImage_Segment%d',      tdate('s'), segIdx), ...
    sprintf('%s_RawSegmentTangentNormal_Segment%d', tdate('s'), segIdx), ...
    sprintf('%s_NormalSegment_Segment%d',           tdate('s'), segIdx)};
lnsz = 7;
dtsz = 25;

%
img = crv.Parent.getImage('gray');
trc = crv.Trace;
seg = crv.RawSegments(:,:,segIdx);
mid = crv.getMidPoint(segIdx);
tng = crv.Tangents(:,:,segIdx) + mid;
nml = crv.Normals(:,:,segIdx) + mid;
sgS = seg(1,:);
sgE = seg(end,:);
nrm = crv.NormalSegments(:,:,segIdx);
nmS = nrm(1,:);
nmE = nrm(end,:);

%%
fig(1) = figure(1);
cla;clf;
hold on;

imagesc(img);
plt(trc, 'g-', 4);
plt(seg, 'y-', lnsz);
plt(sgS, 'bo', dtsz);
plt(sgE, 'r*', dtsz);

colormap gray;
axis image;
axis ij;

%%
figs(2) = figure(2);
cla;clf;
hold on;

plt(seg, 'k-', lnsz);
plt(mid, 'ko', dtsz);
plt(mid, 'k.', dtsz);
plt(sgS, 'bo', dtsz);
plt(sgE, 'r*', dtsz);
plt([sgS ; sgE], 'k--', 2);
plt([mid ; tng], 'b-', 2);
plt([mid ; nml], 'r-', 2);

ylim([0 101]);
xlim([0 101]);
axis ij;

%%
figs(3) = figure(3);
cla;clf;
hold on;

plt(nrm, 'k-', lnsz);
plt(nmS, 'bo', dtsz);
plt(nmE, 'r*', dtsz);
xlim([-40 40]);
ylim([-10 10]);
plt([[-40 0] ; [40 0]], 'k-', 1);
plt([[0 -10] ; [0 10]], 'k-', 1);

%%
if sav
    for f = 1 : numel(figs)
        savefig(figs(f), fnms{f});
        saveas(figs(f), fnms{f}, 'tiffn');
    end
else
    pause(0.5);
end
end


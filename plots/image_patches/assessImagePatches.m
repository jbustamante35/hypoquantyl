function PATCHES = assessImagePatches(c, itr, scl, gaus, figs, fnms, sv)
%% assessImagePatches: run pipeline to generate and analyze image patches
% This function runs a neat little pipeline to generate an image patch of a 
% randomly chosen segment from a randomly chosen contour from the dataset in 
% section 1 of this file. The sv parameter will save figures in an individual 
% folder of the name of the contour and segment chosen.
%
% Use the following set of commands to run through this pipeline N times:
%    Ps = cell(1, N)';
%    for i = 1 : numel(Ps)
%        Ps{i} = assessImagePatches(itr, gaus, f, fn, 1);
%    end
%    pnm = sprintf('%s_ImagePatches_%d', datestr(now, 'yymmdd'), numel(Ps));
%    save(pnm, '-v7.3', 'Ps');
%
% Usage:
%   PATCHES = assessImagePatches(itr, gaus, figs, fnms, sv)
%
% Input:
%   c: CircuitJB object array of contours to extract image patches
%   itr: number of curves between main segment and inner/outer envelopes
%   scl: magnitude to scale maximum envelope distance
%   gaus: sigma value for gaussian filtering to smooth image patch
%   figs: array of figure indices [enter 0 to autogenerate figures]
%   fnms: cell string array of figure names [enter 0 to autogenerate names]
%   sv: boolean to save figure (1)
%
% Output:
%   PATCHES: image patch of a single curve's envelope structure
%
% Example:
%   PATCHES = assessImagePatches(cl, 50, 4, 4, 0, 0, 1)

%% Set-up Figures and random function handle
m  = @(x) randi([1 length(x)], 1);

if ~figs
    figs = 1:4;
    figs(1) = figure; % Trace decomposed curve
    figs(2) = figure; % Plot envelope onto hypocotyl image
    figs(3) = figure; % Plot pixel intensities of curves
    figs(4) = figure; % Plot segment and envelope around entire contour
    
    set(figs, 'Color', 'w');
else
    cla(figs);
    clf(figs);
end

if ~fnms
    fnms = cell(1,4);
    fnms{1} = sprintf('%s_TraceDecomposedCurve', tdate('s'));
    fnms{2} = sprintf('%s_DecomposedCurveOnImage', tdate('s'));
    fnms{3} = sprintf('%s_CurvePixelIntensities', tdate('s'));
    fnms{4} = sprintf('%s_CurveAndEnvelopeOnFullContour', tdate('s'));
end

%% Get random curve segment from random contour
% Take derivative of segment and get tangent line at each coordinate, then get 
% the unit vector distances for each segment
[ctrIdx, ctr, crv, numSegs, segIdx] = randomContourAndSegment(c, m);
segNrm                              = crv.NormalSegments(:, :, segIdx);

% Plot midpoint-normalized curve with left and right envelopes
nxt = 1;
set(0, 'CurrentFigure', figs(nxt));
nxt = nxt + 1;
cla;clf;

subplot(211);
hold on;
[envOut, envInn, dstOut, dstInn] = defineCurveEnvelope(segNrm, scl);
plt(segNrm, 'k.-', 1);
plt(envOut, 'r.-', 1);
plt(envInn, 'b.-', 1);

axis ij;
ttl = sprintf( ...
    'Midpoint-Normalized Curve with Out/Inn Envelope \n Contour %d | Segment %d', ...
    ctrIdx, segIdx);
title(ttl);

% Interpolate curve and envelope to generate all intermediate points
subplot(212);
hold on;
axis ij;

ptsOut = generateFullEnvelope(segNrm, dstOut, itr);
ptsInn = generateFullEnvelope(segNrm, dstInn, itr);

for d = 1 : itr
    plt(ptsOut{d}, 'r.-', 1);
    plt(ptsInn{d}, 'b.-', 1);
end

ttl = sprintf('Full Envelope Structure \n Contour %d | Segments %d', ...
    ctrIdx, numSegs);
title(ttl);

drawnow;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Convert to image axis coordinates
set(0, 'CurrentFigure', figs(nxt));
nxt = nxt + 1;
cla;clf;

% Convert and plot extremes onto original image
subplot(211);
hold on;

img                = ctr.getImage('gray');
Pm                 = crv.getParameter('Pmats', segIdx);
mid                = crv.getMidPoint(segIdx);
[segRawi, segRawm] = mapCurve2Image(segNrm, img, Pm, mid);
[envOuti, envOutm] = mapCurve2Image(envOut, img, Pm, mid);
[envInni, envInnm] = mapCurve2Image(envInn, img, Pm, mid);

imagesc(img);
plt(segRawm, 'ko-', 1);
plt(envOutm, 'ro-', 1);
plt(envInnm, 'bo-', 1);

colormap gray;
axis ij;
axis tight;
ttl = sprintf( ...
    'Original Reference Frame Coordinates \n Segment and Envelope only  \n Contour %d | Segment %d', ...
    ctrIdx, segIdx);
title(ttl);

% Convert and plot full envelope structure onto original image
subplot(212);
hold on;

[fullOuti, fullOutm] = ...
    cellfun(@(x) mapCurve2Image(x, img, Pm, mid), ptsOut, 'UniformOutput', 0);
[fullInni, fullInnm] = ...
    cellfun(@(x) mapCurve2Image(x, img, Pm, mid), ptsInn, 'UniformOutput', 0);

imagesc(img);
plt(segRawm, 'yo-', 1);
plt(envOutm, 'mo-', 1);
plt(envInnm, 'go-', 1);
cellfun(@(x) plt(x, 'r.-', 1), fullOutm, 'UniformOutput', 0);
cellfun(@(x) plt(x, 'b.-', 1), fullInnm, 'UniformOutput', 0);

colormap gray;
axis ij;
axis tight;
ttl = sprintf( ...
    'Original Reference Frame Coordinates \n Full envelope structure \n Contour %d | Segment %d', ...
    ctrIdx, segIdx);
title(ttl);

drawnow;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plot pixel intensities along curve and envelopes
set(0, 'CurrentFigure', figs(nxt));
nxt = nxt + 1;
cla;clf;

% Check segment with left and right envelopes only
subplot(211);
hold on;
px = [envInni segRawi envOuti];
imagesc(px);

colormap summer;
axis ij;
axis tight;
ttl = sprintf( ...
    'Pixel intensities (extremes) \n Contour %d | Segment %d \n Inner | Center | Outer', ...
    ctrIdx, segIdx);
title(ttl);

% Convert full envelope to image axis coordinates and chek pixel intensities
subplot(212);
allOut = cat(2,fullOuti{:});
allInn = fliplr(cat(2,fullInni{:})); % Flip inner envelope to align with others
fullpx = [allInn segRawi allOut];
imPtch = imgaussfilt(fullpx, gaus); % Apply gaussian smoothing
imagesc(imPtch);

colormap summer;
axis ij;
axis tight;
ttl = sprintf( ...
    'Pixel intensities (full envelope) \n Contour %d | Segment %d \n Inner | Center | Outer', ...
    ctrIdx, segIdx);
title(ttl);

drawnow;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Construct entire contour using this function
set(0, 'CurrentFigure', figs(nxt));
nxt = nxt + 1;
cla;clf;

imagesc(img);
hold on;

for s = 1 : numSegs
    currS                = crv.NormalSegments(:,:,s);
    [currL, currR, ~, ~] = defineCurveEnvelope(currS, scl);
    
    % Convert to image axis coordinates
    Pm          = crv.getParameter('Pmats', s);
    mid         = crv.getMidPoint(s);
    [~, currSm] = mapCurve2Image(currS, img, Pm, mid);
    [~, currLm] = mapCurve2Image(currL, img, Pm, mid);
    [~, currRm] = mapCurve2Image(currR, img, Pm, mid);
    
    % Plot segment and envelope on image
    plt(currSm, 'k--', 1);
    plt(currLm, 'r--', 1);
    plt(currRm, 'b--', 1);
end

colormap gray;
axis ij;
ttl = sprintf( ...
    'Converted Segment and Envelope on Full Contour \n Contour %d | Segment %d', ...
    ctrIdx, segIdx);
title(ttl);

drawnow;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Store data into Curve object
% TODO



%% Save CircuitJB data [when I save to objects]
% nm = sprintf('%s_randomCircuitsUpdate_%dcircuitsLR', datestr(now, 'yymmdd'), numel(cl));
% save(nm, '-v7.3', 'cl', 'cr');

%% Save Figures
if sv
    currDir = pwd;
    for g = 1 : numel(figs)
        dnm = sprintf('%s/Contour%d_Segment%d', currDir, ctrIdx, segIdx);
        
        if ~isdir(dnm)
            mkdir(dnm);
        end
        
        cd(dnm);
        savefig(figs(g), fnms{g});
        saveas(figs(g), fnms{g}, 'tiffn');
        
        cd(currDir);
        clf(figs(g));
    end
end

PATCHES = imPtch;

end

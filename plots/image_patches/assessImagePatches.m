function figs = assessImagePatches(crv, idx, figs, fnms, sv)
%% assessImagePatches: plot curve data and analyze image patches
% This function runs a neat little pipeline to take a randomly chosen Curve 
% segment from the inputted CircuitJB object and generate several plots to 
% visualize data on the curve segment, envelope structure, and image patch from
% that Curve object. 
%
% The sv parameter will save figures in an individual folder of the name of the 
% contour and segment chosen.
%
% Use the following set of commands to run through this pipeline N times:
%    Ps = cell(1, N)';
%    for i = 1 : numel(Ps)
%        Ps{i} = assessImagePatches(c, f, fn, 1);
%    end
%    pnm = sprintf('%s_ImagePatches_%d', datestr(now, 'yymmdd'), numel(Ps));
%    save(pnm, '-v7.3', 'Ps');
%
% Usage:
%   figs = assessImagePatches(c, figs, fnms, sv)
%
% Input:
%   crv: Curve object to extract image patches
%   idx: segment index to draw data from
%   figs: array of figure indices [enter 0 to autogenerate figures]
%   fnms: cell string array of figure names [enter 0 to autogenerate names]
%   sv: boolean to save figure (1)
%
% Output:
%   figs: figure handles to outputted figures
%

%% Set-up Figures and random function handle
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Get random curve segment from random contour
cName     = crv.Parent.Origin;
segParent = fixtitle(cName);
numSegs   = crv.NumberOfSegments;

% Misc data from CircuitJB object
img  = crv.Parent.getImage('gray');
crds = crv.CoordPatches{idx};
itr  = crv.getProperty('ENV_ITRS');
gaus = crv.getProperty('GAUSSSIGMA');

% Plot midpoint-normalized curve with left and right envelopes
nxt = 1;
set(0, 'CurrentFigure', figs(nxt));
nxt = nxt + 1;
cla;clf;

% Get envelope structure
subplot(211);
hold on;
segNrm = crv.NormalSegments(:, :, idx);
envOut = crv.getEnvelopeStruct('O');
envInn = crv.getEnvelopeStruct('I');

plt(segNrm, 'k.-', 1);
plt(envOut(idx).Max, 'r.-', 1);
plt(envInn(idx).Max, 'b.-', 1);

axis ij;
ttl = sprintf( ...
    'Midpoint-Normalized Curve and Envelope\nContour %s\nSegment %d', ...
    segParent, idx);
title(ttl);

% Plot all intermediate points
subplot(212);
hold on;
axis ij;

cellfun(@(x) plt(x, 'r.-', 1), envOut(idx).Full, 'UniformOutput', 0);
cellfun(@(x) plt(x, 'b.-', 1), envInn(idx).Full, 'UniformOutput', 0);

ttl = sprintf('Normalized Frame\nFull Envelope\nContour %s\nEnvelope Size %d', ...
    segParent, itr);
title(ttl);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Convert to image axis coordinates
set(0, 'CurrentFigure', figs(nxt));
nxt = nxt + 1;
cla;clf;

% Convert and plot extremes onto original image
subplot(211);
hold on;

segRawm = crds.mid;
envOutm = crds.out(:,:,itr);
envInnm = crds.inn(:,:,itr);

imagesc(img);
plt(segRawm, 'k.-', 3);
plt(envOutm, 'r.-', 3);
plt(envInnm, 'b.-', 3);

colormap bone;
axis ij;
axis tight;
ttl = sprintf( ...
    'Image Frame Coordinates\nSegment and Envelope\nContour %s\nSegment %d', ...
    segParent, idx);
title(ttl);

% Convert and plot full envelope structure onto original image
subplot(212);
hold on;

imagesc(img);
plt(segRawm, 'y.-', 2);
plt(envOutm, 'm.-', 2);
plt(envInnm, 'g.-', 2);
arrayfun(@(x) plt(crds.out(:,:,x), 'r.-', 1), ...
    1:size(crds.out,3), 'UniformOutput', 0);
arrayfun(@(x) plt(crds.inn(:,:,x), 'b.-', 1), ...
    1:size(crds.inn,3), 'UniformOutput', 0);

colormap bone;
axis ij;
axis tight;
ttl = sprintf( ...
    'Image Frame Coordinates\nFull envelope structure\nContour %s\nSegment %d', ...
    segParent, idx);
title(ttl);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Display pixel intensities along curve and envelope
set(0, 'CurrentFigure', figs(nxt));
nxt = nxt + 1;
cla;clf;

% Check left, center, and right envelopes
subplot(211);
hold on;

imgPatch = crv.ImagePatches{idx};
segRawi  = imgPatch(:, median(1:size(imgPatch,2)));
envOuti  = imgPatch(:,1);
envInni  = imgPatch(:,end);

px = [envOuti segRawi envInni];
imagesc(px);

colormap summer;
axis ij;
axis tight;
ttl = sprintf( ...
    'Pixel intensities\nContour %s\nSegment %d\nOuter | Center | Inner', ...
    segParent, idx);
title(ttl);

% Show full image patch 
subplot(212);
imagesc(imgPatch);

colormap bone;
axis ij;
axis tight;
ttl = sprintf( ...
    'Image Patch\nContour %s\nSegment %d | GausSigma %d\nOuter | Center | Inner', ...
    segParent, idx, gaus);
title(ttl);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Construct entire contour using this function
set(0, 'CurrentFigure', figs(nxt));
nxt = nxt + 1;
cla;clf;

imagesc(img);
hold on;

for s = 1 : numSegs
    % Get current segment
    currPatch = crv.CoordPatches{s};
    
    % Plot segment and envelope on image
    plt(currPatch.mid, 'k-', 1);
    plt(currPatch.out(:,:,itr), 'r-', 1);
    plt(currPatch.inn(:,:,itr), 'b-', 1);
end

colormap bone;
axis ij;
ttl = sprintf( ...
    'Converted Envelope on Contour \n Contour %s\nEnvelope Size %d', ...
    segParent, itr);
title(ttl);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save Figures
if sv
    currDir = pwd;
    for g = 1 : numel(figs)
        dnm = sprintf('%s/%s_Segment%d', currDir, cName, idx);
        
        if ~isfolder(dnm)
            mkdir(dnm);
        end
        
        cd(dnm);
        savefig(figs(g), fnms{g});
        saveas(figs(g), fnms{g}, 'tiffn');
        
        cd(currDir);
%         clf(figs(g));
    end
end

end

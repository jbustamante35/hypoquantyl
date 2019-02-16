function fig = showCurves(crv, idx, f, sv)
%% showCurves: display segment and envelope data
% This function creates a simple figure to display the image of the hypocotyl
% from the CircuitJB object, it's individual Curve objects, midpoints, and
% endpoints (top), and an individual Curve in normalized coordinates with it's
% enveloped spline with coordinates above and below the mean Curve.
%
% Usage:
%   fig = showCurves(c, numC, numE, dL, dR, f, sv)
%
% Input:
%   crv: Curve object
%   idx: segment index to display data
%   f: boolean to overwrite existing figure (0) or create new figure (1)
%   sv: boolean to save resulting figure as .fig and .tiff files
%
% Output:
%   fig: resulting figure handle
%

%% Create new figure or overwrite exsisting
if f
    fig = figure;
else
    cla;clf;
    fig = gcf;
end

set(gcf, 'Color', 'w');

%% Extract data from Curve
img     = crv.Parent.getImage('gray');
envSize = crv.getProperty('SEGMENTSTEPS');
envScl  = crv.getProperty('ENV_SCALE');
tSegs   = crv.NumberOfSegments;
segRaw  = crv.RawSegments(:,:,idx);
segNrm  = crv.NormalSegments(:,:,idx);
envOut  = crv.getEnvelopeStruct('O');
envInn  = crv.getEnvelopeStruct('I');
maxOut  = envOut(idx).Max;
maxInn  = envInn(idx).Max;
stp     = 30;

%% Subplot 1: contour with segments, midpoints, endpoints, and raw coordinates
subplot(211);
imshow(img, []);
hold on;

% Plot Curve's Segments, Midpoints, Endpoints
for seg = 1 : tSegs
    plt(crv.RawSegments(:,:,seg), '.', 3);
    plt(crv.getMidPoint(seg),     'x', 2);
    plt(crv.getEndPoint(seg, 1),  'o', 3);
    plt(crv.getEndPoint(seg, 2),  '+', 3);
end

plt(segRaw, 'y.', 5);

pName = fixtitle(crv.Parent.Origin);
ttl   = sprintf('%s\nSegments %d | Total Segments %d | StepSize %d', ...
    pName, idx, tSegs, envSize);
title(ttl);

%% Subplot 2: normalized curve, left and right envelopes, spline, and points
% Plot Normalized Segment
subplot(212);
hold on;
plt([0 0],  'rx', 4);
plt(segNrm, 'k.', 3);

% Plot Left and Right Envelopes
plt(maxOut, 'r.');
plt(maxInn, 'b.');

% Plot spline of envelope
lineInts(segNrm, maxOut, stp, 'm');
lineInts(segNrm, maxInn, stp, 'b');

ttl = sprintf( ...
    'Curve %d | SegmentLength %d \n EnvelopeWidth %d | SplineInterval %d', ...
    idx, size(envOut,1), envScl, stp);
title(ttl);

%% Save figure as .fig and .tiffn files
if sv
    nm = sprintf('%s_curveData_contour%d_curve%d', ...
        tdate('s'), idx, idx);
    savefig(fig, nm);
    saveas(fig, nm, 'tiffn');
end

end

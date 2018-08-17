function fig = showCurves(c, idx, numC, numE, dL, dR, f, sv)
%% showCurves: display segment and envelope data
% This function creates a simple figure to display the image of the hypocotyl from the CircuitJB
% object, it's individual Curve objects, midpoints, and endpoints (top), and an individual Curve in
% normalized coordinates with it's enveloped spline with coordinates above and below the mean Curve.
%
% Usage:
%   fig = showCurves(c, numC, numE, dL, dR, f, sv)
%
% Input:
%   c: CircuitJB object
%   idx: index of c in training data [to be removed later]
%   numC: index of Curve object in c to display data
%   numE: index along a Curve's normalized segment to plot a datapoint
%   dL: distance from Curve's segment within the left envelope section
%   dR: distance from Curve's segment within the right envelope section
%   f: boolean to overwrite existing figure (0) or create new figure (1)
%   sv: boolean to save resulting figure as .fig and .tiffn files
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

%% Subplot 1: contour with segments, midpoints, endpoints, and Curve's raw coordinates
subplot(211);
imagesc(c.getImage(1, 'gray'));
colormap gray;
axis image;
hold on;

% Plot Curve's Segments, Midpoints, Endpoints at once
crv = c.getCurve(numC);
seg = crv.NumberOfSegments;
arrayfun(@(x) plt(crv.RawSegments(:,:,x), '.', 3), 1 : seg, 'UniformOutput', 0);
arrayfun(@(x) plt(crv.getMidPoint(x), 'x', 2), 1 : seg, 'UniformOutput', 0);
arrayfun(@(x) plt(crv.getEndPoint(x, 1), 'o', 3), 1 : seg, 'UniformOutput', 0);
arrayfun(@(x) plt(crv.getEndPoint(x, 2), '+', 3), 1 : seg, 'UniformOutput', 0);

env = 20;
plc = '[PlaceHolder Contour Name]';
ttl = sprintf('%s(%d) \n Segments %d | StepSize %d', plc, idx, seg, env);
title(ttl);

%% Subplot 2: normalized curve, left and right envelopes, spline, and points above and below curve
subplot(211);
raw = crv.RawSegments(:,:,numC);
nrm = crv.NormalSegments(:,:,numC);
plt(raw, 'y.', 5);

% Plot Normalized Segment
subplot(212);
hold on;
plt([0 0], 'rx', 4);
plt(nrm, 'k.', 3);

% Plot Left and Right Envelopes
L = crv.getEnvelopeSide('L');
R = crv.getEnvelopeSide('R');
plt(L(:,:,numC), 'r.');
plt(R(:,:,numC), 'g.');

% Plot spline of envelope
stp = 30;
for k = round(1 : (length(L) - 1) / stp : length(L))
    lnL = [crv.NormalSegments(k,:,numC) ; L(k,:,numC)];
    lnR = [crv.NormalSegments(k,:,numC) ; R(k,:,numC)];
    line(lnL(:,1), lnL(:,2), 'Color', 'm');
    line(lnR(:,1), lnR(:,2), 'Color', 'b');
end

% Pick locations above and below Segment
ptL = [nrm(numE,1), (nrm(numE,2) + dL)];
ptR = [nrm(numE,1), (nrm(numE,2) - dR)];
plt(nrm(numE,:), 'go', 10);
plt(ptL, 'ro', 10);
plt(ptR, 'bo', 10);

% Put point distances on plot
text(ptL(1)-0.5, ptL(2), num2str(-dL), 'Color', 'k', 'FontSize', 7, 'FontWeight', 'b');
text(ptR(1)-0.5, ptR(2), num2str(dR), 'Color', 'k', 'FontSize', 7, 'FontWeight', 'b');

ttl = sprintf('Curve %d | SegmentLength %d \n EnvelopeWidth %d | SplineInterval %d', ...
    numC, size(L,1), 20, stp);
title(ttl);

%% Save figure as .fig and .tiffn files
if sv
    nm = sprintf('%s_curveData_contour%d_curve%d_envelope%d', ...
        datestr(now, 'yymmdd'), idx, numC, numE);
    savefig(fig, nm);
    saveas(fig, nm, 'tiffn');
end

end

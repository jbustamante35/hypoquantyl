function plotPCAcircuits(X, Y, c, n, f)
%% plotPCAcircuits: plot for checking PCA results of fully normalized manual contours
%
%
% Usage:
%   plotPCAcircuits(X, Y, c, n, f)
%
% Input:
%   X: output from my custom pca analysis for x-coordinates
%   Y: output from my custom pca analysis for y-coordinates
%   c: array of CircuitJB objects used for pca analysis
%   n: index of CircuitJB in c to plot data
%   f: 0 to overlay plot on current figure, 1 to create new figure
%
% Output:
%
%

%% Set-up new figure or replace figure, and set-up function handle for contour conversion
if f
    figure;
else
    cla;
    clf;
end

set(gcf, 'Color', 'w');
n2i = @(x,y) norm2interp(y, x.getMean, x.getAnchors(1, 'b2'), x.getAnchors(1, 'd2'));

%% Extract data from index defined in n
raw = [X.InputData(n,:) ; Y.InputData(n,:)]';
trc = [X.SimData(n,:) ; Y.SimData(n,:)]';
rts = c(n).getRoute;

subplot(221);
hold on;
plot(raw(:,1), 'k--');
plot(trc(:,1), 'm');
ttl = sprintf('x-coordinate overlay %d \n %d PCs', n, size(X.EigValues,1));
title(ttl);
hold off;

subplot(222);
hold on;
plot(raw(:,2), 'k--');
plot(trc(:,2), 'm');
ttl = sprintf('y-coordinate overlay %d \n %d PCs', n, size(Y.EigValues,1));
title(ttl);
hold off;

subplot(223);
hold on;

subplot(224);
imagesc(c(n).getImage(1, 'gray'));
colormap gray, axis image;
hold on;

%% Plot input data vs synthetic data
j   = 1;
szA = size(rts,2);
szB = size(trc,1);
szC = szB / szA;

% Increment by size of each individual Route
for k = szC : szC : szB
    C = rand(1,3);
    
    % Raw normalized data
    subplot(223);
    plot(X.InputData(n, (k - (szC-1) : k)), Y.InputData(n, (k - (szC - 1) : k)), '--', 'Color', C);
    plot(X.SimData(n, (k - (szC-1) : k)), Y.SimData(n, (k - (szC - 1) : k)), '.', 'Color', C);
    ttl = sprintf('Input vs Synthetic:\nNormalized Contours %d', n);
    title(ttl);
    
    % Raw converted to interpolated coordinates overlaied on grayscale image
    subplot(224);
    R = n2i(rts(j), raw((k - (szC - 1)) : k, :));
    I = n2i(rts(j), trc((k - (szC - 1)) : k, :));
    plot(R(:,1), R(:,2), '--', 'MarkerSize', 5, 'Color', C);
    plot(I(:,1), I(:,2), '.', 'MarkerSize', 5, 'Color', C);
    ttl = sprintf('Input vs Synthetic:\nOverlay on Image %d', n);
    title(ttl);
    
    j = j + 1;
end

end
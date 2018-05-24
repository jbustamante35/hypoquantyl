function fig = multiPCAplot(pcaX, pcaY, C, n, f)
%% multiPCAplot: reconstruct multiPCA data to check results of fully normalized contours
%
%
% Usage:
%   fig = multiPCAplot(X, Y, c, n, f)
%
% Input:
%   X: output from my custom pca analysis for x-coordinates
%   Y: output from my custom pca analysis for y-coordinates
%   C: array of CircuitJB objects used for pca analysis
%   n: index of CircuitJB in c to plot data
%   f: 0 to overlay plot on current figure, 1 to create new figure
%
% Output:
%   fig: figure outputted by this function
%

%% Set-up new figure or replace figure, and set-up function handle for contour conversion
if f
    fig = figure;
else
    cla;
    clf;
    fig = gcf;
end

set(gcf, 'Color', 'w');

%% Combine PCA output for both x-/y-coordinates
pX = horzcat(pcaX.customPCA);
pY = horzcat(pcaY.customPCA);
r  = arrayfun(@(x) x.getRoute, C, 'UniformOutput', 0);
r  = r';

%% Collect all conversion matrices from each Route
Pmats = cellfun(@(x) arrayfun(@(x) x.getPmat, x, 'UniformOutput', 0), r, 'UniformOutput', 0);
Pmats = cellfun(@(x) cat(3, x{:}), Pmats, 'UniformOutput', 0);
Pmats = cat(4, Pmats{:});
Pmats = permute(Pmats, [1 2 4 3]);

%% Prep variables for storing interpolated segments
szA = size(pX(1).InputData, 1);
szB = size(pX(1).InputData, 2);
szC = numel(pX);
[rX, rY, sX, sY] = deal(zeros(szA, szB, szC));

%% Convert and combine midpoint-normalized segments to interpolated segments
Z = ones(1, szB);
for i = 1 : szA
    for ii = 1 : szC
        Pmat = Pmats(:,:,i,ii);
        
        rawX = pX(ii).InputData;
        rawY = pY(ii).InputData;
        
        simX = pX(ii).SimData;
        simY = pY(ii).SimData;
        
        rP = [rawX(i,:) ; rawY(i,:) ; Z];
        sP = [simX(i,:) ; simY(i,:) ; Z];
        
        rP = reverseMidpointNorm(rP, Pmat);
        sP = reverseMidpointNorm(sP, Pmat);
        
        rX(i,:,ii) = rP(1,:)';
        rY(i,:,ii) = rP(2,:)';
        sX(i,:,ii) = sP(1,:)';
        sY(i,:,ii) = sP(2,:)';
    end
end

%% Extract data from index defined in n
raw = [rX(n,:) ; rY(n,:)]';
trc = [sX(n,:) ; sY(n,:)]';
rts = C(n).getRoute;

subplot(221);
hold on;
plot(raw(:,1), 'k--');
plot(trc(:,1), 'm');
ttl = sprintf('x-coordinate overlay %d \n %d PCs', n, size(pX(1).EigValues,1));
title(ttl);
hold off;

subplot(222);
hold on;
plot(raw(:,2), 'k--');
plot(trc(:,2), 'm');
ttl = sprintf('y-coordinate overlay %d \n %d PCs', n, size(pY(1).EigValues,1));
title(ttl);
hold off;

subplot(223);
axis ij;
hold on;

subplot(224);
imagesc(C(n).getImage(1, 'gray'));
colormap gray, axis image;
hold on;

%% Plot input data vs synthetic data
szX = size(rts,2);
szY = size(trc,1);
szZ = szY / szX;

% Increment by size of each individual Route
for k = szZ : szZ : szY
    colr = rand(1,3);
    incr = (k - (szZ - 1)) : k;
    
    % Raw normalized data
    subplot(223);
    plot(rX(n, incr), rY(n, incr), '--', 'Color', colr);
    plot(sX(n, incr), sY(n, incr), '.', 'Color', colr);
    ttl = sprintf('Input vs Synthetic:\nNormalized Contours %d', n);
    title(ttl);
    
    % Raw converted to interpolated coordinates overlaid on grayscale image
    subplot(224);
    plot(rX(n, incr), rY(n, incr), '--', 'Color', colr);
    plot(sX(n, incr), sY(n, incr), '.', 'Color', colr);
    ttl = sprintf('Input vs Synthetic:\nOverlay on Image %d', n);
    title(ttl);
end

end
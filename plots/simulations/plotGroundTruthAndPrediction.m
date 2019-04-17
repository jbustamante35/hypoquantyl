function fig = plotGroundTruthAndPrediction(idx, img, trnIdx, Zin, Zout, sav, f)
%% plotGroundTruthAndPrediction: overlay ground truth contour on predicted
%
%
% Usage:
%   fig = plotGroundTruthAndPrediction(truX, preY, img, idx, numComponents, f)
%
% Input:
%   X: ground truth contour coordinates
%   Y: predicted contour coordinates
%   I: grayscale image associated with contour
%   idx: index in Curve object array for naming figure
%   numPCs: [3 x 1] array of principal component values used for prediction
%   sav: boolean to save figure as .fig and .tiff image
%   f: index of figure handle to plot data onto
%
% Output:
%   fig: handle to outputted figure
%

%% Plot input vs converted outputs [single, plot only]
fig = figure(f);
% set(0, 'CurrentFigure', fig);
cla;clf;

% Figure data
row   = 2;
col   = 4;
pIdx  = 1;

%% Check if data to plot is in training or testing set
chk = ismember(idx, trnIdx);
if chk
    tSet = 'in training set';
    fSet = 'training';
else
    tSet = 'in testing set';
    fSet = 'testing';
end

%% Extract set-up data
ttlSegs    = size(Zin.FullData, 2) / 6;
numCrvs    = size(Zin.FullData, 1);
[~, sIdxs] = extractIndices(idx, ttlSegs, Zin.RevertData);

%% Store input and predicted data
Xin      = Zin.FullData;
Xin_rev  = Zin.RevertData;
Xin_n    = Zin.RevertData(sIdxs,:);
Xout     = Zout.FullData;
Xout_rev = Zout.RevertData;
Xout_n   = Zout.RevertData(sIdxs,:);

%% Store input and predicted data
Min  = Zin.RevertData(sIdxs,1:2);
Tin  = Zin.RevertData(sIdxs,3:4);
Nin  = Zin.RevertData(sIdxs,5:6);
Hin  = Zin.HalfData(:,:,idx)';
Mout = Zout.RevertData(sIdxs,1:2);
Tout = Zout.RevertData(sIdxs,3:4);
Nout = Zout.RevertData(sIdxs,5:6);
Hout = Zout.HalfData(:,:,idx)';

%% Show CNN Input
subplot(row , col , pIdx); pIdx = pIdx + 1;
imagesc(Xin);
colormap gray;
ttl = sprintf('Full Input');
title(ttl);

%% Show reverted inputed rasterized
subplot(row , col , pIdx); pIdx = pIdx + 1;
imagesc(Xin_rev);
colormap gray;
ttl = sprintf('Full Input Reversion');
title(ttl);

%% Show reverted input for single hypocotyl
subplot(row , col , pIdx); pIdx = pIdx + 1;
imagesc(Xin_n);
colormap gray;
ttl = sprintf('Input Reversion\nContour %d [%s]', idx, tSet);
title(ttl);

%% Overlay Z-Vector on hypocotyl image
subplot(row , col , pIdx); pIdx = pIdx + 1;
imagesc(img);
colormap gray;
axis image;
axis ij;
hold on;

plt(Min, 'g.', 3);
plt([Min ; Tin], 'b-', 1);
plt([Min ; Nin], 'r-', 1);
ttl = sprintf('Midpoint-Tangent-Normal\nGround Truth\nContour %d [%s]', ...
    idx, tSet);
title(ttl);

%% Show CNN Predictions
subplot(row , col , pIdx); pIdx = pIdx + 1;
imagesc(Xout);
colormap gray;
ttl = sprintf('Full Predictions');
title(ttl);

%% Show reverted predictions rasterized
subplot(row , col , pIdx); pIdx = pIdx + 1;
imagesc(Xout_rev);
colormap gray;
ttl = sprintf('Full Predictions Reversion');
title(ttl);

%% Show reverted predictions for single hypocotyl
subplot(row , col , pIdx); pIdx = pIdx + 1;
imagesc(Xout_n);
colormap gray;
ttl = sprintf('Predicted Reversion\nContour %d [%s]', idx, tSet);
title(ttl);

%% Overlay predicted Z-Vector on hypocotyl image
subplot(row , col , pIdx); pIdx = pIdx + 1;
imagesc(img);
colormap gray;
axis image;
axis ij;
hold on;

plt(Mout, 'g.', 3);
plt([Mout ; Tin], 'b-', 1);
plt([Mout ; Nin], 'r-', 1);
hold off;
ttl = sprintf('Midpoint-Tangent-Normal\nPredicted\nContour %d [%s]', ...
    idx, tSet);
title(ttl);

%% Save figure as .fig and .tif
if sav
    fnm = sprintf('%s_ReversionPipeline_%dCurves_%dSegments_Contour%d_%s', ...
        tdate('s'), numCrvs, ttlSegs, idx, fSet);
    savefig(fig, fnm);
    saveas(fig, fnm, 'tiffn');
else
    pause(1);
end

end
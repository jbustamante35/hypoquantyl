function fig = plotPredictions(idx, img, trnIdx, Zin, Zout, sav, f)
%% plotPredictions: Plot predictions from CNN or PLSR
%
%
% Usage:
%   fig = plotPredictions(idx, img, trnIdx, Zin, Zout, sav, f)
%
% Input:
%   idx: index in crvs of hypocotyl to show prediction
%   img: grayscale image corresponding to index in training set
%   px: PCA data of x-coordinates
%   py: PCA data of y-coordinates
%   pz: PCA data of midpoints
%   req: set to 'truth', 'sim', or 'predicted' midpoint values
%   sav: boolean to save figure as .fig and .tiff files
%   f: select index of figure handle
%
% Output:
%   fig: figure handle to generated data
%

%% Plot Contours to Compare Ground Truth vs Predicted
fig = figure(f);
% set(0, 'CurrentFigure', fig);
cla;clf;

% Figure data
row  = 2;
col  = 2;
pIdx = 1;

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
ttlSegs = size(Zin.FullData, 2) / 6;
numCrvs = size(Zin.FullData, 1);
[~, sIdxs] = extractIndices(idx, ttlSegs, Zin.RevertData);

%% Store input and predicted data
Min  = Zin.RevertData(sIdxs,1:2);
Tin  = Zin.RevertData(sIdxs,3:4);
Nin  = Zin.RevertData(sIdxs,5:6);
Hin  = Zin.HalfData(:,:,idx)';
Mout = Zout.RevertData(sIdxs,1:2);
Tout = Zout.RevertData(sIdxs,3:4);
Nout = Zout.RevertData(sIdxs,5:6);
Hout = Zout.HalfData(:,:,idx)';

%% Show ground truth Z-Vectors and Contours
subplot(row , col , pIdx); pIdx = pIdx + 1;
imagesc(img);
colormap gray;
axis image;
hold on;

plt(Min, 'g.', 3);
plt([Min ; Tin], 'b-', 1);
plt([Min ; Nin], 'r-', 1);
plt(Hin, 'g--', 1);
ttl = sprintf('Contour from Z-Vectors\nTruth\nContour %d [%s]', ...
    idx, tSet);
title(ttl);

%% Show predicted Z-Vectors and Contours
subplot(row , col , pIdx); pIdx = pIdx + 1;
imagesc(img);
colormap gray;
axis image;
hold on;

plt(Mout, 'g.', 3);
plt([Mout ; Tin], 'b-', 1);
plt([Mout ; Nin], 'r-', 1);
plt(Hout, 'g--', 1);
ttl = sprintf('Contour from Z-Vectors\nPredicted\nContour %d [%s]', ...
    idx, tSet);
title(ttl);

%% Overlay Ground Truth Vs Predicted Z-Vector
subplot(row , col , pIdx); pIdx = pIdx + 1;
imagesc(img);
colormap gray;
axis image;
hold on;

plt(Min, 'g.', 3);
plt([Min ; Tin], 'b-', 1);
plt([Min ; Nin], 'r-', 1);

plt(Mout, 'g.', 3);
plt([Mout ; Tin], 'b-', 1);
plt([Mout ; Nin], 'r-', 1);
ttl = sprintf('Z-Vectors only\nTruth Vs. Predicted\nContour %d [%s]', ...
    idx, tSet);
title(ttl);

%% Overlay Ground Truth Vs Predicted Contour
subplot(row , col , pIdx); pIdx = pIdx + 1;
imagesc(img);
colormap gray;
axis image;
hold on;

plt(Hin, 'g--', 1);
plt(Hout, 'y-', 1);
ttl = sprintf('Contour only\nTruth Vs. Predicted\nContour %d [%s]', ...
    idx, tSet);
title(ttl);

%% Save figure as .fig and .tif
if sav
    fnm = ...
        sprintf('%s_TruthVsPredicted_%dCurves_%dSegments_Contour%d_%s', ...
        tdate('s'), numCrvs, ttlSegs, idx, fSet);
    savefig(fig, fnm);
    saveas(fig, fnm, 'tiffn');
else
    pause(1);
end

end


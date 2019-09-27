function fig = plotZPredictions(idx, img, trnIdx, Zin, Zout, req, sav, f)
%% plotZPredictions: Plot predictions from CNN or PLSR for Z-Vectors
%
%
% Usage:
%   fig = plotZPredictions(idx, img, trnIdx, Zin, Zout, req, sav, f)
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
tAll = tic;
str  = sprintf('\n%s\n', repmat('-', 1, 80));
fprintf('%sPlotting predictions for %s data\n', str, req);

% Prep and clear figure
fig = figure(f);
cla;clf;

% Figure data
row  = 2;
col  = 2;
pIdx = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Check if data to plot is in training or testing set
t = tic;

chk = ismember(idx, trnIdx);
if chk
    tSet = 'in training set';
    fSet = 'training';
else
    tSet = 'in validation set';
    fSet = 'validation';
end

% Extract set-up data
ttlSegs  = size(Zin.FullData, 2) / 6;
numCrvs  = size(Zin.FullData, 1);
allSegs  = 1 : ttlSegs;
sIdxs    = extractIndices(idx, ttlSegs, Zin.RevertData);

msg = sprintf('Extracted information: Contour %d of %d [%s] [%d segments]', ...
    idx, numCrvs, tSet, ttlSegs);
fprintf('%s...[%.02f sec]\n', msg, toc(t));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Store input and predicted data
t = tic;

% Indices for Midpoint-Tangent-Normal
mid = 1:2;
tng = 3:4;
nrm = 5:6;

% Store M-T-N in separate arrays
revI = Zin.RevertData(sIdxs, :);
Min  = revI(:, mid);
Tin  = arrayfun(@(x) [revI(x,mid) ; revI(x,tng)], allSegs, 'UniformOutput', 0);
Nin  = arrayfun(@(x) [revI(x,mid) ; revI(x,nrm)], allSegs, 'UniformOutput', 0);
Hin  = Zin.HalfData(:,:,idx)';

%
revO = Zout.RevertData(sIdxs, :);
Mout = revO(:, mid);
Tout = arrayfun(@(x) [revO(x,mid) ; revO(x,tng)], allSegs, 'UniformOutput', 0);
Nout = arrayfun(@(x) [revO(x,mid) ; revO(x,nrm)], allSegs, 'UniformOutput', 0);
Hout = Zout.HalfData(:,:,idx)';

msg = sprintf('Extracted information: Contour %d of %d [%s] [%d segments]', ...
    idx, numCrvs, tSet, ttlSegs);
fprintf('%s...[%.02f sec]\n', msg, toc(t));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Show ground truth Z-Vectors and Contours
t = tic;

subplot(row , col , pIdx); pIdx = pIdx + 1;
imagesc(img);
colormap gray;
axis image;
hold on;

plt(Min, 'g.', 3);
cellfun(@(x) plt(x, 'r-', 1), Tin, 'UniformOutput', 0);
cellfun(@(x) plt(x, 'b-', 1), Nin, 'UniformOutput', 0);
plt(Hin, 'g--', 1);
ttl = sprintf('Contour from Z-Vectors\nTruth\nContour %d [%s]', ...
    idx, tSet);
title(ttl);

msg = sprintf('Plotting Ground Truth skeleton and contour');
fprintf('%s...[%.02f sec]\n', msg, toc(t));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Show predicted Z-Vectors and Contours
t = tic;
subplot(row , col , pIdx); pIdx = pIdx + 1;
imagesc(img);
colormap gray;
axis image;
hold on;

plt(Mout, 'g.', 3);
cellfun(@(x) plt(x, 'r-', 1), Tout, 'UniformOutput', 0);
cellfun(@(x) plt(x, 'b-', 1), Nout, 'UniformOutput', 0);
plt(Hout, 'g--', 1);
ttl = sprintf('Contour from Z-Vectors\nPredicted\nContour %d [%s]', ...
    idx, tSet);
title(ttl);

msg = sprintf('Plotting predicted skeleton and contour');
fprintf('%s...[%.02f sec]\n', msg, toc(t));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Overlay Ground Truth Vs Predicted Z-Vector
t = tic;

subplot(row , col , pIdx); pIdx = pIdx + 1;
imagesc(img);
colormap gray;
axis image;
hold on;

plt(Min, 'go', 2);
cellfun(@(x) plt(x, 'g--', 1), Tin, 'UniformOutput', 0);
cellfun(@(x) plt(x, 'g--', 1), Nin, 'UniformOutput', 0);

plt(Mout, 'y.', 3);
cellfun(@(x) plt(x, 'y-', 1), Tout, 'UniformOutput', 0);
cellfun(@(x) plt(x, 'y-', 1), Nout, 'UniformOutput', 0);
ttl = sprintf('Z-Vectors only\nTruth Vs. Predicted\nContour %d [%s]', ...
    idx, tSet);
title(ttl);

msg = sprintf('Plotting ground truth vs predicted overlay [skeletons]');
fprintf('%s...[%.02f sec]\n', msg, toc(t));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Overlay Ground Truth Vs Predicted Contour
t = tic;

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

msg = sprintf('Plotting ground truth vs predicted overlay [contour]');
fprintf('%s...[%.02f sec]\n', msg, toc(t));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save figure as .fig and .tif
msg = sprintf('Finished plotting [Save = %d]', sav);
fprintf('%s...', msg);

if sav
    fnm = ...
        sprintf('%s_TruthVsPredicted_%dCurves_%dSegments_Contour%d_%s_%s', ...
        tdate('s'), numCrvs, ttlSegs, idx, fSet, req);
    savefig(fig, fnm);
    fprintf('...');
    saveas(fig, fnm, 'tiffn');
end

fprintf('Done!...[%.02f sec]%s', toc(tAll), str);

end


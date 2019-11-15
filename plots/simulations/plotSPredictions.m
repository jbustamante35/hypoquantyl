function fig = plotSPredictions(idx, img, trnIdx, Sin, Sout, ttlSegs, numCrvs, req, sav, f)
%% plotSPredictions: Plot predictions from NN for S-Vectors
%
%
% Usage:
%   fig = plotSPredictions( ...
%       idx, img, trnIdx, Sin, Sout, ttlSegs, numCrvs, req, sav, f)
%
% Input:
%   idx: index in crvs of hypocotyl to show prediction
%   img: grayscale image corresponding to index in training set
%   Sin:
%   Sout:
%   ttlSegs:
%   numCrvs:
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
row  = 1;
col  = 2;
pIdx = 1;
scl  = 3;

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
allSegs  = 1 : ttlSegs;
sIdxs    = extractIndices(idx, ttlSegs);

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
zI   = Sin.ZVectors(sIdxs,:);
Min  = zI(:,mid);
tngs = scaleVector(zI(:,tng), Min, scl);
nrms = scaleVector(zI(:,nrm), Min, scl);

Tin = arrayfun(@(x) [Min(x,:) ; tngs(x,:)], allSegs, 'UniformOutput', 0);
Nin = arrayfun(@(x) [Min(x,:) ; nrms(x,:)], allSegs, 'UniformOutput', 0);
Hin = Sin.RawContour(sIdxs,:);

%
zO   = Sout.ZVectors(sIdxs,:);
Mout = zO(:,mid);
tngs = scaleVector(zO(:,tng), Mout, scl);
nrms = scaleVector(zO(:,nrm), Mout, scl);

Tout = arrayfun(@(x) [Mout(x,:) ; tngs(x,:)], allSegs, 'UniformOutput', 0);
Nout = arrayfun(@(x) [Mout(x,:) ; nrms(x,:)], allSegs, 'UniformOutput', 0);
Hout = Sout.Contour(sIdxs,:);

msg = sprintf('Extracted information: Contour %d of %d [%s] [%d segments]', ...
    idx, numCrvs, tSet, ttlSegs);
fprintf('%s...[%.02f sec]\n', msg, toc(t));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Overlay Ground Truth Vs Predicted Z-Vector
t = tic;

subplot(row , col , pIdx); pIdx = pIdx + 1;
myimagesc(img);
hold on;

plt(Min, 'g.', 3);
cellfun(@(x) plt(x, 'g-', 2), Tin, 'UniformOutput', 0);
cellfun(@(x) plt(x, 'g-', 2), Nin, 'UniformOutput', 0);

plt(Mout, 'y.', 2);
cellfun(@(x) plt(x, 'y-', 1), Tout, 'UniformOutput', 0);
cellfun(@(x) plt(x, 'y-', 1), Nout, 'UniformOutput', 0);
ttl = sprintf('Z-Vectors only\nTruth Vs. Predicted\nContour %d [%s]', ...
    idx, tSet);
title(ttl, 'FontSize', 8);

msg = sprintf('Plotting ground truth vs predicted overlay [skeletons]');
fprintf('%s...[%.02f sec]\n', msg, toc(t));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Overlay Ground Truth Vs Predicted Contour
t = tic;

subplot(row , col , pIdx);
myimagesc(img);
hold on;

plt(Hin, 'g--', 2);
plt(Hout, 'y-', 2);
ttl = sprintf('Contour only\nTruth Vs. Predicted\nContour %d [%s]', ...
    idx, tSet);
title(ttl, 'FontSize', 8);

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

function vout = scaleVector(vin, mid, scl)
%% scaleVector: zero-center, scale, and add back vector
% Method to scale tangent and normal vectors that are in the midpoint-frame

vout = (scl * (vin - mid)) + mid;

end



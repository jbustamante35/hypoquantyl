function fig = plotGroundTruthAndPrediction(idx, img, Zin, Zout, sav, f)
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
fIdx = f;
set(0, 'CurrentFigure', figs(fIdx));
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

%% Store input and predicted data
Xin      = Zin.FullData;
Xin_rev  = Zin.RevertData;
Xin_n    = extractIndices(idx, ttlSegs, Xin_rev)';
Xout     = Zout.FullData;
Xout_rev = Zout.RevertData;
Xout_n   = extractIndices(idx, ttlSegs, Xout_rev)';

%% Store input and predicted data
% Xin      = pz.InputData;
% Xin_rev  = zVectorConversion(Xin, ttlSegs, numCrvs, 'rev');
% Xin_n    = extractIndices(idx, ttlSegs, Xin_rev)';
% Xout     = predZ_cnn;
% Xout_rev = zVectorConversion(Xout, ttlSegs, numCrvs, 'rev');
% Xout_n   = extractIndices(idx, ttlSegs, Xout_rev)';

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
ttl = sprintf('Input Reversion\nContour %d [%s]', cIdx, tSet);
title(ttl);

%% Overlay Z-Vector on hypocotyl image
subplot(row , col , pIdx); pIdx = pIdx + 1;
imagesc(img);
colormap gray;
axis image;
axis ij;
hold on;

arrayfun(@(x) plt(Zin.M(x,:), 'g.', 3), sIdxs, 'UniformOutput', 0);
arrayfun(@(x) plt([Zin.M(x,:) ; Zin.T(x,:)], 'b-', 1), ...
    sIdxs, 'UniformOutput', 0);
arrayfun(@(x) plt([Zin.M(x,:) ; Zin.N(x,:)], 'r-', 1), ...
    sIdxs, 'UniformOutput', 0);
ttl = sprintf('Midpoint-Tangent-Normal\nGround Truth\nContour %d [%s]', ...
    cIdx, tSet);
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
ttl = sprintf('Predicted Reversion\nContour %d [%s]', cIdx, tSet);
title(ttl);

%% Overlay predicted Z-Vector on hypocotyl image
subplot(row , col , pIdx); pIdx = pIdx + 1;
imagesc(img);
colormap gray;
axis image;
axis ij;
hold on;

arrayfun(@(x) plt(Zout.M(x,:), 'g.', 3), sIdxs, 'UniformOutput', 0);
arrayfun(@(x) plt([Zout.M(x,:) ; Zout.T(x,:)], 'b-', 1), ...
    sIdxs, 'UniformOutput', 0);
arrayfun(@(x) plt([Zout.M(x,:) ; Zout.N(x,:)], 'r-', 1), ...
    sIdxs, 'UniformOutput', 0);
hold off;
ttl = sprintf('Midpoint-Tangent-Normal\nPredicted\nContour %d [%s]', ...
    cIdx, tSet);
title(ttl);

%% Save figure as .fig and .tif
if sav
    fnms{fIdx} = sprintf('%s_ReversionPipeline_Contour%d_%s', ...
        tdate('s'), cIdx, fSet);
    savefig(figs(fIdx), fnms{fIdx});
    saveas(figs(fIdx), fnms{fIdx}, 'tiffn');
else
    pause(1);
end

end
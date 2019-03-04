function fig = plotGroundTruthAndPrediction(X, Y, I, idx, numPCs, sav, f)
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
%   numPCs: [4 x 1] array of principal component values used for prediction
%   sav: boolean to save figure as .fig and .tiff image
%   f: index of figure handle to plot data onto
%
% Output:
%   fig: handle to outputted figure
%

% Plot predictions and truths
fig = figure(f);
cla;clf;

% Show image with ground truth and simulated prediction
imshow(I, []);
imagesc(I);
colormap gray;
axis image;
axis off;
hold on;
plt(X, 'g--' , 7);
plt(Y, 'y-'  , 7);
ttl = ...
    sprintf('Contour Prediction\nTruth (green) | Predicted (yellow)\nContour %d', ...
    idx);
title(ttl);

% Save figure
if sav
    
    fnm = sprintf('%s_ContourPrediction_p%dPCs_m%dPCs_x%dPCs_y%dPCs_Contour%d', ...
        tdate('s'), numPCs(1), numPCs(2), numPCs(3), numPCs(4), idx);
    savefig(fig, fnm);
    saveas(fig, fnm, 'tiffn');
else
    pause(0.5);
end

end
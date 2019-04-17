function [syntHalf_inp, syntHalf_sim, fig] = plotPredictions(idx, px, py, pz, pMids, crvs, req, sav, f)
%% plotPredictions: Plot predictions from CNN or PLSR
%
%
% Usage:
%   [syntHalf_inp, syntHalf_sim, fig] = plotPredictions(idx, px, py, pz, pMids, crvs, req, sav, f)
%
% Input:
%   idx: index in crvs of hypocotyl to show prediction
%   px: PCA data of x-coordinates
%   py: PCA data of y-coordinates
%   pz: PCA data of midpoints
%   crvs: object array of Curves to provide image and raw midpoint data
%   req: set to 'truth' or 'predicted' midpoint values
%   sav: boolean to save figure as .fig and .tiff files
%   f: select index of figure
%
% Output:
%   syntHalf_inp: converted halfway coordinate segments from inputted PCA data
%   syntHalf_sim: converted halfway coordinate segments from simulated PCA data
%   fig: figure handle to generated data
%

%% Plot Contours to Compare Ground Truth vs Predicted
fIdx = f;
set(0, 'CurrentFigure', figs(fIdx));
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

%% Show ground truth Z-Vectors and Contours
subplot(row , col , pIdx); pIdx = pIdx + 1;
imagesc(img);
colormap gray;
axis image;
hold on;

arrayfun(@(x) plt(Zin.M(x,:), 'g.', 3), sIdxs, 'UniformOutput', 0);
arrayfun(@(x) plt([Zin.M(x,:) ; Zin.T(x,:)], 'b-', 1), ...
    sIdxs, 'UniformOutput', 0);
arrayfun(@(x) plt([Zin.M(x,:) ; Zin.N(x,:)], 'r-', 1), ...
    sIdxs, 'UniformOutput', 0);

plt(ht, 'g--', 1);
ttl = sprintf('Contour from Z-Vectors\nTruth\nContour %d [%s]', ...
    cIdx, tSet);
title(ttl);

%% Show predicted Z-Vectors and Contours
subplot(row , col , pIdx); pIdx = pIdx + 1;
imagesc(img);
colormap gray;
axis image;
hold on;

arrayfun(@(x) plt(Zout.M(x,:), 'g.', 3), sIdxs, 'UniformOutput', 0);
arrayfun(@(x) plt([Zout.M(x,:) ; Zout.T(x,:)], 'b-', 1), ...
    sIdxs, 'UniformOutput', 0);
arrayfun(@(x) plt([Zout.M(x,:) ; Zout.N(x,:)], 'r-', 1), ...
    sIdxs, 'UniformOutput', 0);

plt(hp, 'g--', 1);
ttl = sprintf('Contour from Z-Vectors\nPredicted\nContour %d [%s]', ...
    cIdx, tSet);
title(ttl);

%% Overlay Ground Truth Vs Predicted Z-Vector
subplot(row , col , pIdx); pIdx = pIdx + 1;
imagesc(img);
colormap gray;
axis image;
hold on;

arrayfun(@(x) plt(mdt(x,:), 'g.', 3), sIdxs, 'UniformOutput', 0);
arrayfun(@(x) plt([mdt(x,:) ; tnt(x,:)], 'b--', 1), sIdxs, 'UniformOutput', 0);
arrayfun(@(x) plt([mdt(x,:) ; nrt(x,:)], 'r--', 1), sIdxs, 'UniformOutput', 0);

arrayfun(@(x) plt(mdp(x,:), 'go', 3), sIdxs, 'UniformOutput', 0);
arrayfun(@(x) plt([mdp(x,:) ; tnp(x,:)], 'b-', 1), sIdxs, 'UniformOutput', 0);
arrayfun(@(x) plt([mdp(x,:) ; nrp(x,:)], 'r-', 1), sIdxs, 'UniformOutput', 0);
ttl = sprintf('Z-Vectors only\nTruth Vs. Predicted\nContour %d [%s]', ...
    cIdx, tSet);
title(ttl);

%% Overlay Ground Truth Vs Predicted Contour
subplot(row , col , pIdx); pIdx = pIdx + 1;
imagesc(img);
colormap gray;
axis image;
hold on;

plt(ht, 'g--', 1);
plt(hp, 'y-', 1);
ttl = sprintf('Contour only\nTruth Vs. Predicted\nContour %d [%s]', ...
    cIdx, tSet);
title(ttl);

%% Save figure as .fig and .tif
if sav
    fnms{fIdx} = sprintf('%s_TruthVsPredictedContours_Contour%d_%s', ...
        tdate('s'), cIdx, fSet);
    savefig(figs(fIdx), fnms{fIdx});
    saveas(figs(fIdx), fnms{fIdx}, 'tiffn');
else
    pause(1);
end

end

function midFnc = getMidpointFunction(req, crv, pMids, midIdx)
%% getMidpointFunction: return function to get midpoint
switch req
    case 'truth'
        midFnc  = @(sIdx) crv.getMidPoint(sIdx);
        
    case 'predicted'
        %         midFnc  = @(sIdx) pMids(midIdx(sIdx),:);
        midFnc  = @(sIdx) pMids(midIdx(sIdx),1:2);
        
    otherwise
        % Default to raw midpoint value
        midFnc  = @(sIdx) crv.getMidPoint(sIdx);
end

end

function pm = getPmat(req, crv, zVec, sIdx)
%% reconstructPmat: return ground truth or generate the predicted Pmat
% Returns the ground truth Pmat directly from the Curve object or generates a
% Pmat from the predicted Z-Vector.
switch req
    case 'truth'
        pm = crv.getParameter('Pmats', sIdx);
        
    case 'predicted'
        pm = reconstructPmat(zVec(sIdx,:));
        %
        %         M    = zVec(1:2);
        %         T    = zVec(3:4) - M; % Pmats have T and N subtracted by M
        %         N    = zVec(5:6) - M; % Pmats have T and N subtracted by M
        %         tF   = [T(1) , T(2) , 0 ; ...
        %                 N(1) , N(2) , 0 ; ...
        %                 0    ,  0   , 1 ];
        %         mF   = [1    , 0    , -M(1) ; ...
        %                 0    , 1    , -M(2) ; ...
        %                 0    , 0    , 1 ];
        %         pm   = tF * mF;
        
    otherwise
        % Default to ground truth value
        pm = crv.getParameter('Pmats', sIdx);
end

end

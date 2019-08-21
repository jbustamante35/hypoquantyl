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

%% Set-up figure
fig = figure(f);
set(0, 'CurrentFigure', figure(f));
set(figure(f), 'Color', 'w');
cla;clf;

%% Determine number of PCs and run through plotter
pcx  = length(px.EigValues);
pcy  = length(py.EigValues);
pcz  = length(pz.EigValues);

%% Get midpoint indices and image data for contour
crv        = crvs(idx);
img        = crv.Parent.getImage('gray');
mids_truth = crv.getMidPoint(1:crv.NumberOfSegments);

% Extract x-/y-coordinates of contour from input and simulated PCA data
ttlSegs = crv.NumberOfSegments;
nxi     = extractIndices(idx, ttlSegs, px.InputData);
nxs     = extractIndices(idx, ttlSegs, px.SimData);
nyi     = extractIndices(idx, ttlSegs, py.InputData);
nys     = extractIndices(idx, ttlSegs, py.SimData);

% Set up output data and get truth or predicted midpoint function
[ci, cs]  = deal(zeros([size(nxi,1) , 2, size(nxi,3)]));
[mi, mc]  = deal([]);
mid_truth = zeros(size(mids_truth));
hlfSeg    = ceil(size(nxi,1)/2);
midIdx    = extractIndices(idx, ttlSegs, []);
midFnc    = getMidpointFunction(req, crv, pMids, midIdx);
pVector   = pMids(midIdx, :);

% Convert midpoints to to image frame coordinates
for sIdx = 1 : ttlSegs
    % Get midpoint coordinate and halfway segment coordinate
    %     pm                = crv.getParameter('Pmats', sIdx);
    pm                = reconstructPmat(req, crv, pVector, sIdx);
    mid_truth(sIdx,:) = midFnc(sIdx);
    iSeg              = [nxi(:,sIdx) nyi(:,sIdx)];
    sSeg              = [nxs(:,sIdx) nys(:,sIdx)];
    
    % Convert to image frame coordinates
    ci(:,:,sIdx) = reverseMidpointNorm(iSeg, pm) + mid_truth(sIdx,:);
    cs(:,:,sIdx) = reverseMidpointNorm(sSeg, pm) + mid_truth(sIdx,:);
    mi(:,:,sIdx) = reverseMidpointNorm(iSeg(hlfSeg,:), pm) + mid_truth(sIdx,:);
    mc(:,:,sIdx) = reverseMidpointNorm(sSeg(hlfSeg,:), pm) + mid_truth(sIdx,:);
end

%% Synthesized midpoint contours
mi = squeeze(mi)';
mc = squeeze(mc)';
mi = [mi ; mi(1,:)];
mc = [mc ; mc(1,:)];

syntHalf_inp = mi;
syntHalf_sim = mc;

%% Plot all segments for single contour [converted to image frame]
imagesc(img);
colormap gray;
axis image;
axis off;
hold on;

% Plot segments [debug mode]
%     for l = 1 : ttlSegs
%         plt(ci(:,:,l), 'b-', 2);
%         plt(cs(:,:,l), 'r-', 2);
%     end

% Plot midpoint skeletons, halfway coodinates, and predictions
% plt(mi,  'g-' , 2);  % Inputted halfway coordinates from PCA
% plt(mc,  'y-' , 2);  % Simulated halfway coordinates from PCA
plt(mids_truth, 'g.' , 10); % Actual midpoint coordinates
plt(mid_truth, 'r+' , 8);  % Requested midpoint coordinates

ttl = sprintf('Prediction Assessment [%s]\n%d x-PCs | %d y-PCs | %d z-PCs\nContour %d Backbone onto Contour %d Image', ...
    req, pcx, pcy, pcz, idx, idx);
title(ttl);

if sav
    fnm = sprintf('%s_PredictionAssessment_Contour%dContour%d_%s', ...
        tdate('s'), idx, idx, req);
    savefig(fig, fnm);
    saveas(fig, fnm, 'tiffn');
else
    pause(0.5);
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
function pm = reconstructPmat(req, crv, zVec, sIdx)
%% reconstructPmat: return ground truth or generate the predicted Pmat
% Returns the ground truth Pmat directly from the Curve object or generates a 
% Pmat from the predicted Z-Vector. 
switch req
    case 'truth'
        pm = crv.getParameter('Pmats', sIdx);
        
    case 'predicted'
        M    = zVec(1:2);
        T    = zVec(3:4) - M; % Pmats have T and N subtracted by M
        N    = zVec(5:6) - M; % Pmats have T and N subtracted by M
        tF   = [T(1) , T(2) , 0 ; ...
                N(1) , N(2) , 0 ; ...
                0    ,  0   , 1 ];
        mF   = [1    , 0    , -M(1) ; ...
                0    , 1    , -M(2) ; ...
                0    , 0    , 1 ];
        pm   = tF * mF;
        
    otherwise
        % Default to ground truth value
        pm = crv.getParameter('Pmats', sIdx);
end

end

function [syntHalf_inp, syntHalf_sim, fig] = plotFrankencotyls(idx1, idx2, px, py, pz, pMids, crvs, req, flp, sav, f)
%% plotFrankencotyls: Plot one hypocotyl's backbone onto another's flesh
%
%
% Usage:
%   fig = plotFrankencotyls(cIdx1, cIdx2, px, py, pz, crvs)
%
% Input:
%   cIdx1: index in crvs of hypocotyl 1 (provides backbone)
%   cIdx2: index in crvs of hypocotyl 2 (provides flesh)
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
cIdx = [idx1 , idx2];
pcx = length(px.EigValues);
pcy = length(py.EigValues);
pcz = length(pz.EigValues);

% Switch curves
if flp
    flpMe = 2;
else
    flpMe = 1;
end

[syntHalf_inp, syntHalf_sim] = deal(cell(1,flpMe));
for idx = 1:flpMe
    %% Switch idx at 2nd loop if flp selected
    if idx == 1
        cIdx1 = cIdx(1);
        cIdx2 = cIdx(2);
    elseif idx == 2
        cIdx1 = cIdx(2);
        cIdx2 = cIdx(1);
    end
    
    %% Get midpoint indices for contour 1 and image data for contour 2
    crv = crvs(cIdx2);
    img = crv.Parent.getImage('gray');
    MID = crv.getMidPoint(1:crv.NumberOfSegments);
    
    % Extract x-/y-coordinates of Contour1 from input and simulated PCA data
    ttlSegs  = crv.NumberOfSegments;
    [~, nxi] = extractIndices(cIdx1, ttlSegs, px.InputData);
    [~, nxs] = extractIndices(cIdx1, ttlSegs, px.SimData);
    [~, nyi] = extractIndices(cIdx1, ttlSegs, py.InputData);
    [~, nys] = extractIndices(cIdx1, ttlSegs, py.SimData);
    
    % Set up output data and get truth or predicted midpoint function
    [ci, cs] = deal(zeros([size(nxi,1) , 2, size(nxi,3)]));
    [mi, mc] = deal([]);
    mid      = zeros(size(MID));
    hlfSeg   = ceil(size(nxi,1)/2);
    midIdx   = extractIndices(cIdx2, ttlSegs, []);
    midFnc   = getMidpointFunction(req, crv, pMids, midIdx);
    
    % Convert midpoints to to image frame coordinates
    for sIdx = 1 : ttlSegs
        % Get midpoint coordinate and halfway segment coordinate
        pm          = crv.getParameter('Pmats', sIdx);
        mid(sIdx,:) = midFnc(sIdx);
        iSeg        = [nxi(:,sIdx) nyi(:,sIdx)];
        sSeg        = [nxs(:,sIdx) nys(:,sIdx)];
        
        % Convert to image frame coordinates
        ci(:,:,sIdx) = reverseMidpointNorm(iSeg, pm) + mid(sIdx,:);
        cs(:,:,sIdx) = reverseMidpointNorm(sSeg, pm) + mid(sIdx,:);
        mi(:,:,sIdx) = reverseMidpointNorm(iSeg(hlfSeg,:), pm) + mid(sIdx,:);
        mc(:,:,sIdx) = reverseMidpointNorm(sSeg(hlfSeg,:), pm) + mid(sIdx,:);
    end
    
    %% Synthesized midpoint contours
    mi = squeeze(mi)';
    mc = squeeze(mc)';
    mi = [mi ; mi(1,:)];
    mc = [mc ; mc(1,:)];
    
    syntHalf_inp{idx} = mi;
    syntHalf_sim{idx} = mc;
    
    %% Plot all segments for single contour [converted to image frame]
    subplot(1, flpMe, idx);
%     imshow(img, []);
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
    %     plt(mi,  'y-' , 2);   % Inputted halfway coordinates from PCA
    plt(mc,  'y-' , 2);  % Simulated halfway coordinates from PCA
    plt(MID, 'g-' , 1);  % Actual midpoint coordinates
    plt(mid, 'r.' , 10); % Requested midpoint coordinates
    
    ttl = sprintf('Prediction Assessment [%s]\n%d x-PCs | %d y-PCs | %d z-PCs\nContour %d Backbone onto Contour %d Image', ...
        req, pcx, pcy, pcz, cIdx2, cIdx1);
    title(ttl);
    
end

if sav
    fnm = sprintf('%s_PredictionAssessment_Contour%dContour%d_%s', ...
        tdate('s'), idx1, idx2, req);
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
        midFnc  = @(sIdx) pMids(midIdx(sIdx),:);
    otherwise
        % Default to raw midpoint value
        midFnc  = @(sIdx) crv.getMidPoint(sIdx);
end
end

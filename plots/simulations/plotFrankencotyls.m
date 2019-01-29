function fig = plotFrankencotyls(idx1, idx2, px, py, pz, pMids, crvs, req, f)
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
%   req: set to 'raw' or 'predicted' midpoint values
%   f: select index of figure
%
% Output:
%   fig: figure handle to generated data
%

%
fig = figure(f);
set(0, 'CurrentFigure', figure(f));
set(figure(f), 'Color', 'w');
cla;clf;

%%
cIdx = [idx1 , idx2];
pcx = length(px.EigValues);
pcy = length(py.EigValues);
pcz = length(pz.EigValues);

for idx = 1:2
    % Switch idx at 2nd loop
    if idx == 1
        cIdx1 = cIdx(1);
        cIdx2 = cIdx(2);
    elseif idx == 2
        cIdx1 = cIdx(2);
        cIdx2 = cIdx(1);
    end

    %
    crv = crvs(cIdx2);
    img = crv.Parent.getImage('gray');
    MID = crv.getMidPoint(1:crv.NumberOfSegments);

    % Extract x-/y-coordinates of Contour1 froPCA data
    ttlSegs  = crv.NumberOfSegments;
    [~, nxi] = extractIndices(cIdx1, ttlSegs, px.InputData);
    [~, nxs] = extractIndices(cIdx1, ttlSegs, px.SimData);
    [~, nyi] = extractIndices(cIdx1, ttlSegs, py.InputData);
    [~, nys] = extractIndices(cIdx1, ttlSegs, py.SimData);

    % Convert to image frame coordinates
    [ci, cs] = deal(zeros([size(nxi,1) , 2, size(nxi,3)]));
    [mi, mc] = deal([]);
    mid      = zeros(size(MID));
    hlfSeg   = ceil(size(nxi,1)/2);
    midIdx   = extractIndices(cIdx2, ttlSegs, []);
    midFnc = getMidpointFunction(req, crv, pMids, midIdx);    
    for sIdx = 1 : ttlSegs
        pm   = crv.getParameter('Pmats', sIdx);
        mid(sIdx,:) = midFnc(sIdx);
        iSeg = [nxi(:,sIdx) nyi(:,sIdx)];
        sSeg = [nxs(:,sIdx) nys(:,sIdx)];
        ci(:,:,sIdx) = reverseMidpointNorm(iSeg, pm) + mid(sIdx,:);
        cs(:,:,sIdx) = reverseMidpointNorm(sSeg, pm) + mid(sIdx,:);
        mi(:,:,sIdx) = reverseMidpointNorm(iSeg(hlfSeg,:), pm) + mid(sIdx,:);
        mc(:,:,sIdx) = reverseMidpointNorm(sSeg(hlfSeg,:), pm) + mid(sIdx,:);
    end

    % Predicted midpoint coordinates
%     [~, pMidCrd] = extractIndices(cIdx2, ttlSegs, pMids);

    % Synthesized midpoint contours
    mi = squeeze(mi)';
    mc = squeeze(mc)';
    mi = [mi ; mi(1,:)];
    mc = [mc ; mc(1,:)];

    %% Plot all segments for single contour [converted to image frame]
    subplot(1, 2, idx);
    imagesc(img);
    hold on;
%     for l = 1 : ttlSegs
%         plt(ci(:,:,l), 'b-', 2);
%         plt(cs(:,:,l), 'r-', 2);
%     end

    % Plot midpoint skeletons, halfway coodinates, and predictions
    plt(mi, 'g-', 3);   % Inputted halfway coordinates from PCA
    plt(mc, 'm-', 3);   % Simulatd halfway coordinates from PCA
    plt(MID, 'y-', 3);  % Actual midpoint coordinates
    plt(mid, 'r--', 3); % Requested midpoint coordinates
%     plt(pMidCrd', 'r--', 3); % Midpoint Predictions from PLS

    colormap bone;
    axis image;
    axis ij;
    ttl = sprintf('Frankencotyls [%s]\n%d x-PCs | %d y-PCs | %d z-PCs\nContour %d Backbone onto Contour %d Image', ...
        req, pcx, pcy, pcz, cIdx2, cIdx1);
    title(ttl);

end

end

function midFnc = getMidpointFunction(req, crv, pMids, midIdx)
%% getMidpointFunction: return function to get midpoint
switch req
    case 'raw'
        midFnc  = @(sIdx) crv.getMidPoint(sIdx);

    case 'predicted'
        midFnc  = @(sIdx) pMids(midIdx(sIdx),:);
    otherwise
        % Default to raw midpoint value
        midFnc  = @(sIdx) crv.getMidPoint(sIdx);
end
end

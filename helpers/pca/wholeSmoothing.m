function [trgs , pdx , pdy] = wholeSmoothing(trgs, PF)
%% wholeSmoothing: PCA smoothing of whole contour
%
%
% Usage:
%   [trgs , pdx , pdy] = wholeSmoothing(trgs, PF)
%
% Input:
%   trgs:
%   PF:
%
% Output:
%   trgs:
%   pdx:
%   pdy:
%

%% Separate X-/Y-Coordinates and Determine projection direction
dx = squeeze((trgs(:,1,:)))';
dy = squeeze((trgs(:,2,:)))';

switch numel(PF)
    case 1
        %% Build PC space with ground truth data
        npf = PF;
        pdx = myPCA(dx, npf);
        pdy = myPCA(dy, npf);
        
    case 2
        %% Project and Back-Project into PC space
        pdx = PF(1);
        pdy = PF(2);
        
        % Smooth X-Coordinates
        dx = pcaProject(dx, pdx.EigVecs, pdx.MeanVals, 'sim2scr');
        dx = pcaProject(dx, pdx.EigVecs, pdx.MeanVals, 'scr2sim');
        
        % Smooth  Y-Coordinates
        dy = pcaProject(dy, pdy.EigVecs, pdy.MeanVals, 'sim2scr');
        dy = pcaProject(dy, pdy.EigVecs, pdy.MeanVals, 'scr2sim');
        
        % Back-Project and reshape
        dprex = reshape(dx', [size(trgs,1), 1, size(trgs,3)]);
        dprey = reshape(dy', [size(trgs,1), 1, size(trgs,3)]);
        trgs  = [dprex , dprey , ones(size(dprex))];
end

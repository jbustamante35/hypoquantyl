function [trgs , pdx , pdy] = wholeSmoothing(trgs, PF, npcs)
%% wholeSmoothing: PCA smoothing of whole contour
%
%
% Usage:
%   [trgs , pdx , pdy] = wholeSmoothing(trgs, PF, npcs)
%
% Input:
%   trgs:
%   PF:
%   npcs: number of dimensions to project in (default [])
%
% Output:
%   trgs:
%   pdx:
%   pdy:
%

if nargin < 3; npcs = []; end

%% Separate X-/Y-Coordinates and Determine projection direction
dx = squeeze((trgs(:,1,:)))';
dy = squeeze((trgs(:,2,:)))';

switch class(PF)
    case 'double'
        %% Build PC space with ground truth data
        npf = PF;
        pdx = myPCA(dx, npf(1));
        pdy = myPCA(dy, npf(2));
    case 'PcaJB'
        %% Project to image space then Back-Project into PC space
        pdx = PF(1);
        pdy = PF(2);

        if isempty(npcs)
%             [npx , npy] = deal(pdx.NumberOfPCs);
            npx = pdx.NumberOfPCs;
            npy = pdy.NumberOfPCs;
        else
            % Check if using different number of PCs for X and Y
            if numel(npcs) == 2
                npx = npcs(1);
                npy = npcs(2);
            else
                [npx , npy] = deal(npcs);
            end
        end

        % Smooth and back-project  X-Coordinates
        dx = pcaProject(dx, pdx.EigVecs(npx), pdx.MeanVals, 'sim2scr');
        dx = pcaProject(dx, pdx.EigVecs(npx), pdx.MeanVals, 'scr2sim');

        % Smooth and back-project Y-Coordinates
        dy = pcaProject(dy, pdy.EigVecs(npy), pdy.MeanVals, 'sim2scr');
        dy = pcaProject(dy, pdy.EigVecs(npy), pdy.MeanVals, 'scr2sim');

        % Reshape and Concatenate
        dprex = reshape(dx', [size(trgs,1), 1, size(trgs,3)]);
        dprey = reshape(dy', [size(trgs,1), 1, size(trgs,3)]);
        trgs  = [dprex , dprey , ones(size(dprex))];
end
end

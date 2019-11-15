function [px, py, pz, pp] = hypoquantylPCA(CRVS, sav, pcx, pcy, pcz, pcp)
%% hypoquantylPCA: run PCA on x-/y-coordinates and z-vectors
% Description
%
% Usage:
%    [px, py, pz, pp] = hypoquantylPCA(CRVS, sav, pcx, pcy, pcz, pcp)
%
% Input:
%   CRVS array of Curve objects to extract data from
%   sav: boolean to save output as .mat file
%   pcx: number of PCs to extract from x-coordinates [optional]
%   pcy: number of PCs to extract from y-coordinates [optional]
%   pcz: number of PCs to extract from z-vectors [optional]
%   pcp: number of PCs to extract from z-patches [optional]
%
%
% Output:
%   px: PCA object from midpoint-normalized x-coordinates
%   py: PCA object from midpoint-normalized y-coordinates
%   pz: PCA object from Z-Vectors
%   pp: PCA object from Z-Patches
%
% Author Julian Bustamante <jbustamante@wisc.edu>
%

%% Information on Dataset
numCrvs = numel(CRVS);
ttlSegs = CRVS(1).NumberOfSegments;

% Get default PCs
if nargin < 3
    [pcx , pcy] = deal(3);
    pcz         = 10;
    pcp         = 5;
end

%% Split and Midpoint-Normalize x-/y-coordinates
% Prepare rasterized data
[rX , rY] = arrayfun(@(c) c.rasterizeSegments, CRVS, 'UniformOutput', 0);
rX        = cat(1, rX{:});
rY        = cat(1, rY{:});

%% Rasterize Z-Vectors and Generate Z-Patches
% Prepare and Process Z-Vectors [Midpoints and Tangents only]
rZ = arrayfun(@(c) c.getZVector(1:4), CRVS, 'UniformOutput', 0);
rZ = cellfun(@(z) zVectorConversion(z, ttlSegs, 1, 'prep'), ...
    rZ, 'UniformOutput', 0);
rZ = cat(1, rZ{:});

% Prepare and Process Z-Patches
rP = arrayfun(@(c) c.getZPatch, CRVS, 'UniformOutput', 0);
rP = cat(2, rP{:});
rP = cellfun(@(x) x(:), rP, 'UniformOutput', 0);
rP = cat(2, rP{:})';

%% Run PCA on x-/y-coordinates and Z-Vectors
% Run PCA on x-coordinates
xnm = sprintf('x%dHypocotyls', numCrvs);
px  = pcaAnalysis(rX, pcx, sav, xnm, 0);

% Run PCA on y-coordinates
ynm = sprintf('y%dHypocotyls', numCrvs);
py  = pcaAnalysis(rY, pcy, sav, ynm, 0);

% Run PCA on z-Vectors
znm = sprintf('z%dHypocotyls', numCrvs);
pz  = pcaAnalysis(rZ, pcz, sav, znm, 0);

% Run PCA on z-patches
pnm = sprintf('zp%dHypocotyls', numCrvs);
pp  = pcaAnalysis(rP, pcp, sav, pnm, 0);

end



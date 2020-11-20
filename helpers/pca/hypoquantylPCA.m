function [px, py, pz, pp] = hypoquantylPCA(CRVS, sav, pcx, pcy, pcz, pcp, addMid)
%% hypoquantylPCA: run PCA on x-/y-coordinates and z-vectors
% Description
%
%
% Usage:
%    [px, py, pz, pp] = hypoquantylPCA(CRVS, sav, pcx, pcy, pcz, pcp, addMid)
%
% Input:
%   CRVS array of Curve objects to extract data from
%   sav: boolean to save output as .mat file
%   pcx: number of PCs to extract from x-coordinates [optional]
%   pcy: number of PCs to extract from y-coordinates [optional]
%   pcz: number of PCs to extract from z-vectors [optional]
%   pcp: number of PCs to extract from z-patches [optional]
%   addMid: add midpoint vector to tangent and normal vectors (default 0)
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

% Separator strings
[~ , sepA , sepB] = jprintf('', 0, 0);

% Get default PCs
switch nargin
    case 1
        sav         = 0;
        [pcx , pcy] = deal(6);
        pcz         = 20;
        pcp         = 10;
        addMid      = 0;
    case 2
        [pcx , pcy] = deal(6);
        pcz         = 20;
        pcp         = 10;
        addMid      = 0;
    case 6
        addMid      = 0;
    case 7        
    otherwise
        fprintf(2, 'Error with inputs (%d)\n', nargin);
        [px, py, pz, pp] = deal([]);
        return;
end

%
tAll = tic;
fprintf('%s\nRunning HypoQuantyl PCA Pipeline [%d %ss | %d pcx | %d pcy | %d pcz | %d pcp]\n%s\n', ...
    sepA, numCrvs, class(CRVS), pcx, pcy, pcz, pcp, sepB);

%% Split and Midpoint-Normalize x-/y-coordinates
[rX , rY , rZ , rP] = deal(zeros(numCrvs, 1));

% Prepare rasterized data
t = tic;
n = fprintf('Preparing and Processing S-Vectors');
if pcx > 0 && pcy > 0
    [rX , rY] = arrayfun(@(c) c.rasterizeSegments, CRVS, 'UniformOutput', 0);
    rX        = cat(1, rX{:});
    rY        = cat(1, rY{:});
end
jprintf(' ', toc(t), 1, 80 - n);

%% Rasterize Z-Vectors and Generate Z-Patches
% Prepare and Process Z-Vectors [Midpoints and Tangents only]
t = tic;
n = fprintf('Preparing and Processing Z-Vectors');

if pcz > 0
    rZ = arrayfun(@(c) c.getZVector(1:4, addMid), CRVS, 'UniformOutput', 0);
    rZ = cellfun(@(z) zVectorConversion(z, ttlSegs, 1, 'prep'), ...
        rZ, 'UniformOutput', 0);
    rZ = cat(1, rZ{:});
end

jprintf(' ', toc(t), 1, 80 - n);

% Prepare and Process Z-Patches
t = tic;
n = fprintf('Generating Z-Patches');

if pcp > 0
    rP = arrayfun(@(c) c.getZPatch, CRVS, 'UniformOutput', 0);
    rP = cat(2, rP{:});
    rP = cellfun(@(x) x(:), rP, 'UniformOutput', 0);
    rP = cat(2, rP{:})';
end

jprintf(' ', toc(t), 1, 80 - n);

%% Run PCA on x-/y-coordinates and Z-Vectors
t = tic;
n = fprintf('Performing PCA on all datasets');

% Run PCA on x-coordinates
xnm = sprintf('x%dHypocotyls', numCrvs);
px  = pcaAnalysis(rX, pcx, sav, xnm);

% Run PCA on y-coordinates
ynm = sprintf('y%dHypocotyls', numCrvs);
py  = pcaAnalysis(rY, pcy, sav, ynm);

% Run PCA on z-Vectors
znm = sprintf('z%dHypocotyls', numCrvs);
pz  = pcaAnalysis(rZ, pcz, sav, znm);

% Run PCA on z-patches
pnm = sprintf('zp%dHypocotyls', numCrvs);
pp  = pcaAnalysis(rP, pcp, sav, pnm);

jprintf(' ', toc(t), 1, 80 - n);

fprintf('%s\nFinished PCA pipeline on %d %ss [ %.03f sec]\n%s\n', ...
    sepB, numCrvs, class(CRVS), toc(tAll), sepA);

end

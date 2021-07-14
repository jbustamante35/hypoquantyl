function [px, py, pz, pp] = hypoquantylPCA(CRVS, sav, varargin)
%% hypoquantylPCA: run PCA on x-/y-coordinates and z-vectors
% Description
%
%
% Usage:
%   [px, py, pz, pp] = hypoquantylPCA(CRVS, sav, ...
%       'pcx', pcx, 'pcy', pcy, 'pcz', pcz, 'pcp', pcp, ...
%       'addMid', addMid, 'zrotate', zrotate, 'rtyp', rtyp, ...
%       'znorm', znorm, 'zshp', zshp, 'split2stitch', split2stitch)
%
% OLD METHOD
%   [px, py, pz, pp] = hypoquantylPCA(CRVS, sav, ...
%       pcx, pcy, pcz, pcp, addMid, zrotate, rtyp, znorm, zshp, split2stitch)
%
% Input:
%   CRVS array of Curve objects to extract data from (required)
%   sav: boolean to save output as .mat file (required)
%   pcx: number of PCs to extract from x-coordinates [default 6]
%   pcy: number of PCs to extract from y-coordinates [default 6]
%   pcz: number of PCs to extract from z-vectors [default 10]
%   pcp: number of PCs to extract from z-patches [default 10]
%   addMid: add midpoint vector to tangent and normal vectors (default 0)
%   zrotate: use rotation vector instead of tangent-normals (default 0)
%   rtyp: rotation vector units in degrees or radians [deg|rad] (default rad)
%   znorm: perform Z-Score normalization on input (default 0) * NOTE *
%   zshp: dimensions to reshape inputs before znorm (default 0) * NOTE *
%   split2stitch: split Z-Vectors then restitch after PCA (default 0)
%
% ---------------------------------------------------------------------------- %
% NOTE [Z-Score Normalization]
%   This should be a structure containing boolean values designating whether to
%   Z-Score normalize for each PCA, and should be accompanied by a 'zshp'
%   structure definine the reshape dimensions.
%       n     = CRVS(1).NumberOfSegments * numel(CRVS);
%       d     = 4; % MidpointX , MidpointY , TangentX , TangentY
%
%       znorm = struct('ps', 0, 'pz', 1,       'pp', 0);
%       zshp  = struct('ps', 0, 'pz', [n , d], 'pp', 0);
%
%   If performing PCA with split2stitch, there should be 2 separate values for
%   'pz' indicated by a cell array.
%       n     = CRVS(1).NumberOfSegments * numel(CRVS);
%       dmid  = 2; % MidpointX , MidpointY
%       dtng  = 2; % TangentX, TangentY
%
%       znorm = struct('ps', 0, 'pz', {1 , 1},                   'pp', 0);
%       zshp  = struct('ps', 0, 'pz', {[n , dmid] , [n , dtng]}, 'pp', 0);
%
% ---------------------------------------------------------------------------- %
%
% Output:
%   px: PCA object from midpoint-normalized x-coordinates
%   py: PCA object from midpoint-normalized y-coordinates
%   pz: PCA object from Z-Vectors
%   pp: PCA object from Z-Patches
%
% Author Julian Bustamante <jbustamante@wisc.edu>
%

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

%% Information on Dataset
ncrvs = numel(CRVS);
nsegs = CRVS(1).NumberOfSegments;

% Separator strings
[~ , sepA , sepB] = jprintf('', 0, 0);

% Set default arguments
switch nargin
    case 1
        sav = 0;
end

tAll = tic;

if iscell(pcz)
    fprintf('%s\nRunning HypoQuantyl PCA Pipeline [%d %ss | %d pcx | %d pcy | [%d-%d] pcz | %d pcp]\n%s\n', ...
        sepA, ncrvs, class(CRVS), pcx, pcy, pcz{1}, pcz{2}, pcp, sepB);
else
    fprintf('%s\nRunning HypoQuantyl PCA Pipeline [%d %ss | %d pcx | %d pcy | %d pcz | %d pcp]\n%s\n', ...
        sepA, ncrvs, class(CRVS), pcx, pcy, pcz, pcp, sepB);
end

[px , py , pz , pp] = deal([]);

%% Split and Midpoint-Normalize x-/y-coordinates [S-Vectors]
% Prepare rasterized data
t = tic;
n = fprintf('Preparing and Processing S-Vectors');
if pcx > 0 && pcy > 0
    [rX , rY] = arrayfun(@(c) c.rasterizeSegments, CRVS, 'UniformOutput', 0);

    X         = cat(1, rX{:});
    Y         = cat(1, rY{:});
    [px , py] = svectorPCA(X, Y, ncrvs, pcx, pcy, sav, znorm.ps, zshp.ps);
end

jprintf(' ', toc(t), 1, 80 - n);

% ---------------------------------------------------------------------------- %
%% Rasterize and Reshape Z-Vectors
% Prepare and Process Z-Vectors [Midpoints and Tangents only]
t = tic;
n = fprintf('Preparing and Processing Z-Vectors');

if iscell(pcz)
    zchk = cat(1, pcz{:});
else
    zchk = pcz;
end

if zchk > 0
    rZ = arrayfun(@(c) c.getZVector(1:4, addMid, zrotate, rtyp), ...
        CRVS, 'UniformOutput', 0);
    Z  = cat(1, rZ{:});
    pz = zvectorPCA(Z, sav, pcz, nsegs, ncrvs, ...
        addMid, zrotate, rtyp, znorm.pz, zshp.pz, split2stitch);

end

jprintf(' ', toc(t), 1, 80 - n);

% ---------------------------------------------------------------------------- %
%% Generate and Process Z-Patches
t = tic;
n = fprintf('Generating Z-Patches');

if pcp > 0
    rP = arrayfun(@(c) c.getZPatch, CRVS, 'UniformOutput', 0);
    rP = cat(2, rP{:});
    P  = cellfun(@(x) x(:), rP, 'UniformOutput', 0);
    P  = cat(2, P{:})';

    pp = zpatchPCA(P, sav, ncrvs, pcp, znorm.pp, zshp.pp);

end

jprintf(' ', toc(t), 1, 80 - n);

% ---------------------------------------------------------------------------- %
%% DEPRECATED [04.07.2021] - Replaced by sub-functions that perform PCA
% %% Run PCA on x-/y-coordinates and Z-Vectors
% t = tic;
% n = fprintf('Performing PCA on all datasets');
%
% % Run PCA on x-coordinates
% xnm = sprintf('x%dHypocotyls', numCrvs);
% px  = pcaAnalysis(rX, pcx, sav, xnm, ...
%     'ZScoreNormalize', znorm, 'ZScoreReshape', zshp);
%
% % Run PCA on y-coordinates
% ynm = sprintf('y%dHypocotyls', numCrvs);
% py  = pcaAnalysis(rY, pcy, sav, ynm, ...
%     'ZScoreNormalize', znorm, 'ZScoreReshape', zshp);
%
% % Run PCA on z-Vectors
% znm = sprintf('z%dHypocotyls', numCrvs);
% pz  = pcaAnalysis(rZ, pcz, sav, znm, ...
%     'ZScoreNormalize', znorm, 'ZScoreReshape', zshp);
%
% % Run PCA on z-patches
% pnm = sprintf('zp%dHypocotyls', numCrvs);
% pp  = pcaAnalysis(rP, pcp, sav, pnm, ...
%     'ZScoreNormalize', znorm, 'ZScoreReshape', zshp);
%
% jprintf(' ', toc(t), 1, 80 - n);
% ---------------------------------------------------------------------------- %

fprintf('%s\nFinished PCA pipeline on %d %ss [ %.03f sec]\n%s\n', ...
    sepB, ncrvs, class(CRVS), toc(tAll), sepA);

end

function [px , py] = svectorPCA(X, Y, ncrvs, pcx, pcy, sav, znorm, zshp)
%% S-Vectors: x-coordinates and y-coordinates of segments
% Run PCA on x-coordinates
xnm = sprintf('x%dHypocotyls', ncrvs);
px  = pcaAnalysis(X, pcx, sav, xnm, ...
    'ZScoreNormalize', znorm, 'ZScoreReshape', zshp);

% Run PCA on y-coordinates
ynm = sprintf('y%dHypocotyls', ncrvs);
py  = pcaAnalysis(Y, pcy, sav, ynm, ...
    'ZScoreNormalize', znorm, 'ZScoreReshape', zshp);

end

function pz = zvectorPCA(Z, sav, pcz, nsegs, ncrvs, addMid, zrotate, rtyp, znorm, zshp, split2stitch)
%% Z-Vectors
if zrotate
    % Rotations
    vvec = 3;
    vtyp = 'rotations';
else
    % Tangents
    vvec = 3 : 4;
    vtyp = 'tangents';
end

if split2stitch
    % Split midpoints from tangent/rotations, then stitch after PCA
    zmids = Z(:,1:2);
    ztngs = Z(:,vvec);
    vmids = zVectorConversion(zmids, nsegs, ncrvs, 'prep', addMid, rtyp);
    vtngs = zVectorConversion(ztngs, nsegs, ncrvs, 'prep', addMid, rtyp);

    mnm = sprintf('z%dHypocotyls_midpoints', ncrvs);
    vnm = sprintf('z%dHypocotyls_%s', ncrvs, vtyp);
    pm  = pcaAnalysis(vmids, pcz{1}, 0, mnm, ...
        'ZScoreNormalize', znorm{1}, 'ZScoreReshape', zshp{1});
    pv  = pcaAnalysis(vtngs, pcz{2}, 0, vnm, ...
        'ZScoreNormalize', znorm{2}, 'ZScoreReshape', zshp{2});

    pz = struct('mids', pm, vtyp, pv);

    if sav
        znm = sprintf('z%dHypocotyls', ncrvs);
        save(znm, '-v7.3', 'pz');
    end

else
    % PCA with midpoints-tangents/rotations together (default)
    if iscell(Z)
        Z = cellfun(@(z) zVectorConversion(z, nsegs, 1, 'prep', rtyp), ...
            Z, 'UniformOutput', 0);
        Z = cat(1, Z{:});
    else
        Z = zVectorConversion(Z, nsegs, ncrvs, 'prep', rtyp);
    end

    znm = sprintf('z%dHypocotyls', ncrvs);
    pz  = pcaAnalysis(Z, pcz, sav, znm, ...
        'ZScoreNormalize', znorm, 'ZScoreReshape', zshp);

end

end

function pp = zpatchPCA(P, sav, ncrvs, pcp, znorm, zshp)
%% Z-Vector patches
% Run PCA on z-patches
pnm = sprintf('zp%dHypocotyls', ncrvs);
pp  = pcaAnalysis(P, pcp, sav, pnm, ...
    'ZScoreNormalize', znorm, 'ZScoreReshape', zshp);

end

function args = parseInputs(varargin)
%% Parse input parameters

p = inputParser;
p.addOptional('pcx', 6);
p.addOptional('pcy', 6);
p.addOptional('pcz', 10);
p.addOptional('pcp', 10);
p.addOptional('addMid', 0);
p.addOptional('zrotate', 0);
p.addOptional('rtyp', 'rad');
p.addOptional('znorm', struct('ps', 0, 'pz', 0, 'pp', 0));
p.addOptional('zshp', struct('ps', 0, 'pz', 0, 'pp', 0));
p.addOptional('split2stitch', 0);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end

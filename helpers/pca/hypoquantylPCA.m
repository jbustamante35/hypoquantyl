function [px , py , pz , pp , pm , pc , pv , pt] = hypoquantylPCA(CRVS, sav, varargin)
%% hypoquantylPCA: run PCA on x-/y-coordinates and z-vectors
% Perform PCA on various aspects of Curves
%
% Usage:
%   [px , py , pz , pp , pm , pc , pv , pt] = hypoquantylPCA(CRVS, sav, ...
%       'pcx', pcx, 'pcy', pcy, 'pcz', pcz, 'pcp', pcp, ...
%       'addMid', addMid, 'zrotate', zrotate, 'rtyp', rtyp, ...
%       'znorm', znorm, 'zshp', zshp, 'split2stitch', split2stitch)
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
%   pc: PCA object for vectorized contours
%   pv: PCA object for vectorized midlines
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
[~ , sprA , sprB] = jprintf('', 0, 0);

% Set default arguments
if nargin < 2; sav = 0; end

tAll = tic;
if iscell(pcz)
    fprintf(['%s\nRunning HypoQuantyl PCA Pipeline [%d %ss | %d pcx | ' ...
        '%d pcy | [%d-%d] pcz | %d pcp | %d pcm]\n%s\n'], ...
        sprA, ncrvs, class(CRVS), pcx, pcy, pcz{1}, pcz{2}, pcp, pcm, sprB);
else
    fprintf(['%s\nRunning HypoQuantyl PCA Pipeline [%d %ss | %d pcx | ' ...
        '%d pcy | %d pcz | %d pcp | %d pcm]\n%s\n'], ...
        sprA, ncrvs, class(CRVS), pcx, pcy, pcz, pcp, pcm, sprB);
end

% Extract and Histogram-Normalize Images
IMGS = arrayfun(@(x) x.getImage('gray', 'upper', fnc, ...
    [], mbuf, abuf, scl), CRVS, 'UniformOutput', 0);
if ~isempty(href)
    hhist = href.Data;
    hmth  = href.Tag;
    nbins = href.NumBins;
    IMGS  = cellfun(@(x) normalizeImageWithHistogram( ...
        x, hhist, hmth, nbins), IMGS, 'UniformOutput', 0);
end

[px , py , pz , pp , pm , pc , pv , pt] = deal([]);

%% Split and Midpoint-Normalize x-/y-coordinates [S-Vectors]
% Rasterize S-Vectors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                           [NOTE 10.05.2021]
% I removed the Curve.rasterizeSegments function, so fix this if I ever get back
% to using S-Vectors [which I likely never will, unless I change it's meaning]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
t = tic;
n = fprintf('Preparing and Processing S-Vectors');
if pcx > 0 && pcy > 0
    [rX , rY] = arrayfun(@(c) c.rasterizeSegments, CRVS, 'UniformOutput', 0);
    X         = cat(1, rX{:});
    Y         = cat(1, rY{:});
    [px , py] = svectorPCA(X, Y, ncrvs, pcx, pcy, znorm.ps, zshp.ps);
end
jprintf(' ', toc(t), 1, 80 - n);

% ---------------------------------------------------------------------------- %
%% Rasterize and Reshape Z-Vectors
% Prepare and Process Z-Vectors
t = tic;
n = fprintf('Preparing and Processing Z-Vectors');
if iscell(pcz); zchk = cat(1, pcz{:}); else; zchk = pcz; end

if zchk > 0
    midx = round(nsplt / 2);
    rZ   = arrayfun(@(c) c.getZVector(zdims, 'vsn', vsn, 'fnc', fnc, ...
        'addMid', addMid, 'rot', zrotate, 'rtyp', rtyp, 'dpos', dpos, ...
        'nsplt', nsplt, 'midx', midx, 'bdsp', bdsp, 'mbuf', mbuf, ...
        'scl', scl), CRVS, 'UniformOutput', 0);
    Z   = cat(1, rZ{:});
    pz  = zvectorPCA(Z, sav, pcz, nsegs, ncrvs, ...
        addMid, zrotate, rtyp, znorm.pz, zshp.pz, split2stitch);
end
jprintf(' ', toc(t), 1, 80 - n);

% ---------------------------------------------------------------------------- %
%% Generate and Process Z-Patches
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                           [NOTE 10.05.2021]
% This doesn't account for the contour version or function to apply to the
% contours. So fix this to add in those parameters.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
t = tic;
n = fprintf('Generating Z-Patches');
if pcp > 0
    rP = arrayfun(@(c) c.getZPatch, CRVS, 'UniformOutput', 0);
    rP = cat(2, rP{:});
    P  = cellfun(@(x) x(:), rP, 'UniformOutput', 0);
    P  = cat(2, P{:})';
    pp = zpatchPCA(P, ncrvs, pcp, znorm.pp, zshp.pp);
end
jprintf(' ', toc(t), 1, 80 - n);

% ---------------------------------------------------------------------------- %
%% Generate Midlines and Midline Patches
t = tic;
n = fprintf('Generating Midline Patches');
if pcm > 0
    % Get images and normalize with histogram if given
    mP = arrayfun(@(x) x.getMidline(mmth, mtyp), CRVS, 'UniformOutput', 0);
    mp = cellfun(@(i,m) msample(i,m), IMGS, mP, 'UniformOutput', 0);
    %     mp = cellfun(@(i,m) sampleMidline(i, m, 0, psz, 'full'), ...
    %         IMGS, mP, 'UniformOutput', 0);
    MP = cellfun(@(x) x(:)', mp, 'UniformOutput', 0);
    MP = cat(1, MP{:});
    pm = mpatchPCA(MP, ncrvs, pcm);
end
jprintf(' ', toc(t), 1, 80 - n);

% ---------------------------------------------------------------------------- %
%% Vectorize and Stitch Contours-Midlines
t = tic;
n = fprintf('Generating Contour-Midline Stitching');
if pcv > 0 && pmv > 0
    CTRU = arrayfun(@(x) x.getTrace(vsn, fnc, mbuf, scl), ...
        CRVS, 'UniformOutput', 0);
    MTRU = arrayfun(@(x) x.getMidline('pca', fnc, mbuf, scl), ...
        CRVS, 'UniformOutput', 0);
    MC   = cell2mat(cellfun(@(x) x(:)', CTRU, 'UniformOutput', 0));
    MM   = cell2mat(cellfun(@(x) x(:)', MTRU, 'UniformOutput', 0));

    [pc , pv] = stitchPCA(MC, MM, ncrvs, pcv, pmv);
end
jprintf(' ', toc(t), 1, 80 - n);

% ---------------------------------------------------------------------------- %
%% Cotyledon Patches
t = tic;
n = fprintf('Generating Cotyledon Patches');
if pct > 0
    tP = cellfun(@(i,c) tsample(i,c), IMGS, CTRU, 'UniformOutput', 0);
    TP = cell2mat(cellfun(@(x) x(:)', tP, 'UniformOutput', 0));
    pt = tpatchPCA(TP, ncrvs, pct);
end
jprintf(' ', toc(t), 1, 80 - n);

% ---------------------------------------------------------------------------- %
%% Save datasets
t = tic;
n = fprintf('Saving PCA Datasets');
if sav
    pdir = sprintf('%s/pca', SaveDir);
    if ~isfolder(pdir); mkdir(pdir); pause(0.5); end
    if ~isempty(px); save([pdir , filesep , px.DataName], '-v7.3', 'px'); end
    if ~isempty(py); save([pdir , filesep , py.DataName], '-v7.3', 'py'); end
    if ~isempty(pz); save([pdir , filesep , pz.DataName], '-v7.3', 'pz'); end
    if ~isempty(pp); save([pdir , filesep , pp.DataName], '-v7.3', 'pp'); end
    if ~isempty(pm); save([pdir , filesep , pm.DataName], '-v7.3', 'pm'); end
    if ~isempty(pc); save([pdir , filesep , pc.DataName], '-v7.3', 'pc'); end
    if ~isempty(pv); save([pdir , filesep , pv.DataName], '-v7.3', 'pv'); end
end
jprintf(' ', toc(t), 1, 80 - n);

fprintf('%s\nFinished PCA pipeline on %d %ss [ %.03f sec]\n%s\n', ...
    sprB, ncrvs, class(CRVS), toc(tAll), sprA);
end

function [px , py] = svectorPCA(X, Y, ncrvs, pcx, pcy, znorm, zshp)
%% S-Vectors: x-coordinates and y-coordinates of segments
% Run PCA on x-coordinates
xnm = sprintf('x%dHypocotyls', ncrvs);
px  = pcaAnalysis(X, pcx, 0, xnm, ...
    'ZScoreNormalize', znorm, 'ZScoreReshape', zshp);

% Run PCA on y-coordinates
ynm = sprintf('y%dHypocotyls', ncrvs);
py  = pcaAnalysis(Y, pcy, 0, ynm, ...
    'ZScoreNormalize', znorm, 'ZScoreReshape', zshp);
end

function pz = zvectorPCA(Z, sav, pcz, nsegs, ncrvs, addMid, zrotate, rtyp, znorm, zshp, split2stitch)
%% Z-Vectors: Midpoint-Tangent-Normals from contours
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
    zmids = Z(:, 1 : 2);
    ztngs = Z(:, vvec);
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
    pz  = pcaAnalysis(Z, pcz, 0, znm, ...
        'ZScoreNormalize', znorm, 'ZScoreReshape', zshp);
end
end

function pp = zpatchPCA(P, ncrvs, pcp, znorm, zshp)
%% Z-Vector patches
% Run PCA on z-patches
pnm = sprintf('zp%dHypocotyls', ncrvs);
pp  = pcaAnalysis(P, pcp, 0, pnm, ...
    'ZScoreNormalize', znorm, 'ZScoreReshape', zshp);
end

function pm = mpatchPCA(MP, ncrvs, pcm)
%% Midline Patches
mnm = sprintf('mp%dHypocotyls', ncrvs);
pm  = pcaAnalysis(MP, pcm, 0, mnm);
end

function [pc , pv] = stitchPCA(MC, MM, ncrvs, pnc, pnv)
%% Contour-Midline PCA stitching
cnm = sprintf('cvector%dHypocotyls', ncrvs);
vnm = sprintf('mvector%dHypocotyls', ncrvs);
pc  = pcaAnalysis(MC, pnc, 0, cnm);
pv  = pcaAnalysis(MM, pnv, 0, vnm);
end

function pt = tpatchPCA(TP, ncrvs, pct)
%% Cotyledon Patches
tnm = sprintf('tp%dHypocotyls', ncrvs);
pt  = pcaAnalysis(TP, pct, 0, tnm);
end

function args = parseInputs(varargin)
%% Parse input parameters

p = inputParser;
p.addOptional('pcx', 6);
p.addOptional('pcy', 6);
p.addOptional('pcz', 10);
p.addOptional('pcp', 10);
p.addOptional('pcm', 20);
p.addOptional('pcv', 20);
p.addOptional('pmv', 20);
p.addOptional('pct', 3);
p.addOptional('addMid', 0);
p.addOptional('zrotate', 0);
p.addOptional('rtyp', 'rad');
p.addOptional('dpos', 0);
p.addOptional('bdsp', 0);
p.addOptional('mmth', 'nate');
p.addOptional('mtyp', 'left');
p.addOptional('nsplt', 25);
p.addOptional('znorm', struct('ps', 0, 'pz', 0, 'pp', 0));
p.addOptional('zshp',  struct('ps', 0, 'pz', 0, 'pp', 0));
p.addOptional('split2stitch', 0);
p.addOptional('msample', []);
p.addOptional('tsample', []);
p.addOptional('SaveDir', pwd);
p.addOptional('zdims', 1 : 4);
p.addOptional('vsn', 'Clip');
p.addOptional('fnc', 'left');
p.addOptional('mbuf', 0);
p.addOptional('abuf', 0);
p.addOptional('scl', 1);
p.addOptional('href', []);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end

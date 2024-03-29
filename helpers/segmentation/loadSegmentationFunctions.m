function [bpredict , bcnv , zpredict , zcnv, cpredict , mline , mscore , tscore , escore , sopt , zmaster , msample , mcnv , tsample , tcnv] = loadSegmentationFunctions(varargin)
%% loadSegmentationFunctions: load function handles
%
% Usage:
%   [bpredict , bcnv , zpredict , zcnv, cpredict , mline , ...
%       mscore , tscore , escore , sopt , mmaster , msample , mcnv , ...
%       tsample , tcnv] = loadSegmentationFunctions(varargin)
%
% Input:
%   varargin: various inputs [see below]
%       inputs
%
% Output:
%   bpredict:
%   bcnv:
%   zpredict:
%   zcnv:
%   cpredict:
%   mline:
%   mscore:
%   tscore:
%   escore:
%   sopt:
%   mmsaster:
%   msample:
%   mcnv:
%   tsample:
%   tcnv:

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

%%
mscrs = pm.PCAScores;
mvecs = pm.EigVecs;
mmns  = pm.MeanVals;
tscrs = pt.PCAScores;
tvecs = pt.EigVecs;
tmns  = pt.MeanVals;
zsegs = size(pdx.InputData,2);
zvecs = pz.EigVecs;
zmns  = pz.MeanVals;

%
bpredict = @(i,z,r) predictBvectorFromImage(i,Nb,z,r);
zpredict = @(i,r) predictZvectorFromImage(i, Nz, pz, r);
cpredict = @(i,zs) displacementWindowPredictor(i, 'Nz', Nz, 'pz', pz, 'Nd', Nd, ...
    'pdp', pdp, 'pdx', pdx, 'pdy', pdy, 'pdw', pdw, 'z', zs, 'npxy', npxy, ...
    'npw', npw, 'toFix', toFix, 'seg_lengths', seg_lengths, ...
    'myShps', myShps, 'zoomLvl', zoomLvl, 'par', par, 'vis', 0);
switch mmth
    case 'nate'
        rho   = mparams(1); %#ok<USENS>
        edg   = mparams(2);
        res   = mparams(3);
        mline = @(c) nateMidline(c, seg_lengths, rho, edg, res, mpts);
    case 'pca'
        if ~iscell(mparams)
            fprintf(2, 'PCA midline method requires 2-4 cell inputs\n');
            return;
        end
        pcv   = mparams{1};
        pmv   = mparams{2};
        ncv   = mparams{3};
        nmv   = mparams{4};
        mline = @(c) pcaMidline(c, pcv, pmv, seg_lengths, mpts, ncv, nmv);
end
bcnv    = @(i,z) bpredict(i,z,1);
zcnv    = @(x) zVectorProjection(x, zsegs, zvecs, zmns, 3);
msample = @(i,m) sampleMidline(i, m, 0, psz, 'full');
mcnv    = @(m) pcaProject(m, mvecs, mmns);
mgrade  = computeKSdensity(mscrs, bwid);
mscore  = @(i,m) mgrade(mcnv(msample(i,m)));
tsample = @(i,c) sampleCotyledon(i, c, ...
    seg_lengths, tscl, tlen, nwid, tres, twid);
tcnv    = @(t) pcaProject(t,  tvecs, tmns);
tgrade  = computeKSdensity(tscrs, bwid);
tscore  = @(i,c) tgrade(tcnv(tsample(i,c)));
escore  = @(i,c) mscore(i,mline(c)) + tscore(i,c);
zmaster = @(i)@(z) ...
    escore(i,cpredict(i,bpredict(i,zcnv(z),1)));

% Optimize with nopts iterations
if cepox
    sopt = @(i,z,c) segmentationOptimizer(i, 'zinit', z, 'cinit', c, ...
        'cepox', cepox, 'bpredict', bpredict, 'zpredict', zpredict, ...
        'cpredict', cpredict, 'zmaster', zmaster, 'mline', mline, ...
        'escore', escore, 'bcnv', bcnv, 'zcnv', zcnv);
else
    sopt = [];
end
end

function args = parseInputs(varargin)
%%
p = inputParser;

% Required
p.addRequired('pz');
p.addRequired('pdp');
p.addRequired('pdx');
p.addRequired('pdy');
p.addRequired('pdw');
p.addRequired('pm');
p.addRequired('pt');
p.addRequired('Nz');
p.addRequired('Nd');
p.addRequired('Nb');

% Optional
p.addOptional('seg_lengths', [53 , 52 , 53 , 51]);
p.addOptional('ymin', 10);
p.addOptional('bwid', 0.5);
p.addOptional('psz', 20); % Usually 20
p.addOptional('npxy', []);
p.addOptional('npw', []);
p.addOptional('toFix', 0);
p.addOptional('cepox', 100);
p.addOptional('tolfun', 1e-4);
p.addOptional('tolx', 1e-4);
p.addOptional('z2c', 0);
p.addOptional('myShps', [2 , 3 , 4]);
p.addOptional('zoomLvl', [0.5 , 1.5]);
p.addOptional('mpts', 50);
p.addOptional('mmth', 'nate');
p.addOptional('mparams', [5 , 3 , 0.1]);
p.addOptional('tscl', 5);
p.addOptional('tlen', 50);
p.addOptional('nwid', 20);
p.addOptional('tres', [30 , 30]);
p.addOptional('twid', 3);

% Misc
p.addOptional('par', 0);
p.addOptional('vis', 0);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end

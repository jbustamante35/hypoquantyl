function [bpredict , bcnv , zpredict , zcnv, cpredict , mline , mscore , sopt , mmaster , msample] = loadSegmentationFunctions(varargin)
%% loadSegmentationFunctions: load function handles
%
% Usage:
%   [bpredict , bcnv , zpredict , zcnv, cpredict , mline , mscore , ...
%       sopt , mmaster , msample] = loadSegmentationFunctions(varargin)
%
% Input:
%
% Output:
%   bpredict:
%   bcnv:
%   zpredict:
%   zcnv:
%   cpredict:
%   mline:
%   mscore:
%   sopt:
%   mmsaster:
%   msample:

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

%%
pscrs = pm.PCAScores;
pvecs = pm.EigVecs;
pmns  = pm.MeanVals;
zsegs = size(pdx.InputData,2); % If 209 [correct]
zvecs = pz.EigVecs;
zmns  = pz.MeanVals;

%
bpredict = @(i,z,r) predictBvectorFromImage(i,Nb,z,r);
zpredict = @(i,r) predictZvectorFromImage(i, Nz, pz, r);
cpredict = @(i,zs) displacementWindowPredictor(i, 'Nz', Nz, 'pz', pz, 'Nd', Nd, ...
    'pdp', pdp, 'pdx', pdx, 'pdy', pdy, 'pdw', pdw, 'z', zs, 'npxy', npxy, ...
    'npw', npw, 'toFix', toFix, 'seg_lengths', seg_lengths, ...
    'par', par, 'vis', vis);
mline    = @(c) nateMidline(c);
msample  = @(i,m) sampleMidline(i, m, 0, psz, 'full');
bcnv     = @(i,z) bpredict(i,z,1);
zcnv     = @(x) zVectorProjection(x, zsegs, zvecs, zmns, 3);
mcnv     = @(m) pcaProject(m(:)', pvecs, pmns, 'sim2scr');
mgrade   = computeKSdensity(pscrs, bwid);
mscore   = @(i,m) mgrade(mcnv(msample(i,m)));
mmaster  = @(i)@(z) ...
    mgrade(mcnv(msample(i,mline(cpredict(i,bpredict(i,zcnv(z),1))))));
%     mgrade(mcnv(msample(i,mline(cpredict(i,bpredict(i,zpredict(i,0),1))))));

% Optimize with nopts iterations
if nopts
    sopt = @(i,z,b) segmentationOptimizer(i, 'zinit', z, 'binit', b, 'Nz', Nz, ...
        'pz', pz, 'Nd', Nd, 'pdp', pdp, 'pdx', pdx, 'pdy', pdy, 'pdw', pdw, ...
        'pm', pm, 'Nb', Nb, 'toFix', toFix, 'seg_lengths', seg_lengths, ...
        'bwid', bwid, 'nopts', nopts, 'tolfun', tolfun, 'tolx', tolx, ...
        'par', par, 'vis', vis, 'z2c', z2c);
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
p.addOptional('nopts', 100);
p.addOptional('tolfun', 1e-4);
p.addOptional('tolx', 1e-4);
p.addOptional('z2c', 0);

% Misc
p.addOptional('par', 0);
p.addOptional('vis', 0);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end

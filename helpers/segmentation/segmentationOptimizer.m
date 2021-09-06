function [zopt , fval , eflg , opts] = segmentationOptimizer(img, varargin)
%% segmentationOptimizer: optimization
%
%
% Usage:
%   [zopt , fval , eflg] = segmentationOptimizer(img, varargin)
%
% Input:
%   img:
%   ncycs:
%   ctru:
%   varargin: various input options (detailed below)
%       - Nz:
%       - pz:
%       - Nd:
%       - pdp:
%       - pdx:
%       - pdy:
%       - pdw:
%       - par:
%       - nopts:
%
% Output:
%   zopt: PC score for optimally-predicted Z-Vector
%   fval: value of the objective function
%   eflg: exit flag describing exit condition
%   opts: various data from optimization
%

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

%%
%
nsegs = size(ctru,1);
scrs  = pz.PCAScores;
evecs = pz.EigVecs;
mns   = pz.MeanVals;
cmns  = mean(scrs);
cvar  = cov(scrs);

%
zgrade    = @(x) -log(mvnpdf(x, cmns, cvar));
zcnv      = @(x) zVectorProjection(x, nsegs, evecs, mns, 3);
zpredict  = @(i,r) predictZvectorFromImage(i, Nz, pz, r);
cpredict  = @(i,zs) displacementWindowPredictor(i, 'Nz', Nz, 'pz', pz, 'Nd', Nd, ...
    'pdp', pdp, 'pdx', pdx, 'pdy', pdy, 'pdw', pdw, 'z', zs, ...
    'par', par, 'vis', vis);
zmaster   = @(i)@(zs) zgrade(zcnv(cpredict(i,zcnv(zs))));

%%
zpre  = zpredict(img,0);
zscr  = zpredict(img,1);
cinit = cpredict(img, zpre);

showBest = @(zs,aa,bb) showSegmentationOptimizer(img, ctru, cinit, zcnv(zs), ...
    cpredict, aa, bb);
options  = optimset('Display', 'iter', 'MaxIter', nopts, 'PlotFcns', showBest);

% Run the optimizer!
[zopt , fval , eflg , opts] = fminsearch(zmaster(img), zscr, options);

end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
% Required: ncycs
% Model: Nz, pz, Nd, pdp, pdx, pdy, pdw, fmth, z, model_manifest
% Misc: par, sav, vis
% Vis: fidx, cidx, ncrvs, splts, ctru, ztru, ptru, zoomLvl, toRemove

% Required
p = inputParser;
p.addOptional('ncycs', 1);

% Model Options
p.addOptional('Nz', 'znnout');
p.addOptional('pz', 'pz');
p.addOptional('Nd', 'dnnout');
p.addOptional('pdp', 'pcadp');
p.addOptional('pdx', 'pcadx');
p.addOptional('pdy', 'pcady');
p.addOptional('pdw', 'pcadw');
p.addOptional('fmth', 'local');
p.addOptional('z', []);
p.addOptional('model_manifest', {'dnnout' , 'pcadp' , ...
    'pcadx' , 'pcady' , 'pcadw' , 'znnout' , 'pz'});

% Miscellaneous Options
p.addOptional('nopts', 200);
p.addOptional('par', 0);
p.addOptional('sav', 0);
p.addOptional('vis', 0);

% Visualization Options
p.addParameter('fidx', 1);
p.addParameter('cidx', 1);
p.addParameter('ncrvs', 1);
p.addParameter('splts', []);
p.addParameter('ctru', [0 , 0]);
p.addParameter('ztru', [0 , 0]);
p.addParameter('ptru', [0 , 0]);
p.addParameter('zoomLvl', [0.5 , 1.5]);
p.addParameter('toRemove', 1);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;

end

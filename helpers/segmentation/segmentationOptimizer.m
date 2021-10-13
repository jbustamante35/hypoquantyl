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
bwid  = 0.5;
% msz   = 50;
psz   = 20;
scrs  = pp.PCAScores;
pvecs = pp.EigVecs;
pmns  = pp.MeanVals;
zsegs = size(ctru,1) - 1;
zvecs = pz.EigVecs;
zmns  = pz.MeanVals;
% scrs  = pz.PCAScores;
% cmns  = mean(scrs);
% cvar  = cov(scrs);

%
zcnv      = @(x) zVectorProjection(x, zsegs, zvecs, zmns, 3);                         % Z-Vector PC Score to Vector
zpredict  = @(i,r) predictZvectorFromImage(i, Nz, pz, r);                            % Z-Vector from Image
cpredict  = @(i,zs) displacementWindowPredictor(i, 'Nz', Nz, 'pz', pz, 'Nd', Nd, ... % D-Vector from Z-Vector on Image
    'pdp', pdp, 'pdx', pdx, 'pdy', pdy, 'pdw', pdw, 'z', zs, ...
    'par', par, 'vis', vis);
mline     = @(c) nateMidline(c);                                                     % Midline from D-Vectors
msample   = @(i,m) sampleMidline(i, m, 0, psz, 'full');                              % Midline Patch from Midline
% msample   = @(i)@(m) sampleMidline(i, m, 0, psz, 'full');                              % Midline Patch from Midline
mcnv      = @(m) pcaProject(m(:)', pvecs, pmns, 'sim2scr');                               % Midline Patch Vector to PC Score
mgrade    = computeKSdensity(scrs, bwid);                                            % Grade from Midline Patch PC Score Distribution
% mmaster   = @(i,z)@(ms) mgrade(mcnv(msample(i,mline(cpredict(i,z)))));           % Optimize Midline Patch PC Score
mmaster   = @(i)@(z) mgrade(mcnv(msample(i,mline(cpredict(i,zcnv(z))))));           % Optimize Midline Patch PC Score

% DEPRECATED [optimization by minimization of Z-Vector PC score probability]
% zgrade    = computeKSdensity(x, bwid);                       % Grade by Z-Vector PC distribution
% zgrade    = @(x) -log(mvnpdf(x, cmns, cvar));                % Assume gaussians
% zmaster   = @(i)@(zs) zgrade(zcnv(cpredict(i,zcnv(zs))));    % Optimize Z-Vector PC Score

%%
zpre  = zpredict(img,0);  % 0 for Z-Vector
zscr  = zpredict(img,1); % 1 for PC score
cinit = cpredict(img, zpre);
% minit = mline(cinit);
% pinit = msample(img, minit);
% mscr  = mcnv(pinit(:)');

% Run the optimizer!
showBest = @(zs,aa,bb) showSegmentationOptimizer(img, ctru, cinit, zcnv(zs), ...
    cpredict, aa, bb);
options  = optimset('Display', 'iter', 'MaxIter', nopts, 'PlotFcns', showBest);

% Run the optimizer!
% Minimization of M-Patch PC scores
[zopt , fval , eflg , opts] = fminsearch(mmaster(img), zscr, options);

% Minimization of Z-Vector PC scores
% [zopt , fval , eflg , opts] = fminsearch(zmaster(img), zscr, options); %

% Minimization of Z-Vector PC scores using patternsearch [allows parallel]
% Set upper and lower bounds set to sqrt or std from Z-Vector PC scores
% options  = optimset('Display', 'iter', 'MaxIter', nopts, ...
%     'UseParallel', true);
% [zopt , fval , eflg , opts] = patternsearch(zmaster(img), zscr, ...
%     [], [], [], [], [], [], [], options);

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

% Optimization Options
p.addOptional('bwid', 0.5);
p.addOptional('pp', 'pp');

% Miscellaneous Options
p.addOptional('nopts', 50);
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

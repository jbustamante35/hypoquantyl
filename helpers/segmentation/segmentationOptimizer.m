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
%       - Nb:
%       - pdp:
%       - pdx:
%       - pdy:
%       - pdw:
%       - pm:
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

%
[bpredict , bcnv , zpredict , zcnv, cpredict , ~ , ~ , ~ , ~ , ~ , mmaster] = ...
    loadSegmentationFunctions(pz , pdp , pdx , pdy , pdw , pm , Nz , Nd , Nb, ...
    'seg_lengths', seg_lengths, 'toFix', toFix, 'bwid', bwid, 'psz', psz, ...
    'nopts', nopts, 'par', par, 'vis', vis);

% Get initial guesses
zscr  = zpredict(img,1);       % 1 for PC score
zinit = zpredict(img,0);       % 0 for Vector
zinit = bpredict(img,zinit,1); % 1 for Z-Vector
cinit = cpredict(img,zinit);

%% Optimize Z-Vector from midline patch PC score probability
showBest = @(zs,aa,bb) showSegmentationOptimizer(img, ctru, cinit, ...
    bcnv(img,zcnv(zscr)), cpredict, aa, bb);
options  = optimset('MaxIter', nopts, 'TolFun', tolfun, 'TolX', tolx, ...
    'Display', 'iter', 'PlotFcns', showBest);

% Run the optimizer!
% Minimization of M-Patch PC scores
[zopt , fval , eflg , opts] = fminsearch(mmaster(img), zscr, options);

% Minimization of Z-Vector PC scores using patternsearch [allows parallel]
% Set upper and lower bounds set to sqrt or std from Z-Vector PC scores
% options  = optimset('Display', 'iter', 'MaxIter', nopts, ...
%     'UseParallel', true);
% [zopt , fval , eflg , opts] = patternsearch(zmaster(img), zscr, ...
%     [], [], [], [], [], [], [], options);

%% Generate contour from optimized Z-Vector
if z2c
    zinit = bpredict(img, zcnv(zopt), 1);
    zopt  = cpredict(img, zinit);
end
end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
% Required: ncycs
% Model: Nz, pz, Nd, pdp, pdx, pdy, pdw, fmth, z, model_manifest
% Misc: par, vis
% Vis: fidx, cidx, ncrvs, splts, ctru, ztru, ptru, zoomLvl, toRemove

% Required
p = inputParser;
p.addOptional('ncycs', 1);

% Model Options
p.addOptional('Nz', 'znnout');
p.addOptional('Nd', 'dnnout');
p.addOptional('Nb', 'bnnout');
p.addOptional('pz', 'pz');
p.addOptional('pm', 'pm');
p.addOptional('pdp', 'pdp');
p.addOptional('pdx', 'pdx');
p.addOptional('pdy', 'pdy');
p.addOptional('pdw', 'pdw');
p.addOptional('fmth', 'local');
p.addOptional('z', []);
p.addOptional('model_manifest', {'dnnout' , 'znnout' , 'bnnout' , ...
    'pz' , 'pm' , 'pdp' , 'pdx' , 'pdy' , 'pdw'});

% Optimization Options
p.addOptional('bwid', 0.5);
p.addOptional('psz', 20);
p.addOptional('toFix', 0);
p.addOptional('seg_lengths', [53 , 52 , 53 , 51]);

% Miscellaneous Options
p.addOptional('z2c', 0);
p.addOptional('nopts', 100);
p.addOptional('tolfun', 1e-4);
p.addOptional('tolx', 1e-4);
p.addOptional('par', 0);
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

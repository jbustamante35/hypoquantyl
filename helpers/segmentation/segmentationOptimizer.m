function    [zopt , copt , opts , fval , eflg] = segmentationOptimizer(img, varargin)
%% segmentationOptimizer: optimization
%
%
% Usage:
%   [zopt , copt , opts , fval , eflg] = segmentationOptimizer(img, varargin)
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
%   copt: contour generated from optimally-predicted Z-Vector
%   opts: various data from optimization
%   fval: value of the objective function
%   eflg: exit flag describing exit condition
%

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

%
if isempty(mmaster)
    [bpredict , bcnv , zpredict , zcnv, cpredict , mline , ...
        msample , mcnv , mgrade , sopt , mmaster] = loadSegmentationFunctions( ...
        pz , pdp , pdx , pdy , pdw , pm , Nz , Nd , Nb, ...
        'seg_lengths', seg_lengths, 'toFix', toFix, 'bwid', bwid, 'psz', psz, ...
        'nopts', nopts, 'par', par, 'vis', vis);
end

% Get initial or seeded Z-Vector
if isempty(zinit)
    zscr = zpredict(img,1); % 1 to obtain PC score
    zinit = zcnv(zscr);
else
    % Seeded Z-Vector in image space
    zscr = zcnv(zinit);
end

% Predict B-Vector and add back to initial Z-Vector
if isempty(binit); binit = bpredict(img, zinit, 0); end

zinit = [zinit(:,1:2) + binit , zinit(:,3:end)];
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
copt = cpredict(img, bpredict(img, zcnv(zopt), 1));
if z2c
    % Backup Z-Vector, Replace Z-Vector with contour, Replace contour
    zbak = zopt;
    zopt = copt;
    copt = zbak;
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
p.addOptional('Nz', []);
p.addOptional('Nd', []);
p.addOptional('Nb', []);
p.addOptional('pz', []);
p.addOptional('pm', []);
p.addOptional('pdp', []);
p.addOptional('pdx', []);
p.addOptional('pdy', []);
p.addOptional('pdw', []);
p.addOptional('fmth', 'local');
p.addOptional('z', []);
p.addOptional('model_manifest', {'dnnout' , 'znnout' , 'bnnout' , ...
    'pz' , 'pm' , 'pdp' , 'pdx' , 'pdy' , 'pdw'});

% Optimzation function handles
p.addOptional('zcnv', []);
p.addOptional('zpredict', []);
p.addOptional('bpredict', []);
p.addOptional('cpredict', []);
p.addOptional('mline', []);
p.addOptional('msample', []);
p.addOptional('mcnv', []);
p.addOptional('mgrade', []);
p.addOptional('mmaster', []);

% Optimization Options
p.addOptional('bwid', 0.5);
p.addOptional('psz', 20);
p.addOptional('toFix', 0);
p.addOptional('seg_lengths', [53 , 52 , 53 , 51]);

% Miscellaneous Options
p.addOptional('zinit', []);
p.addOptional('binit', []);
p.addOptional('nopts', 100);
p.addOptional('tolfun', 1e-4);
p.addOptional('tolx', 1e-4);
p.addOptional('z2c', 0);
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

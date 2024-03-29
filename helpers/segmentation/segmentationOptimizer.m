function    [zopt , copt , mopt , bopt , opts , fval , eflg] = segmentationOptimizer(img, varargin)
%% segmentationOptimizer: optimization
%
%
% Usage:
%   [zopt , copt , mopt , bopt , opts , fval , eflg] = ...
%       segmentationOptimizer(img, varargin)
%
% Input:
%   img:
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
%       - cepox:
%
% Output:
%   zopt: PC score for optimally-predicted Z-Vector
%   copt: contour generated from optimally-predicted Z-Vector
%   mopt: midline generated from optimally-predicted contour
%   opts: various data from optimization
%   fval: value of the objective function
%   eflg: exit flag describing exit condition

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

%% Optimize Z-Vector from midline patch PC score probability
zscr = zcnv(zinit);
switch vis
    case 0
        % No Visualization
        showBest = [];
    case 1
        % Quick version [no contour prediction]
        showBest = @(zs,aa,bb) showSegmentationOptimizer(img, ctru, cinit, ...
            bcnv(img,zcnv(zscr)), 1, aa, bb);
    case 2
        % Full version [predicts contour]
        showBest = @(zs,aa,bb) showSegmentationOptimizer(img, ctru, cinit, ...
            bcnv(img,zcnv(zscr)), cpredict, aa, bb);
end

options  = optimset('MaxIter', cepox, 'TolFun', tolf, 'TolX', tolx, ...
    'Display', 'iter', 'PlotFcns', showBest);

% Run the optimizer!
% Minimization of M-Patch PC scores
[zopt , fval , eflg , opts] = fminsearch(zmaster(img), zscr, options);

% Minimization of Z-Vector PC scores using patternsearch [allows parallel]
% Set upper and lower bounds set to sqrt or std from Z-Vector PC scores
% options  = optimset('Display', 'iter', 'MaxIter', cepox, ...
%     'UseParallel', true);
% [zopt , fval , eflg , opts] = patternsearch(zmaster(img), zscr, ...
%     [], [], [], [], [], [], [], options);

%% Generate contour from optimized Z-Vector
hopt = predictFromImage(img, bpredict, zpredict, cpredict, ...
    mline, escore, [], zcnv(zopt), 1, 1);
if z2struct
    % Backup Z-Vector, Replace Z-Vector with contour, Replace contour
    zopt = hopt;
    copt = struct('opts', opts, 'fval', fval, 'eflg', eflg);
else
    zopt = hopt.z;
    copt = hopt.c;
    mopt = hopt.m;
    bopt = hopt.b;
end
end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
p = inputParser;

% Optimzation function handles
p.addOptional('zcnv', []);
p.addOptional('bcnv', []);
p.addOptional('zpredict', []);
p.addOptional('bpredict', []);
p.addOptional('cpredict', []);
p.addOptional('escore', []);
p.addOptional('zmaster', []);
p.addOptional('mline', []);

% Miscellaneous Options
p.addOptional('zinit', []);
p.addOptional('cinit', []);
p.addOptional('cepox', 100);
p.addOptional('tolf', 1e-4);
p.addOptional('tolx', 1e-4);
p.addOptional('z2struct', 1);
p.addOptional('par', 0);
p.addOptional('vis', 0);

% Visualization Options
p.addParameter('fidx', 1);
p.addParameter('cidx', 1);
p.addParameter('ncrvs', 1);
p.addParameter('ctru', [0 , 0]);
p.addParameter('ztru', [0 , 0]);
p.addParameter('ptru', [0 , 0]);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end

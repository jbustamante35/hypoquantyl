function [scls , doms , domSizes , domShapes] = setupParams(varargin)
%% setupParams: get scales, domains, and domain sizes
%
%
% Usage:
%   [scls , doms , domSizes , domShapes] =  ...
%       setupParams(toRemove, zoomLvl, ds, sq, vl, hl, d, s, v, h)
%
% Input:
%   toRemove: index to remove unneeded domains and domain sizes
%   zoomLvl: zoom levels for each domain
%   ds: scale sizes for disk patch
%   sq: scale sizes for square patch
%   vl: scale sizes for vertical line
%   hl: scale sizes for horizontal line
%   d: domain size for a disk
%   s: domain size for a square
%   v: domain size for a vertical line
%   h: domain size for a horizontal line
%
% Output:
%   scls: sizes to scale patches up or down
%   doms: domain coordinates of various shapes
%   domSizes: sizes for the generated domains
%   domShapes: shapes of domains (for printing)
%

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

%% Set Scales
scls           = {diskScale , squareScale , vertScale , horzScale};
scls(toRemove) = [];

% Append additional scaling if given
scls = cellfun(@(scl) [scl ; cell2mat(arrayfun(@(zl) scl * zl, ...
    zoomLvl, 'UniformOutput', 0)')], scls, 'UniformOutput', 0);

%% Generate domains
[doms , domSizes , domShapes] = generateDomains( ...
    diskDomain, squareDomain, vertDomain, horzDomain, toRemove);

end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
% Need descriptions for all these parameters
% pcaX, pcaY, dim2chg, mns, eigs, scrs, pc2chg, upFn, dwnFn, stp, f

p = inputParser;
p.addParameter('toRemove', []);
p.addParameter('zoomLvl', []);
p.addParameter('diskScale', [30 , 30]);
p.addParameter('squareScale', [30 , 30]);
p.addParameter('vertScale', [50 , 1]);
p.addParameter('horzScale', [1 , 50]);
p.addParameter('diskDomain', [30 , 30]);
p.addParameter('squareDomain', [30 , 30]);
p.addParameter('vertDomain', [3 , 100]);
p.addParameter('horzDomain', [100 , 3]);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end
function [scls, dom, domSize] = setupParams(toRemove, ds, sq, vl, hl, d, s, v, h)
%% setupParams: get scales, domains, and domain sizes
%
%
% Usage:
%   [scls, dom, domSize] = setupParams(toRemove, ds, sq, vl, hl, d, s, v, h)
%
% Input:
%   toRemove: index to remove unneeded domains and domain sizes
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
%   dom: domain coordinates of various shapes
%   domSize: sizes for the generated domains
%

%% Select indices to remove
if nargin == 0
    toRemove = [];
end

%% Set Scales
% Default values
if nargin <= 1
    ds = [1  ,  1]; % Disk
    sq = [30 , 30]; % Square
    vl = [50 , 1] ; % Vertical Line
    hl = [1  , 50]; % Horizontal Line
end

scls           = {ds ; sq ; vl ; hl};
scls(toRemove) = [];

%% Generate domains
% Default values
if nargin < 5
    d = [1   , 1];
    s = [30  , 30];
    v = [3   , 100];
    h = [100 , 3];
end

[dom , domSize] = generateDomains(d, s, v, h, toRemove);

end


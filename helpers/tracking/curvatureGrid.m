function [kint , ksdl , kraw , kidv] = curvatureGrid(k, ftrp, ktrp, ksmth)
%% curvatureGrid: make interpolated grid from curvature values
%
% Usage:
%   [kint , ksdl , kraw , kidv] = curvatureGrid(k, ftrp, ktrp, ksmth)
%
% Input:
%   k: curvautre cell array
%   ftrp: interpolation size for frames (x-axis) [default size(k,1)]
%   ktrp: interpolation size for curvautres (y-axis) [default size(k,2)]
%   ksmth: radius of disk for smoothing grid
%
% Output:
%   kint: averaged gridded interpolant for curvatures
%   ksdl: gridded interpolant for each seedling
%   kraw: corrected averaged non-interpolated curvature grid
%   kidv: corrected non-interpolated curvature for each seedling
%

nk = size(k,2);
xx = cellfun(@(x) linspace(0, max(x), numel(x)), k, 'UniformOutput', 0);
yy = cellfun(@(x) linspace(0, max(x), ktrp), k, 'UniformOutput', 0);
qq = cellfun(@(x,y,z) interp1(x,y,z), xx, k, yy, 'UniformOutput', 0);

kidv = arrayfun(@(x) rot90(cat(1, qq{:,x})), 1 : nk, 'UniformOutput', 0);
ksdl = cellfun(@(x) interpolateGrid(x, 'xtrp', ftrp, 'ytrp', ktrp, ...
    'fsmth', ksmth), kidv, 'UniformOutput', 0);

ea   = cat(3, kidv{:});
eb   = cat(3, ksdl{:});
kraw = mean(ea,3);
kint = mean(eb,3);
end

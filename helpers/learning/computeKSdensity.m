function F = computeKSdensity(scrs, bwid)
%% computeKSdensity:
%
%
% Usage:
%   F = computeKSdensity(scrs, bwid)
%
% Input:
%   scrs:
%   bwid:
%
% Output:
%   F:
%

%% Defaults
if nargin < 2; bwid = 0.5; end

% Density of Z-Score normalized PC scores
zs = std(scrs,1,1);
z  = scrs .* (zs .^ -1);
F  = @(x) -log(mvksdensity(z, x .* (zs .^ -1), 'bandwidth', bwid));
end

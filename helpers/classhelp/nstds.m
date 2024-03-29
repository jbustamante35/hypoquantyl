function n = nstds(v, u, s)
%% nstds: compute the total standard deviations away from the mean
%
% Usage:
%   n = nstds(v, u, s)
%
% Input:
%   v: value
%   u: mean or median of dataset (or simply the dataset)
%   s: standard deviation of dataset
%
% Output:
%   n: total standard deviations from the mean/median

if nargin < 3; s = []; end
if isempty(s); d = u; u = mean(d); s = std(d); end
n = v / pdist([u + s ; u]);
end
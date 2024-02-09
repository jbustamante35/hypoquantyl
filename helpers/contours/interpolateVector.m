function Y = interpolateVector(X, ncrds)
%% interpolateVector: interpolation of single vector
%
% Usage:
%   Y = interpolateVector(X, ncrds)
%
% Input:
%   X:
%   ncrds:
%
% Output:
%   Y:

if nargin < 2; ncrds = numel(X); end

[rows , cols] = size(X);
Xa            = 1 : numel(X);
Xq            = linspace(min(Xa), max(Xa), ncrds);

if rows > cols; Xq = Xq'; end
Y  = interp1(Xa, X, Xq);
end
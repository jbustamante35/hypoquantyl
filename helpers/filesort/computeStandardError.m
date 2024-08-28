function stderrs = computeStandardError(X,dim)
%% computeStandardError: compute standard error of the mean
%
% Usage:
%   stderrs = computeStandardError(X,dim)
%
% Input:
%   X: 2D or 3D data
%   dim: dimension to compute on [default 3]
%
% Output:
%   stderrs: standard errors of the mean
if nargin < 2; dim = 3; end
stderrs = std(X,0,dim) ./ sqrt(size(X,dim));
end
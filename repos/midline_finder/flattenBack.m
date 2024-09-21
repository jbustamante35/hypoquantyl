function [X,szX] = flattenBack(X,n)
    if nargin < 2;n = 1;end
    szX = size(X);
    X = reshape(X,[szX(1:n) prod(szX((n+1):(end)))]);
end
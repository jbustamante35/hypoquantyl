function [rIdxs , x] = pullRandom(X, n)
%% pullRandom: pull random number(s) from distribution
% Description
%
% Usage:
%    rIdxs = pullRandom(X, n)
%
% Input:
%    X: distribution of numbers
%    n: number of random pulls (optional) [defaults to 1]
%
% Output:
%    rIdxs: random index or indices from distribution
%    x: random data pulled from distribution
%
% Author Julian Bustamante <jbustamante@wisc.edu>
%

%%
if nargin < 2
    n = 1;
end

%%
% rIdxs = randi([1 , length(X)], 1);
% x     = X(rIdxs);
rIdxs = sort(Shuffle(length(X), 'index', n));
x     = X(rIdxs);

end



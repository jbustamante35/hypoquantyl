function [ridx , rx] = pullRandom(X, n, getrx, toSort)
%% pullRandom: pull random number(s) from distribution
% Description
%
% Usage:
%    [ridx , rx] = pullRandom(X, n, getrx)
%
% Input:
%    X: distribution of numbers
%    n: number of random pulls (optional) [defaults to 1]
%    getrx: return the actual value instead of the index
%
% Output:
%    ridx: random index or indices from distribution
%    rx: random data pulled from distribution
%
% Author Julian Bustamante <jbustamante@wisc.edu>
%

%% Default to take 1 sample
if nargin < 1; X      = 1 : 100; end
if nargin < 2; n      = 1;       end
if nargin < 3; getrx  = 0;       end
if nargin < 4; toSort = 1;       end

%% Return random index and object
% Check if Shuffle function is available
if ~isempty(which('Shuffle')) && n <= numel(X)
    ridx = Shuffle(length(X), 'index', n);
else
    % No Shuffle function found
    ridx = randi(length(X), [1 , n]);
end

if toSort; ridx = sort(ridx); end

rx = X(ridx);
if getrx; tmp = ridx; ridx = X(ridx); rx = tmp; end
end

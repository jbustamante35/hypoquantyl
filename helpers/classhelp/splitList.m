function Y = splitList(L)
%% splitList: split list into cells of arrays of matching strings
%
% Usage:
%   Y = splitList(X)
%
% Input:
%   X: list to split
%
% Output:
%   Y: split list
%
[L , Li] = sort(L);
[~ , la] = unique(L, 'stable');
lb       = [diff(la) - 1 ; (numel(L) - la(end))];
Y        = arrayfun(@(x) Li(la(x) : la(x) + lb(x))', ...
    1 : numel(la), 'UniformOutput', 0)';
end

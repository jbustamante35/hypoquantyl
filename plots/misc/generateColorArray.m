function clrmap = generateColorArray(itrs, toSkip)
%% generateColorArray:
%
%
% Usage:
%   clrmap = generateColorArray(itrs, toSkip)
%
% Input:
%   itrs: total colors to generate
%   toSkip: color to skip [default []]
%
% Output:
%   clrmap: cell array of colors with skipped color excluded
%
if nargin < 1; itrs   = 7; end
if nargin < 2; toSkip = []; end

clrs = {'k' , 'b' , 'r' , 'g' , 'c' , 'm'};

if ~isempty(toSkip)
    if iscell(toSkip)
        skp = cellfun(@(x) strncmpi(x,clrs,1), toSkip, 'UniformOutput', 0);
        skp = ~logical(sum(cat(1, skp{:})));
    else
        skp = ~strncmpi(toSkip, clrs, 1);
    end
    clrs = clrs(skp);
end

nreps  = ceil(itrs / numel(clrs));
clrmap = repmat(clrs , 1 , nreps);
clrmap = clrmap(1 : itrs);
end

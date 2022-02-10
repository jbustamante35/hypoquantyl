function clrmap = generateColorArray(itrs)
%% generateColorArray:
%
%
% Usage:
%   clrmap = generateColorArray(itrs)
%
% Input:
%   itrs:
%
% Output:
%   clrmap
%
if nargin < 1; itrs = 7; end

clrs   = {'k' , 'b' , 'r' , 'g' , 'c' , 'm'};
nreps  = ceil(itrs / numel(clrs));
clrmap = repmat(clrs , 1 , nreps);
clrmap = clrmap(1 : itrs);
end

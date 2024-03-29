function testparfor(n)
%% testparfor: simple test of parfor functionality
% Usage:
%   testparfor(n)
%
% Input:
%   n: number to count to

if nargin < 1; n = 100; end

t = tic;
fprintf('\n|');
parfor ni = 1 : n; fprintf('%d|', ni); end
fprintf('\n[%.03f sec]\n', mytoc(t));
end
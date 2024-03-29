function keepParpool(n, p, t)
%% keepParpool: maintain parpool if away for a while
%
% Usage:
%   keepParpool(n, p, t)
%
% Input:
%   n: loop iterations (default 100)
%   p: pause time in seconds (default 100)
%   t: parfor test loop iterations (default 100)

if nargin < 1; n = 100; end
if nargin < 2; p = 100; end
if nargin < 3; t = 100; end

[~ , sprA , sprB] = jprintf(' ', 0, 0, 80);
fprintf('\n\n%s\nLooping %d times and pausing for %d seconds\n%s\n', ...
    sprA, n, p, sprB);
for ni = 1 : n
    fprintf('Loop %d of %d', ni, n);
    testparfor(t);
    for pi = 1 : p
        pause(1);
        fprintf('.');
    end
    fprintf(' | DONE!\n%s\n', sprB);
end
fprintf('Finished %d loops of %d seconds\n%s\n', n, p, sprA);
end
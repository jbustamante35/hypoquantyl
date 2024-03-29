function t = mytoc(t, mth, rnd)
%% mytoc: shortcut to convert to sec/min/hrs from toc(t)
% Usage:
%   t = mytoc(t, mth, rnd)
%
% Input:
%   t: time elapsed from tic(t)
%   mth: time conversion [sec|min|hrs|days] (default 'sec')
%   rnd: number of digits to round to (default 2)
%
% Output:
%   t: time elapsed in converted time
if nargin < 2; mth = 'sec'; end
if nargin < 3; rnd = 2;     end

t = round(toc(t), rnd);
switch mth
    case 'sec'
    case 'min'
        t = t / 60;
    case 'hrs'
        t = (t / 60) / 60;
    case 'days'
        t = ((t / 60) / 60) / 24;
    otherwise
        t = [];
        fprintf(2, 'Input mth must be [sec|min|hrs|days] (%s)\n', mth);
end
end
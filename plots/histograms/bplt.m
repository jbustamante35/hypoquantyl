function bfig = bplt(x, clr, smth, wid)
%% bplt: plot distribution as bar plot
%
% Usage:
%   fig = bplt(x, clr, smth, wid)
%
% Input:
%   x: histogram data
%   clr: color of bars
%   smth: smoothing value
%   wid: width of bars
%
% Output:
%   bfig: figure handle to Bar
%
if nargin < 2; clr  = 'k'; end
if nargin < 3; smth = 1;   end
if nargin < 4; wid  = 3;   end

if endsWith(clr, '1')
    fclr = 'none';
    eclr = clr(1);
else
    fclr = clr(1);
    eclr = 'none';
end

bfig = bar(smooth(x,smth)', ...
    'EdgeColor', eclr, 'FaceColor', fclr, 'BarWidth', wid);
end
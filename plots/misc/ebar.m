function eb = ebar(y, err, lcolor, lstyle, lwid, mcolor, mstyle, mwid)
%% ebar: customizabe errorbar plotter
%
% Usage:
%   eb = ebar(y, err, lcolor, lstyle, lwid, mcolor, mstyle, mwid)
%
% Input:
%   y: data
%   err: errors
%   lcolor: line color [default 'k']
%   lstyle: line style [default '-']
%   lwid: line width [default 1]
%   mcolor: marker color [default 'k']
%   mstyle: marker type [default 'none']
%   mwid: marker size [default 5]
%
% Output:
%   eb: error bar function handle

if nargin < 3; lcolor = 'k';    end
if nargin < 4; lstyle = '-';    end
if nargin < 5; lwid   = 1;      end
if nargin < 6; mcolor = 'k';    end
if nargin < 7; mstyle = 'none'; end
if nargin < 8; mwid   = 5;      end

eb = errorbar(y, err, 'vertical', ...
    'Color', lcolor, 'LineStyle', lstyle, 'LineWidth', lwid, ...
    'MarkerFaceColor', mcolor, 'Marker', mstyle, 'MarkerSize', mwid);
end
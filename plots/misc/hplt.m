function hfig = hplt(x, nbins, clr, mth)
%% hplt: simple histogram function
%
% Usage:
%   hfig = hplt(x, nbins, clr, mth)
%
% Input:
%   nbins: number of bins [default 20]
%   clr: color of bars [default 'k']
%   mth: normalization method [default 'pdf']
%
% Output:
%   hfig: figure handle

if nargin < 2; nbins = 20;      end
if nargin < 3; clr   = 'k';     end
if nargin < 4; mth   = 'pdf'; end

hfig = histogram(x, 'NumBins', nbins, 'Normalization', mth, ...
    'EdgeColor', 'none', 'FaceColor', clr);
end
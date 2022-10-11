function h = makeHist(x, nbins, mth)
%% makeHist: generate histogram from data
%
% Usage:
%   h = makeHist(x, nbins, mth)
%
% Input:
%   x: data
%   nbins: number of bins to create [default 256]
%   mth: histogram normalization method [default 'probability']
%
% Output:
%   h: histogram vector
%

if nargin < 2; nbins = 256;   end
if nargin < 3; mth   = 'probability'; end
% if nargin < 3; mth   = 'pdf'; end

% h = histcounts(x, nbins, 'Normalization', mth);
h = histcounts(x, 1 : nbins + 1, 'Normalization', mth);
end
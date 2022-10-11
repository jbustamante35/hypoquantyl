function [ismth , hsmth , gmm] = histogramNormalize_gmm(img, npeaks, nbits, nbins, bwid, smth)
%% histogramNormalize_gmm
%
%
% Usage:
%   [ismth , hsmth , gmm] = histogramNormalize_gmm( ...
%       img, npeaks, nbits, nbins, bwid, smth)
%
% Input:
%
%
% Output:
%

%
if nargin < 2; nbits  = 8;    end
if nargin < 3; npeaks = 3;    end
if nargin < 4; nbins  = 256;  end
if nargin < 5; bwid   = 0.02; end
if nargin < 6; smth   = 1;    end

%%
img   = double(img) / (2 ^ nbits);
dbins = linspace(0, 1, nbins);
hsmth = ksdensity(img(:), dbins, 'BandWidth', bwid);
hsmth = hsmth / sum(hsmth);
hsmth = imfilter(hsmth, ones(1, smth) / smth);
ismth = hist2image(hsmth, 0 : nbins);

%%
gopts = statset('Display', 'iter');
gmm   = fitgmdist(double(ismth(:)) / 255, npeaks, 'Options', gopts, ...
    'Replicates', 1, 'RegularizationValue', 0.001);
end
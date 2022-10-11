function nimg = simpleHistCorrect(img, ithrsh, nbins)
%% simpleHistCorrect: histogram normalization on image with no reference
% Take bins from intensity histogram above threshold and stretch across 0-255
%
% Usage:
%   nimg = simpleHistCorrect(img, ithrsh, nbins)
%
% Input:
%   img: image to normalize
%   ithrsh: threshold for lowest probability in image histogram [default 0.01]
%   nbins: number of bins to stretch histogram to [default 256]
%
% Output:
%   nimg: normalized image
%

if nargin < 2; ithrsh = 0.01; end
if nargin < 3; nbins  = 256;  end

[h , hx] = imhist(img / (nbins - 1), nbins);
h        = h / sum(h);
bwid     = bwlarge(h > ithrsh / 100);
fidx     = find(bwid);

%
hcorr = @(value)(value - fidx(1)) / (fidx(end) - fidx(1));
nimg  = (nbins - 1) * hcorr(img);
end
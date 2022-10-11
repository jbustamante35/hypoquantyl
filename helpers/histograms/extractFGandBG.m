function [iF , iB , hF , hB] = extractFGandBG(img, nbins, mth)
%% extractFGandBG: extract image and histogram of foreground and background
%
% Usage:
%   [iF , iB , hF , hB] = extractFGandBG(img, inv, nbins, mth)
%
% Input:
%   img: image
%   inv: invert image so foreground is bright [default 1]
%   nbins: number of bins for histogram [default 256]
%   mth: normalization method [default 'probability']
%
% Output:
%   iF: image filtered for foreground pixels
%   iB: image filtered for background pixels
%   hF: histogram of foreground pixels
%   hB: histogram of background pixels

if nargin < 2; nbins = 256;           end
if nargin < 3; mth   = 'probability'; end

% if inv; img = imcomplement(img); end

[iF , iB] = deal(img);
fg        = imbinarize(img);
bg        = ~fg;
iF(fg)    = 0;
iB(bg)    = 0;
hF        = makeHist(img(iF > 0), nbins, mth);
hB        = makeHist(img(iB > 0), nbins, mth);

if nargout == 1
    tmp = iF;
    iF.fimg = tmp;
end
end
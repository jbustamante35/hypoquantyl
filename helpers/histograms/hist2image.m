function [img , org] = hist2image(hhist, hbins, isz, npix, nrng, shfl)
%% hist2image: convert histogram of pixel intensities to image
%
%
% Usage:
%   [img , org] = hist2image(hhist, hbins, isz, npix, nrng, shfl)
%
% Input:
%   hhist: histogram counts
%   hbins: histogram bin ranges
%   isz: size to reshape image (default [])
%   npix: number of pixels to normalize to (default prod(isz))
%   nrng: size of linspace to draw from bin range (default 1000)
%   shfl: randomly shuffle output just because (default 0)
%
% Output:
%   img: array with strings of pixel intensities corresponding to histogram bins
%   org: unshuffled or unshaped original output (if isz ~= [] || shfl == 1)
%

if nargin < 3; isz  = [];                end
if nargin < 4; npix = prod([101 , 101]); end
if nargin < 5; nrng = 1000;              end
if nargin < 6; shfl = 0;                 end

if all(hhist < 1)
    %% Convert probabilities to counts
    % Ensure all >0 probabilities are at least 1 (for rounding)
    if ~isempty(isz); npix = prod(isz); end
    %     hhist = hhist * npix;
    hhist = round(hhist * npix);

    if uint8(sum(hhist)) ~= uint8(npix)
        rnd        = hhist > 0 & hhist < 0.5;
        hhist(rnd) = 1;
        %     hhist      = round(hhist);
        hhist      = floor(hhist);
        rdst       = sum(hhist) - npix;
        ridx       = find(rnd);
        hidx       = pullRandom(ridx, abs(rdst), 1);
        if rdst > 0
            % Remove pixels from rnd index
            hhist(hidx) = 0;
        elseif rdst < 0
            % Add pixels from rnd index
            hhist(hidx) = 1;
        end
    end
end

%% Histogram to Image
% Randomly select n values within it's corresponding range of b bins
% (i.e.) 100 counts in range 0.1407 to 0.1422 -->
%        uniform random sampling of 100 numbers within range
% nbins = numel(hbins) - 1;
% brng  = @(b1,b2) linspace(hbins(b1), hbins(b2), nrng);
% img   = cell(nbins,1);
% for b = 1 : nbins
%     rng    = brng(b,b+1);
%     img{b} = pullRandom(rng, uint8(hhist(b)), 1);
% end

% Repeat value of each bin
nbins = numel(hbins) - 1;
img   = cell(nbins,1);
for b = 1 : nbins
    h      = hhist(b);
    img{b} = repmat(b, 1, h);
end

img = cat(2, img{:});
org = [];

if numel(img) ~= npix; img(end) = []; end

if shfl;          org = img; img = Shuffle(img);      end
if ~isempty(isz); org = img; img = reshape(img, isz); end
end

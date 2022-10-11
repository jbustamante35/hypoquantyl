function inrm = normalizeImageWithHistogram(img, href, mth, nbins)
%% normalizeImageWithHistogram: histogram normalization on image
%
%
% Usage:
%   inrm = normalizeImageWithHistogram(img, href, mth, nbins)
%
% Input:
%   img: image to normalize
%   href: probability threshold [simple] or histogram to normalize image to
%   mth: normalization method [ simple | polynomial | uniform ]
%   nbins: number of bins to normalize to [default 256]
%
% Output:
%   inrm: image normalized from histogram
%

if nargin < 2; href  = 0.01;     end
if nargin < 3; mth   = 'simple'; end
if nargin < 4; nbins = 256;      end

switch mth
    case 'simple'
        %% Force stretching of histogram to 0-255
        inrm = simpleHistCorrect(img, href, nbins);
    case ''
        %% Do Nothing
        inrm = img;
    otherwise
        %% Use reference histogram
        % Figure handles for converting to image and normalization
        cls   = class(img);
        wbins = 0 : nbins;
        h2i   = @(x)   hist2image(x, wbins);                    % Convert histogram to image
        fg    = @(x,r) imhistmatch(x, r, nbins, 'Method', mth); % Normalize to histogram

        % Convert histogram to image then normalize
        img  = uint8(img); % Force uint8
        iref = uint8(h2i(href));
        inrm = fg(img,iref);

        % Revert output to original class type
        inrm = eval(sprintf('%s(inrm)', cls));
end
end
function [smsk, sdata] = getStraightenedMask(crds, img, BNZ, SCL, BG)
%% getStraightenedMask: straighten image from midline
% This is a modified version of the sampleStraighten function that straightens
% an object in an image by extending normal vectors along each coordinate of a
% midline.
%
% Usage:
%   [smsk, sdata] = getStraightenedMask(crds, img, BNZ, SCL, BG)
%
% Input:
%   crds: x-/y-coordinates of curve to map
%   img: image to interpolate pixels from coordinates
%   BNZ: boolean to binarize the final mask [for bw objects]
%   SCL: scaler to extend normal to desired distance [in pixels]
%   BG:
%
% Output:
%   smsk: straightened image
%   sdata: extra data for visualization or debugging
%

try
    %% Default parameters
    if nargin < 3; BNZ = 1;                     end % Binarization on
    if nargin < 4; SCL = ceil(size(img,1) / 2); end % Envelope size half width of the image
    if nargin < 5; BG  = 0;                     end % No BG

    %% Create envelope structure
    % Set unit length vector to place outer boundary
    tng  = gradient(crds')';
    d2e  = sum((tng .* tng), 2).^(-0.5);
%     ulng = bsxfun(@times, tng, d2e) * SCL;
    tng  = bsxfun(@times, tng, d2e);
    nrm  = [-tng(:,2) , tng(:,1)];
    ulng = nrm * SCL;

    % Compute distances from midline points to edge of envelope
    %     bndsOut = [-ulng(:,2) , ulng(:,1)] + crds;
    %     bndsInn = [ulng(:,2) , -ulng(:,1)] + crds;
    bndsOut = ulng + crds;
    bndsInn = -ulng + crds;

    %% Map curves to image
    [envO, datO] = map2img(img, crds, bndsOut, SCL, BNZ, BG);
    [envI, datI] = map2img(img, crds, bndsInn, SCL, BNZ, BG);

    if BNZ
        %% For CarrotSweeper straightener
        smsk = handleFLIP([flipud(envO) ; envI],3);

        % Extract largest object from binarized image
        prp                            = regionprops(smsk, 'Area', 'PixelIdxList');
        [~ , maxIdx]                   = max(cell2mat(arrayfun(@(x) x.Area, ...
            prp, 'UniformOutput', 0)));
        smsk                           = zeros(size(smsk));
        smsk(prp(maxIdx).PixelIdxList) = 1;
    else
        %% For HypoQuantyl S-Patches
        smsk = [fliplr(envI') , envO'];
    end

    % Extra data for visualization or debugging
    sdata = struct('OuterData', datI, 'InnerData', datO);
catch
    fprintf(2, '\nError with straightening\n');
    [smsk , sdata] = deal([]);
end
end

function [env, edata] = map2img(img, crds, ebnds, dscl, bnz, bg)
%% map2img: interpolate pixel intensities from curve coordinates
% Create the envelope structure
[eCrds, eGrid] = generateFullEnvelope(crds, ebnds, dscl, 'cs');

% Map curves to image
sz = [size(eGrid,1), length(crds)];

if bg > 0
    mapimg = interp2(double(img), eCrds(:,1), eCrds(:,2), 'linear', bg);
else
    mapimg = ba_interp2(double(img), eCrds(:,1), eCrds(:,2));
end

% Binarize if using for CarrotSweeper
if bnz
    mapimg = imbinarize(mapimg, 'adaptive', 'Sensitivity', 1);
end

env = reshape(mapimg, sz);

% Extra data for visualization or debugging
edata = struct('eCrds', eCrds, 'eGrid', eGrid, ...
    'eBnds', ebnds, 'GridSize', size(eGrid));
end


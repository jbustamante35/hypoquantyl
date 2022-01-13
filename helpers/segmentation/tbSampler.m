function [ptch , imgSample , domSample] = tbSampler(img, aff, dom, domSize, vis, sidx, dshp)
%% tbSampler: sample image at domains from the affine transformation
% Sample an image from the coordinates of the inputted domains generated from
% the affine transformation. This returns the image patches corresponding to the
% coordinates of the transformation.
%
% Usage:
%   [ptch , imgSample , domSample] = tbSampler( ...
%       img, aff, dom, domSize, vis, sidx, dshp)
%
% Input:
%   img: image to sample on
%   aff: affine transformation vector
%   dom: domain shape to sample from
%   domSize: dimensions of the domain
%   vis: figure handle index for visualizing image patches [0 for no figure]
%   sidx: unique index value for saving filename [0 for no save]
%   dshp: shape of domains (for text output) [default '']
%
% Output:
%   ptch: image patches sampled from the domains of the transformations
%

%%
if nargin < 5; vis  = 0;  end
if nargin < 6; sidx = 0;  end
if nargin < 7; dshp = ''; end

%%
ptch   = zeros([size(aff,1) , domSize , size(aff,4)]);
msk    = img > graythresh(img / 255) * 255;
bk     = mean(img(msk(:)));
padVal = size(img,1);
bak    = img; %#ok<NASGU> % backup of image [for debug]
img    = padarray(img, [padVal , padVal], bk, 'both');

%% Sample image with affines for each segment
naffs = size(aff,1);
nscls = size(aff,4);
for e = 1 : naffs
    % Sample image with affines for each scale
    for s = 1 : nscls
        domSample = squeeze(aff(e,:,:,s)) * dom';
        imgSample = ...
            ba_interp2(img, domSample(1,:) + padVal, domSample(2,:) + padVal);
        imgSample = reshape(imgSample, domSize);

        if domSize(1) == domSize(2)
            % Rotate squares 90-degrees
            rots = 1;
        elseif domSize(1) > domSize(2)
            % Flip horizontal lines 180-degrees
            rots = 2;
        else
            % Don't flip vertical lines
            rots = 0;
        end

        imgSample     = rot90(imgSample,rots);
        ptch(e,:,:,s) = imgSample;

        z    = squeeze(aff(e,:,:,s));
        mid  = z(1:2,3)' + padVal;
        tng  = [(z(1:2,1)' + mid) ; mid];
        nrm  = [(z(1:2,2)' + mid) ; mid];
        dsmp = domSample(1:2,:)' + padVal;
        mpt  = flip(round(size(imgSample) / 2));
        if vis
            figclr(vis);
            subplot(121);
            myimagesc(imgSample);
            hold on;
            plt(mpt, 'g.', 20);
            ttl = sprintf('Domain Size [%d %d]', domSize);
            title(ttl, 'FontSize', 10);

            subplot(122);
            myimagesc(img);
            hold on;
            plt(dsmp, 'g.', 10);
            plt(tng, 'r-', 2);
            plt(nrm, 'b-', 2);
            plt(mid, 'y.', 20);
            ttl = sprintf('Image Padding [%d]', padVal);
            title(ttl, 'FontSize', 10);

            drawnow;

            if sidx
                sdir = sprintf('tbsampler_curve%03d', sidx);
                fnm = sprintf('%s_tbsampler_dims[%d-%d]_scale%02dof%02d_zvec%03dof%03d_%s', ...
                    tdate, domSize, s, nscls, e, naffs, dshp);
                saveFiguresJB(vis, {fnm}, sdir);
            end
        end
    end
end
end
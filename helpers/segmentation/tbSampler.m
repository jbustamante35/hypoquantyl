function [ptch , imgSample , domSample] = tbSampler(img, aff, dom, domSize, dsk, fidx, sidx, dshp)
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
%   dsk: disk size for smoothing binary mask
%   fidx: figure handle index for visualizing image patches [0 for no figure]
%   sidx: unique index value for saving filename [0 for no save]
%   dshp: shape of domains (for text output) [default '']
%
% Output:
%   ptch: image patches sampled from the domains of the transformations

%%
if nargin < 5; dsk  = 3;  end
if nargin < 6; fidx = 0;  end
if nargin < 7; sidx = 0;  end
if nargin < 8; dshp = ''; end

%%
ptch   = zeros([size(aff,1) , domSize , size(aff,4)]);
msk    = img > graythresh(img / 255) * 255;
msk    = processMask(msk, dsk);
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
        domSample = (squeeze(aff(e,:,:,s)) * dom') + [padVal ; padVal ; 0];
        imgSample = reshape(ba_interp2(img, ...
            domSample(1,:), domSample(2,:)), domSize);

        % Displace domSample back to non-padded location
        domSample = (domSample' - [padVal , padVal , 0])';

        if     domSize(1) == domSize(2); rots = 1; % Rotate squares 90-degrees
        elseif domSize(1) >  domSize(2); rots = 2; % Flip horz lines 180-degrees
        else;                            rots = 0; % Don't flip vert lines
        end

        imgSample     = rot90(imgSample, rots);
        ptch(e,:,:,s) = imgSample;

        % Visualize domain patch on image
        if fidx
            fnm = sprintf(['%s_tbsampler_dims[%d-%d]_' ...
                'scale%02dof%02d_zvec%03dof%03d_%s'], ...
                tdate, domSize, s, nscls, e, naffs, dshp);
            showDomain(fidx, fnm, sidx, imgSample, ...
                domSample(1:2,:)', aff(e,:,:,s), padVal, domSize);
        end
    end
end
end

function showDomain(fidx, fnm, sidx, img, dom, aff, padVal, dsz)
%% showDomain

z    = squeeze(aff);
mid  = z(1:2,3)' + padVal;
tng  = [(z(1:2,1)' + mid) ; mid];
nrm  = [(z(1:2,2)' + mid) ; mid];
dsmp = dom(1:2,:)';
mpt  = flip(round(size(img) / 2));

figclr(fidx);
subplot(121);
myimagesc(img);
hold on;
plt(mpt, 'g.', 20);
ttl = sprintf('Domain Size [%d %d]', dsz);
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
    saveFiguresJB(fidx, {fnm}, sdir);
end
end

function msk = processMask(msk, dsk)
%% processMask: processing of binary mask
if nargin < 2; dsk = 3; end

if dsk
    % Only process if dsk size input
    ds  = fspecial('disk', dsk);
    se  = strel('disk', dsk);
    msk = imfilter(msk, ds);
    msk = imdilate(msk, se);
    msk = ~imfill(~msk, 'holes');
end
end
function [ptch , imgSample , domSample] = tbSampler(img, aff, dom, domSize, vis)
%% tbSampler: sample image at domains from the affine transformation
% Sample an image from the coordinates of the inputted domains generated from
% the affine transformation. This returns the image patches corresponding to the
% coordinates of the transformation.
%
% Usage:
%   [ptch , imgSample , domSample] = tbSampler( ...
%       img, aff, dom, domSize, vis)
%
% Input:
%   img: image to sample on
%   aff: resulting coordinates of the affine transformation
%   dom: domain shape to sample from
%   domSize: size of the domain
%   vis: boolean to visualize patches as they are generated
%
% Output:
%   ptch: image patches sampled from the domains of the transformations
%

%%
ptch   = zeros([size(aff,1) , domSize , size(aff,4)]);
msk    = img > graythresh(img / 255) * 255;
bk     = mean(img(msk(:)));
padVal = size(img,1);
bak    = img; %#ok<NASGU> % backup of image [for debug]
img    = padarray(img, [padVal , padVal], bk, 'both');

%% Sample image with affines for each segment
for e = 1 : size(aff,1)
    % Sample image with affines for each scale
    for s = 1 : size(aff,4)
        domSample = squeeze(aff(e,:,:,s)) * dom';
        imgSample = ...
            ba_interp2(img, domSample(1,:) + padVal, domSample(2,:) + padVal);
        
        % I think square patches need to be rotated?
        imgSample = reshape(imgSample, domSize);
        
        if size(domSize,1) == size(domSize,2)
            % NOTE: This logic needs to change if using rectangles. But then
            % again, a rectangle is just a fattened line
            ptch(e,:,:,s) = rot90(imgSample);
        else
            % Don't rotate for vertical/horizontal lines
            ptch(e,:,:,s) = imgSample;
        end
        
        z    = squeeze(aff(e,:,:,s));
        mid  = z(1:2,3)' + padVal;
        dsmp = domSample(1:2,:)' + padVal;
        if vis
            figclr(1);
            myimagesc(imgSample);
            ttl = sprintf('Domain Size [%d %d]', domSize);
            title(ttl, 'FontSize', 10);
            
            figclr(2);
            myimagesc(img);
            hold on;
            plt(dsmp, 'g.', 10);
            plt(mid, 'r.', 20);
            ttl = sprintf('Image Padding [%d]', padVal);
            title(ttl, 'FontSize', 10);
            
            drawnow;
        end
    end
end

end
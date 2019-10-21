function ptch = tbSampler(img, aff, dom, domSize, vis)
%% tbSampler: sample an image at the domains from the affine transformation
% Sample an image from the coordinates of the inputted domains generated from
% the affine transformation. This returns the image patches corresponding to the
% coordinates of the transformation.
%
% Input:
%   img: image to sample on
%   aff: resulting coordinates of the affine transformation
%   dom: domain shape to sample from
%   domSize: size of the domain
%
% Output:
%   ptch: image patches sampled from the domains of the transformations
%

%%
ptch   = zeros([size(aff,1) , domSize , size(aff,4)]);
msk    = img > graythresh(img / 255) * 255;
bk     = mean(img(msk(:)));
padVal = size(img,1);
img    = padarray(img, [padVal , padVal], bk, 'both');

%% Sample image with affines for each segment
for e = 1 : size(aff,1)
    % Sample image with affines for each scale
    for s = 1 : size(aff,4)
        domSample = squeeze(aff(e,:,:,s)) * dom';
        imgSample = ...
            ba_interp2(img, domSample(1,:) + padVal, domSample(2,:) + padVal);
        
        %
        imgSample     = reshape(imgSample, domSize);
        ptch(e,:,:,s) = imgSample;
        
        if vis
            cla;
            imagesc(img);
            colormap gray;
            axis image;
            axis off;
            hold on;
            plt(domSample(1:2,:)'+padVal, 'g.', 10);
            
            drawnow;
        end
    end
end

end
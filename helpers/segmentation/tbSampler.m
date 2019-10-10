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

ptch = zeros([size(aff,1) , domSize , size(aff,4)]);
msk  = img > graythresh(img/255)*255;
bk   = mean(img(msk(:)));
pv   = 101;
img  = padarray(img, [pv pv], bk, 'both');

% For each segment
for e = 1 : size(aff,1)
    % For each scale
    for s = 1 : size(aff,4)
        sample_domain = squeeze(aff(e,:,:,s)) * dom';
        img_sample    = ba_interp2(img, sample_domain(1,:)+pv, sample_domain(2,:)+pv);
        img_sample    = reshape(img_sample, domSize);
        ptch(e,:,:,s) = img_sample;
        
        if vis
            cla;
            imagesc(img);
            colormap gray;
            axis image;
            axis off;
            hold on;
            plt(sample_domain(1:2,:)'+pv, 'g.', 10);
            
            drawnow;
        end
    end
end

end
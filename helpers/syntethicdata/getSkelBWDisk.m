function bw = getSkelBWDisk(img, padVal)
%% getSkelBWDisk: get distance transform of an image
%
%
% Usage:
%   bw = getSkelBWDisk(img, padVal)
%
% Input:
%   img: grayscale image to perform operation
%   padVal: size to pad image, defaults to size of the image (optional)
%
% Output:
%   bw: distance transform image
%

if nargin < 2
    padVal = size(img,1);
end

% Simple hresholding to get binary mask and generate padding around image
msk  = img > graythresh(img / 255) * 255;
msk  = padarray(msk, [padVal , padVal], 'replicate', 'both');

% Distance transform on padded skeleton
skel = bwmorph(~msk, 'skeleton', Inf);
bw   = double(bwdist(skel));

% Remove the padding and return the distance transform
szM  = size(img);
bw   = bw(padVal+1 : padVal+szM(1), padVal+1 : padVal+szM(2));

end


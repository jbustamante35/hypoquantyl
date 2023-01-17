function [bnd , oob] = bufferCropBox(bnd, soff, img)
%% bufferCropBox
%
% Usage:
%    [bnd , oob] = bufferCropBox(bnd, soff, img)
%
% Input:
%   bnd:
%   soff:
%   img:
%
% Output:
%   bnd: updated crop box
%   oob: out-of-bounds pixels to subtract off

% Check if crop box out of bounds
bnd = bnd + soff;
oob = (bnd(1) + bnd(3)) - size(img,2);

% Force crop box to fit in image, otherwise set oob to 0
if oob > 1; bnd(3) = bnd(3) - oob; else; oob = 0; end
end
function msk = crds2mask(img, crd, buff)
%% crds2mask: create logical mask with input coordinates set to true
% This function sets up a probability distribution matrix by creating a logical mask where pixels
% containing a contour are set to true.
%
% Usage:
%   msk = crds2mask(img, crd)
%
% Input:
%   img: inputted image
%   crd: set of x-/y-coordinates corresponding to inputted image
%   buff: range to extend mask image
%
% Output:
%   msk: logical mask of size matching inputted image, with coordinates set to true
%

%% Convert coordinates to integers if needed
if ~startsWith(class(crd), 'int')
    crd           = floor(crd);
    crd(crd == 0) = 1;    
end

%% Create mask and set coordinates to true
% Setup / initialization.
% msk      = zeros(size(img));
msk      = createMask(size(img), buff);
org      = [size(msk,1) round(size(msk,2)/3)];
crd      = slideCoords(crd, org);
idx      = sub2ind(size(msk), crd(:,2), crd(:,1));
msk(idx) = true;
end

function m = createMask(sz, buff)
%% createMask: subfunction to create mask of different size than original image (experimental)
% This tests what happens if you give the mask a buffer of specified pixels
% Input:
%   sz: size of original image
%   buff: number pixels to buffer by
b = floor(sz * buff);
m = zeros([sz(1) b(2)]);
end

function c = slideCoords(crd, org)
%% Slide x-coordinates to common starting point
d = org(2) - crd(1,1);
c = [(crd(:,1) + d) crd(:,2)];
end
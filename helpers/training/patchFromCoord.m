function P = patchFromCoord(seg, mid, img, sz)
%% patchFromCoord: generate an image patch centered around given coordinate
% This function takes the given coordinate and generates a square image patch of
% the size of the sz parameter. 
%
% Usage:
%   P = patchFromCoord(crd, img, sz)
%
% Input:
%   crd: coordinate in image to create a patch from
%   tng: tangent vector from coordinate
%   nrm: normal vector perpendicular to tangent vector from coordinate
%   img: corresponding image containing inputted coordinate
%   sz: distance from center coordinate to define size of patch
%
% Output:
%   P: image patch of size [sz sz] centered around crd parameter 
%

%% Placeholder output until this actually works
P = [];

%% Rotate image along tangent vector
s   = seg(1,:);
e   = seg(end,:);
[F, tng, nrm] = findFrame(s,e);
frm  = [tng ; nrm] + mid;
tSeg = [[0 0] ; tng] + mid;
nSeg = [[0 0] ; nrm] + mid;

%% Get coordinates of crop box


%% Get pixel intensities from crop box


end
function [X, Y, Z] = masterFunction1(img, cntr, len, dom, domSize, scls)
%% masterFunction1: algorithm obtain data from the inital run 
%
%
% Usage:
%   [X, Y, Z] = masterFunction1(img, cntr, len, dom, domSize, scls)
%
% Input:
%   img: grayscale image of an object
%   cntr: x-/y-coordinates of a contour of the object in the image
%   len: length to split the contour int osegments 
%   dom: domain coordinates to generate patches
%   domSize: size of the domains to generate patches from
%   scls: dimensions for scaling the patches up or down
%
% Output:
%   X: vectorized patches of the domains for all segments of all scales
%   Y: displacement vectors from the tangent bundle
%   Z: the tangent bundle associated with each segment of the contour
%

%% Some Constants
STEP = 1;
VIS  = 0;

%% Get Tangent Bundle, Core Frame, and S-Vectors in Midpoint-Normalized Frame
% Split contour into segments
segs = split2Segments(cntr, len, STEP, 1);

% Get Tangent Bundle and Displacements along bundle in the tangent frame
Z = contour2corestructure(cntr, len, STEP);

% Sample Image from Tangent Bundles
X = sampleCorePatches(img, Z, scls, dom, domSize, VIS);

% Get Displacements from the Core Structure
hlfIdx = ceil(size(segs,1) / 2);
Y      = [squeeze(segs(hlfIdx,:,:))' , ones(size(segs,3), 1)];

end


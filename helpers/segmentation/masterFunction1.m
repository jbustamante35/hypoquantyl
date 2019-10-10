function [X, Y, Z] = masterFunction1(img, cntr, len, dom, domSize, scls)
%% masterFunction1:
%
%
%
%
%% Some Constants
STEP = 1;

%% Get Tangent Bundle, Core Frame, and S-Vectors in Midpoint-Normalized Frame
% Split contour into segments
segs = split2Segments(cntr, len, STEP, 'new');

% Get Tangent Bundle and Displacements along bundle in the tangent frame
Z = contour2corestructure(cntr, len, STEP);

% Sample Image from Tangent Bundles
X = sampleCorePatches(img, Z, scls, dom, domSize);

% Get Displacements from the Core Structure
hlfIdx = ceil(size(segs,1) / 2);
Y      = [squeeze(segs(hlfIdx,:,:))' , ones(size(segs,3), 1)];

end


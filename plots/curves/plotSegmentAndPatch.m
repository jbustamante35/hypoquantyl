function plotSegmentAndPatch(crv, idx)
%% plotSegmentAndPatch: overlay envelope on image and display patch
% This function plots the envelope structure from a segment (Curve object) of a
% a contour onto the grayscale image it corresponds to. It also plots the image
% patch associated with that segment.
%
% You can use this function to generate a "movie" that runs through each segment
% of a contour with the following code:
%
% Usage:
%   plotSegmentAndPatch(crv, idx, cIdx, img, cvrt, envO, envI, imPt)
%
% Input:
%   crv: Curve object to extract data from
%   idx: segment to display information
%   cIdx: index of parent CircuitJB [ to be deprecated ]
%   img: grayscale image associated with segment [ to be deprecated ]
%   cvrt: curve coordinates in the image reference frame [ to be deprecated ]
%   envO: structure defining outer envelope of segment [ to be deprecated ]
%   envI: structure defining inner envelope of segment [ to be deprecated ]
%   imPt: cell array of image patches associated with curve [ to be deprecated ]
%
% Output:
%   fig: handle to figure
%

%% Extract data from Curve object
img   = crv.Parent.getImage('gray'); % Grayscale image
impth = crv.ImagePatches{idx};       % Envelope structure image patch 
strt  = crv.getEndPoint(idx, 1);     % Start point of segment
dest  = crv.getEndPoint(idx, 2);     % End point of segment

% Envelope coordinates in image frame
tItr = crv.getProperty('ENV_ITRS');
crds = crv.CoordPatches{idx};
segR = crds.mid;
maxO = crds.out(:,:,tItr);
maxI = crds.inn(:,:,tItr);
segO = arrayfun(@(x) crds.out(:,:,x), 1:tItr, 'UniformOutput', 0);
segI = arrayfun(@(x) crds.inn(:,:,x), 1:tItr, 'UniformOutput', 0);

% Misc data for figure title
segParent = fixtitle(crv.Parent.Origin);
segSize   = crv.getProperty('SEGMENTSIZE');
segScl    = crv.getProperty('ENV_SCALE');
segGauss  = crv.getProperty('GAUSSSIGMA');
segTtl    = crv.NumberOfSegments;

%% Overlay envelope structure onto image
cla;clf;
subplot(211);

imagesc(img);
colormap gray;
axis ij;
hold on;

plt(segR, 'y.-', 2);
plt(strt, 'g+', 10);
plt(dest, 'm+', 10);
plt(maxO, 'r.-', 1);
plt(maxI, 'b.-', 1);
cellfun(@(x) plt(x, 'r-', 0.5), segO, 'UniformOutput', 0);
cellfun(@(x) plt(x, 'b-', 0.5), segI, 'UniformOutput', 0);
ttl = sprintf('%s\nSegment %d | Segment Size %d | Total Segments %d | Envelope Scale Distance %d', ...
    segParent, idx, segSize, segTtl, segScl);
title(ttl);

%% Show image patch
subplot(212);
imagesc(impth);
colormap gray;
axis ij;
ttl = sprintf('Image Patch | Segment %d \n Gaussian Smooth Param %d | Envelope Itrs %d', ...
    idx, segGauss, tItr);
title(ttl);

end
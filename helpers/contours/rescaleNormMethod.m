function [D, scale_size] = rescaleNormMethod(X, offset)
%% rescaleNormMethod: curve normalization using midpoint between end points
% This function implements the method of normalization ultimately used for a
% probability matrix, where contours are rescaled and shifted such that the
% anchor points at the base of a contour are set to the same coordinates. The
% offset (off) parameter defines how far to shift the base anchor points from
% its original [0 0] point. This is meant to ensure the entire contour has no
% points in negative coordinates.
%
% Usage:
%   [D, scale_size] = rescaleNormMethod(X, off)
%
% Input:
%   X: original coordinates
%   offset: degree of rotation to
%
% Output:
%   D: shifted and rotated coordinates
%   scale_size: number of pixels to offset base anchorpoints from center
%

D               = normalizeCoordinates(X);
[D, scale_size] = rescaleCoordinates(D);
D               = offsetCoordinates(D, offset);
end

function nrm = normalizeCoordinates(crd)
%% normalizeCoordinates: normalize coordinates to [0,0] - [1,1]
mid = ((crd(1,:) + crd(end,:)) .'/2)';
nrm = crd - mid;
end

function [scl, sz] = rescaleCoordinates(crd)
%% rescaleCoordinates: rescale coordinates to [n x m] matrix
dst = pdist([crd(1,:) ; crd(end,:)]);
sz  = dst / 2; % Size to rescale coordinates
scl = crd / sz;
end

function fnl = offsetCoordinates(crd, offset)
%% offsetCoordinates: offset new center to location
% This sets the origin for creating the probability matrix
fnl = crd + offset;
fnl = fnl .* offset;
end

function [D, scale_size] = rescaleNormMethod(X, off)
%% rescaleNormMethod: normalization method for curves using midpoint between end points
% This function implements the method of normalization
%
% Usage:
%   [D, rescale_factor] = rescaleNormMethod(X)
%
% Input:
%   X: coordinates of original coordinates
%   scale_size: degree of rotation to
%
% Output:
%   D: coordinates of shifted and rotated contour
%   off: number of pixels to offset base anchorpoints from center
%

D               = normalizeCoordinates(X);
[D, scale_size] = rescaleCoordinates(D);
D               = offsetCoordinates(D, off);
end

function nrm = normalizeCoordinates(crd)
%% normalizeCoordinates: subfunction to normalize coordinates to [0,0] - [1,1]
mid = ((crd(1,:) + crd(end,:)) .'/2)';
nrm = crd - mid;
end

function [scl, sz] = rescaleCoordinates(crd)
%% rescaleCoordinates: subfunction to rescale coordinates to [n x m] matrix
dst = pdist([crd(1,:) ; crd(end,:)]);
sz  = dst / 2; % Size to rescale coordinates
scl = crd / sz;
end

function fnl = offsetCoordinates(crd, off)
%% offsetCoordinates: subfunction to set new center to desired location to create probability matrix
% fnl = [(crd(:,1) + off) crd(:,2)];
fnl = crd + off;
fnl = fnl .* off;
end

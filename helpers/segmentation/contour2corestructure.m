function [Z, L, segs, lbl] = contour2corestructure(cntr, len, stp, toCenter)
%% contour2corestructure: create the tangent bundle of a contour
% This function
%
% Usage:
%   [Z, L, segs, lbl] = contour2corestructure(cntr, len, step)
%
% Input:
%   cntr: x-/y-coordinates of a closed contour
%   len: length of the segments to split the contour
%   stp: step size to skip per segment
%   toCenter: index to set new center point for each segment (default 1)
%
% Output:
%   Z: tangent bundle for each of the contour's segments
%   L: distance of the labeled points of the contour
%   segs: segments of the split contour
%   lbl: labeled width of the base of the contour
%
%

%% Set default segment length and step sizes
switch nargin
    case 1
        len      = 25;
        stp      = 1;
        toCenter = 1;
    case 2
        stp      = 1;
        toCenter = 1;
    case 3
        toCenter = 1;
    case 4
    otherwise
        fprintf(2, 'Incorrect number of inputs (%d)\n', nargin);
        [Z, L, segs, lbl] = deal([]);
        return;
end

%% Label the base of the contour
lbl = labelContour(cntr);

%% Split contour into segments
segs = split2Segments(cntr, len, stp, 1, toCenter);
lbl  = split2Segments(lbl, len, stp, 1, toCenter);

%% Get Tangent Bundle and Displacements along bundle in the tangent frame
coref1  = squeeze(segs(end,:,:) - segs(1,:,:));
mid     = squeeze(segs(1,:,:)) + 0.5 * coref1;
coremag = sum(coref1 .* coref1, 1) .^ -0.5;

% Force tangents and normals to be unit length
coref1  = bsxfun(@times, coref1, coremag)';
coref2  = [coref1(:,2) , -coref1(:,1)];
Z       = [mid' , coref1 , coref2];

%% Compute the distance between anchor points
L = (coremag.^-1)';

end


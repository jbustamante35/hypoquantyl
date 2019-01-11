function X = reverseMidpointNorm(P, Pmat)
%% reverseMidpointNorm: revert midpoint-normalized contour to interpolated values
% This function is the reverse of the Midpoint Normalization Method (see midpointNorm), which takes
% coordinates from a Curve object's RawSegments and represents it as coordinates in which the
% euclidean midpoint between start and end points are set to [0 0]. This function requires the
% P-matrix (Pmat) that contains the vectors in the old and new reference frame in order to perform
% the rotation required for the conversion.
%
% NOTE: to fully convert back to raw coordinates, remember to add back the midpoint!!!
%
% Usage:
%   X = reverseMidpointNorm(P, Pmat)
%
% Input:
%   P: midpoint-normalized coordinates of a contour
%   Pmat: P-matrix holding basis vectors and midpoint
%
% Output:
%   X: contour in interpolated coordinates
%

%% Get the dot product of the inverse of the conversion matrix with normalized coordinates
if numel(size(P)) ~= 3
    P(:,3) = 0;
%     P(:,3) = 1;
    P      = P';
end

X = (Pmat^-1 * P);
X = X(1:2,:)';

end
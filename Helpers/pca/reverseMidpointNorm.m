function X = reverseMidpointNorm(P, Pmat)
%% reverseMidpointNorm: revert midpoint-normalized contour to interpolated values
%
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
X = (Pmat^-1 * P);
X = X(1:2,:);

end
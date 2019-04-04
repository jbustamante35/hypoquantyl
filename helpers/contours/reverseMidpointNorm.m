function X = reverseMidpointNorm(P, Pmat)
%% reverseMidpointNorm: revert midpoint-normalized to interpolated contour
% This function is the reverse of the Midpoint Normalization Method (see
% midpointNorm), which takes coordinates from a Curve object's RawSegments and
% represents it as coordinates in which the euclidean midpoint between start
% and end points are set to [0 0]. This function requires the P-matrix (Pmat)
% that contains the vectors in the old and new reference frame in order to
% perform the rotation required for the conversion.
% 
% In short, this operation rotates the inputted vector P by the amount described
% by the tangent vectoris visualized below (see midpointNorm for more detail):
%   Normalized --> Original
%                       [Tx Ty (-TxMx - TyMy)]-1   [Cx]     [Fx]
%     Pmat^-1 * Cxy =>  [Nx Ny (NxMx  - NyMy)]   . [Cy] ==> [Fy] + Mxy
%                       [0  0         1      ]     [1 ]     [1 ]
%
% NOTE: full conversion to raw coordinates requires addition of the midpoint!!!
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

%% Dot product of the inverse conversion matrix with normalized coordinates
if numel(size(P)) ~= 3
    P(:,3) = 0;
%     P(:,3) = 1;
    P      = P';
end

X = (Pmat^-1 * P);
X = X(1:2,:)';

end

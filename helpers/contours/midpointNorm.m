function [P, Pmat, M, T, N, Z] = midpointNorm(X, mth)
%% midpointNorm: normalization method for curves around midpoint
% This function implements the normalization method to express values in the
% inputted curve X's reference frame into a new reference frame. This new
% reference frame is centered at the midpoint between the starting and ending
% points of X and rotated along the vector tangent to the midpoint and end
% point, such that the midpoint becomes the origin and the tangent and normal
% vectors lie along the unit vectors.
%
% An intermediate step in this operation generates what I call a "P-matrix" (or
% "Pmat" for short), which contains the vectors necessary to convert coordinates
% from the normalized reference frame back to the original reference frame. The
% required elements of a Pmat are the following:
%   M) Midpoint vector: coordinate between start-end points
%   T) Tangent vector: coordinate parallel along the imaginary start-end line
%   N) Normal vector: coordinate perpendicular to the Tangent vector
%
% The operation to convert a point [Fx , Fy] between reference frames is as so:
%   Original --> Normalized
%                   [Tx Ty 0]   [0 0 -Mx]   [Tx Ty (-TxMx - TyMy)]   [Fx]   [Cx]
%     Pmat * Fxy => [Nx Ny 0] . [0 1 -My]=> [Nx Ny (NxMx  - NyMy)] . [Fy]=> [Cy]
%                   [0  0  1]   [0 0  1 ]   [0  0         1      ]   [1 ]   [1 ]
%
%   Normalized --> Original (see reverseMidpointNorm)
%                       [Tx Ty (-TxMx - TyMy)]-1   [Cx]     [Fx]
%     Pmat^-1 * Cxy =>  [Nx Ny (NxMx  - NyMy)]   . [Cy] ==> [Fy] + Mxy
%                       [0  0         1      ]     [1 ]     [1 ]
%
% Usage:
%   [P, Pmat, M, T, N, Z] = midpointNorm(X)
%
% Input:
%   X: coordinates of original vector
%
% Output:
%   P: coordinates of original vector expressed in new reference frame
%   Pmat: conversion matrix for new reference frame around midpoint
%   M: midpoint coordinate
%   T: tangent vector
%   N: normal vector
%   Z: Z-Vector slice [M T N]
%

if nargin < 2
    mth = 'old';
end

%% Find midpoint and vectors for new reference frame
s         = X(1,:);
e         = X(end,:);
M         = findMidpoint(s,e);
[F, T, N] = findFrame(s,e);
V         = -F * M';

% Store Z-Vector with or without midpoint added
switch mth
    case 'old'
        Z = [M , T+M , N+M];
    case 'new'
        Z = [M , T , N];
    otherwise
        fprintf(2, 'Method must be [old|new]'\n');
end

%% Compute conversion with P matrix
Pmat = [F , V ; 0 0 1]; % MidPoint in new reference frame
Pcnv = Pmat * [X, ones(length(X), 1)]';
P    = Pcnv(1:2,:)';

end

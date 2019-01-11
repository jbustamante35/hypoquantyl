function [P, Pmat, M, T, N] = midpointNorm(X)
%% midpointNorm: normalization method for curves around midpoint
% This function implements the method of normalization to express values in the
% inputted curve X in the new reference frame established at the midpoint
% between the starting and ending points of X.
%
% Usage:
%   [P, Pmat, M, T, N] = midpointNorm(X)
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
%

%% Find midpoint and vectors for new reference frame
s         = X(1,:);
e         = X(end,:);
M         = findMidpoint(s,e);
[F, T, N] = findFrame(s,e);
Z         = -F * M';

%% Compute conversion with P matrix
Pmat = [F , Z ; 0 0 1]; % MidPoint in new reference frame
% Pmat = [F , M' ; 0 0 1];  % MidPoint in original reference frame
Pcnv = Pmat * [X, ones(length(X), 1)]';
P    = Pcnv(1:2,:)';

end

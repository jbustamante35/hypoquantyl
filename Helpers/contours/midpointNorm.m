function [P, Pmat] = midpointNorm(X)
%% midpointNorm: normalization method for curves using midpoint between end points
% This function implements the method of normalization to express values in X in the new reference
% frame established at the midpoint between the starting and ending points of X.
%
% Usage:
%   [P, Pmat] = midpointNorm(X)
%
% Input:
%   X: coordinates of original vector
%
% Output:
%   P: coordinates of original vector expressed in new reference frame
%   Pmat: conversion matrix for new reference frame around midpoint
%

%% Find midpoint and vectors for new reference frame
s = X(1,:);
e = X(end,:);
M = findMidpoint(s,e);
F = findFrame(s,e);
Z = -F * M';

%% Compute conversion with P matrix
Pmat = [F , Z ; 0 0 1];
Pcnv = Pmat * [X, ones(length(X), 1)]';
P    = Pcnv(1:2,:)';
end

function M = findMidpoint(S, E)
%% getMidpoint: find midpoint coordinate between points S and E
% Input:
%   S: coordinate at start of curve
%   E: coordinate at end of curve
%
% Output:
%   M: coordinate between start and ending curve

M = S + 0.5 * (E - S);
end

function F = findFrame(S, E)
%% findFrame: vector representing the rotation needed to change between reference frames
% Input:
%   S: coordinate at start of curve
%   E: coordinate at end of curve
%
% Output:
%   F: [2 x 2] matrix representing rotated basis vectors

%% Rotation Matrix
Rmat = @(t) [[cos(t) ; -sin(t)], ...
    [sin(t) ; cos(t)]];
R = Rmat(deg2rad(90));

%% New reference frame
Z = E - S;
D = Z * norm(Z)^-1;
N = (R * D')';
F = [D ; N];
end


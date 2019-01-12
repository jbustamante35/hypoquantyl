function [F, T, N] = findFrame(S, E)
%% findFrame: returns matrix to change between reference frames
% This function uses a rotation matrix to compute the 90-degree rotation from 
% the input normal vector to find it's orthogonal tangent vector. The normal and 
% tangent vectors define the new reference frame. This function is primarily 
% used for the midpointNorm() function.
% 
% Usage:
%   F = findFrame(S, E)
%
% Input:
%   S: coordinate at start of curve
%   E: coordinate at end of curve
%
% Output:
%   F: [2 x 2] matrix representing rotated basis vectors
%   T: tangent vector
%   N: normal vector

%% Rotation Matrix to convert from normal to tangent vector
R = Rmat(90);

%% Compute new reference frame
Z = E - S;
T = Z * norm(Z)^-1;
N = (R * T')';
F = [T ; N];

end
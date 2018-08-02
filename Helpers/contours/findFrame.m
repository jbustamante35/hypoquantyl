function F = findFrame(S, E)
%% findFrame: vector representing the rotation needed to change between reference frames
% This function uses a rotation matrix to compute the 90-degree rotation from the input vector to
% find it's orthogonal vector. The input and orthogonal vectors define the new reference frame. This
% function is primarily used for the midpointNorm() function.
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

%% Rotation Matrix for orthogonal vector
R = Rmat(deg2rad(90));

%% New reference frame
Z = E - S;
D = Z * norm(Z)^-1;
N = (R * D')';
F = [D ; N];
end
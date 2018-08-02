function Rm = Rmat(deg)
%% Rmat: use the rotation matrix to perform a rotation of deg degrees in Euclidean space
% This function rotates a vector in xy space in a counter-clockwise direction. The input should be 
% in degrees, rather than radians. The rotation matrix is defined as:
%   Rmat = @(t) [[cos(t) ; -sin(t)],
%                [sin(t) ; cos(t)]];
%
% The output of this function is the matrix that will perform the transformation. Simply take the
% dot product of the rotation matrix and the transpose of the vector.
%
% Usage:
%   Rm = Rmat(deg)
%
% Input:
%   deg: degrees in which to rotate the vector in a counter-clockwise direction
%
% Output:
%   Rm: matrix that will perform the rotation transformation
%

rotation_matrix = @(t) [[cos(t) ; -sin(t)], ...
    [sin(t) ; cos(t)]];
Rm = rotation_matrix(deg2rad(deg));

end
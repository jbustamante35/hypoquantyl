function [Rm, R3] = Rmat(deg, rad, d)
%% Rmat: rotation matrix of deg degrees in Euclidean space
% This function returns the rotation matrix needed to perform a rotation of a
% vector in Euclidean (xy) space in a counter-clockwise direction. The input
% should be in degrees, rather than radians. The rotation matrix is defined as:
%   Rmat = @(t) [[cos(t) ; -sin(t)],
%                [sin(t) ; cos(t)]];
%
% The output of this function is the matrix that will perform the
% transformation. Simply take the dot product of the rotation matrix and the
% transpose of the vector to rotate to yield the rotated vector.
%
% Usage:
%   [Rm, R3] = Rmat(deg, rad, d)
%
% Input:
%   deg: degrees in which to rotate the vector in a counter-clockwise direction
%   rad: boolean to keep in radians (default 0)
%   d: dimension (x, y, or z) to perform a 3D rotation
%
% Output:
%   Rm: matrix that will perform the rotation transformation
%   R3: 3-Dimensional rotation matrix in x, y, or z direction
%

switch nargin
    case 1
        [rad , d] = deal(0);
    case 2
        d = 0;
end

rotation_matrix = @(t) [[cos(t) ; -sin(t)], ...
    [sin(t) ; cos(t)]];

% Convert to degrees (default) or keep in radians
if rad
    Rm = rotation_matrix(deg);
else
    Rm = rotation_matrix(deg2rad(deg));
end

if d
    switch d
        % 3D rotation matrix
        case 'x'
            % Rotation around x-axis
            r3 = @(t) [[1       , 0      , 0      ]; ...
                [0       , cos(t) , -sin(t)]; ...
                [0       , sin(t) , cos(t)]];
            
        case 'y'
            % Rotation around y-axis
            r3 = @(t) [[cos(t)  , 0 , sin(t)]; ...
                [0       , 1 , 0     ]; ...
                [-sin(t) , 0 , cos(t)]];
            
        case 'z'
            % Rotation around z-axis
            r3 = @(t) [[cos(t) , -sin(t) , 0]; ...
                [sin(t) ,  cos(t) , 0]; ...
                [ 0     ,     0   , 1]];
            
        otherwise
            % Default to rotation around z-axis
            r3 = @(t) [[cos(t) , -sin(t) , 0]; ...
                [sin(t) ,  cos(t) , 0]; ...
                [ 0     ,     0   , 1]];
    end
    
    R3 = r3(deg2rad(deg));
end

end
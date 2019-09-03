function [N , Z] = addNormalVector(M, T)
%% addNormalVector: 
% 
%
% Usage:
%   [N , Z] = addNormalVector(M, T) or [N,Z] = addNormalVector(Z)
%
% Input:
%   M: midpoint vector
%   T: tangent vector
%   Z: midpoint and normal vector as single matrix
%
% Output:
%   N: normal vector
%   Z: full Z-vector with added Normals
%

%%
% Combined midpoints and tangents
if nargin < 2
    Z = M;
    M = Z(:,1:2);
    T = Z(:,3:4);
end

% Return Normal vector and combined Z-Vector slices
N = (Rmat(90) * (T - M)')' + M;
Z = [M , T , N];

end
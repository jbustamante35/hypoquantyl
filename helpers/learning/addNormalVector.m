function [N , Z] = addNormalVector(M, T, addMid)
%% addNormalVector: 
% 
%
% Usage:
%   [N , Z] = addNormalVector(M, T) or [N,Z] = addNormalVector(Z)
%
% Input:
%   M: midpoint vector [or midpoint and normal vector as single matrix]
%   T: tangent vector
%   addMid: boolean to add midpoint to place tangent-normal in midpoint's frame
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
if addMid
    N = (Rmat(90) * (T - M)')' + M;
else
    N = (Rmat(90) * (T - M)')';
end

Z = [M , T , N];

end
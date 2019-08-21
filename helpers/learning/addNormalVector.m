function [N , Z] = addNormalVector(M, T)
%% addNormalVector: 
% 
%
% Usage:
%   [N , Z] = addNormalVector(M, T)
%
% Input:
%   M: midpoint vector
%   T: tangent vector
%
% Output:
%   N: normal vector
%   Z: full Z-vector with added Normals
%

%%
N = (Rmat(90) * (T - M)')' + M;
Z = [M , T , N];
end
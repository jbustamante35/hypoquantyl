function [N , Z] = addNormalVector(M, T, addMid, uLen)
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
%   uLen: force tangent and normals to be unit length
%
% Output:
%   N: normal vector
%   Z: full Z-vector with added Normals
%

%%
% Combined midpoints and tangents
if nargin < 2
    Z      = M;
    M      = Z(:,1:2);
    T      = Z(:,3:4);
    addMid = 0; % Default to not adding back midpoint
    uLen   = 1; % Default to forcing vectors to be unit length
end

% Determine if tangent should be subtracted by mean
if all(mean(abs(T)) > 1)
    T = T - M;
end

% Force Tangent and Normal vector to be unit length
if uLen
    tmpL = sum(T .* T, 2) .^ 0.5;
    T    = bsxfun(@times, T, tmpL .^-1);
end

N = (Rmat(90) * T')';

% Add back midpoint to tangent and normal vectors
if addMid
    T = T + M;
    N = N + M;
end

Z = [M , T , N];

end
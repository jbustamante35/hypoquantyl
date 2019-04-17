function pm = reconstructPmat(zVec)
%% reconstructPmat: return ground truth or generate the predicted Pmat
% Generates a Pmat from the given [1 x 6] Z-Vector
%
% Usage:
%   pm = reconstructPmat(zVec)
%
% Input:
%   zVec: [1 x 6] Z-Vector consisting of a segment's Midpoint-Tangent-Normal
%
% Output:
%   pm: [3 x 3] Pmat defining the matrix for reference frame conversions
%

%% Main components of a Z-Vector: Midpoint-Tangent-Normal
M = zVec(1:2);
T = zVec(3:4) - M; % Pmats have T and N subtracted by M
N = zVec(5:6) - M; % Pmats have T and N subtracted by M

%% Construct matrices to allow dot product to be taken
tF = [T(1) , T(2) , 0 ; ...
      N(1) , N(2) , 0 ; ...
      0    ,  0   , 1 ];

mF = [1    , 0    , -M(1) ; ...
      0    , 1    , -M(2) ; ...
      0    , 0    , 1 ];

%% Compute Pmat    
pm = tF * mF;

end
function pm = reconstructPmat(zvec, addMid, affInv)
%% reconstructPmat: return ground truth or generate the predicted Pmat
% Generates a Pmat from the given [1 x 6] Z-Vector
%
% Usage:
%   pm = reconstructPmat(zVec)
%
% Input:
%   zVec: [1 x 6] Z-Vector slice containing Midpoint-Tangent-Normal
%   addMid: pre-subtract off midpoint from tangent and normals (default 0)
%   affInv: take inverse of reference frame (default 0)
%
% Output:
%   pm: [3 x 3] Pmat representing the reference frame from the Z-Vector slice
%

%% Determine if midpoint should be subtracted
switch nargin
    case 1
        addMid = 0; % Do not subtract off midpoint
        affInv = 0; % Don't invert matrix
    case 2
        affInv = 0; % Don't invert matrix
end

%% Main components of a Z-Vector: Midpoint-Tangent-Normal
if addMid
    M = zvec(1:2);
    T = zvec(3:4) - M; % Pmats have T and N subtracted by M
    N = zvec(5:6) - M; % Pmats have T and N subtracted by M
else
    M = zvec(1:2);
    T = zvec(3:4); % Pmats should not have subtract off M
    N = zvec(5:6); % Pmats should not have subtract off M
end

%% Construct matrices to allow dot product to be taken
tF = [T(1) , T(2) , 0 ; ...
    N(1)   , N(2) , 0 ; ...
    0      ,  0   , 1 ];

mF = [1  , 0    , M(1) ; ...
    0    , 1    , M(2) ; ...
    0    , 0    , 1 ];

%% Compute Pmat or take it's inverse
pm = mF * tF;

if affInv
    pm = inv(pm);
end

end
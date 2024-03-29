function aff = tb2affine(tb, scls, affineInvert)
%% tb2affine: affine transformation of a tangent bundle with scaling
% Perform an affine transformation to sample images from domains. Order of
% output is a 3-D matrix of N rows - where N is the number of rows in the tangent
% bundle - and M columns - where M is two coordinates and 0 or 1 - and P slices
% - where P is three, containing tangents (1), normals (2), and midpoints (3) of
% the tangent bundle.
%
% NOTE:
%   The sizes of M and P may change once I implement taking the rotation
%   vector, instead of taking tangents and normals.
%
% Usage:
%   aff = tb2affine(tb, scls, affineInvert)
%
% Input:
%   tb: tangent bundle of [N x 6] size (midpoint-tangent-normal)
%   scls: scaling factors used to generate domains
%   affineInvert: return inversion of the affine transformation
%
% Output:
%   aff: affine transformation of all the points of the tangent bundle
%

%%
if nargin < 3; affineInvert = false; end

d2  = round(size(tb,2) / 2); %% NOTE: Change this when I implement rotation
aff = zeros(size(tb,1), d2, d2);
for e = 1 : size(tb,1)
    % Force tangents and normals to be unit length vectors
    mid = tb(e,1:2);
    tng = tb(e,3:4);
    tng = tng / norm(tng);
    nrm = tb(e,5:6);
    nrm = nrm / norm(nrm);

    %% Run affine transformation for all tangent points for all scales
    % Create 3D matrix ordered as tangents-normals-midpoints
    aff0 = [[tng , 0]' , [nrm , 0]' , [mid , 1]'];
    for s = 1 : size(scls,1)
        % Scale the transformation
        scl = diag([scls(s,:) , 1]);
        tmp = aff0 * scl;

        % Return the inverse of the transformation
        if affineInvert; tmp = inv(tmp); end

        aff(e,:,:,s) = tmp;
    end
end
end

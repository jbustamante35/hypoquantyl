function [nrmfld , tngfld , affs] = getVectorField(crv)
%% getNormalVectorField: compute normal vector field around a curve
% Description
%
% Usage:
%   [nrmfld , tngfld , affs] = getVectorField(crv)
%
% Input:
%   mline: x-/y-coordinates of a curve
%
% Output:
%   nrmfld: normal vector field
%
% Author Julian Bustamante <jbustamante@wisc.edu>
%

%% Vector Fields
% Tangents
tngfld = gradient(crv')';
len    = sum(tngfld .^ 2, 2) .^ -0.5;
tngfld = bsxfun(@times, tngfld , len);

% Normals
nrmfld      = flip(tngfld,2);
nrmfld(:,1) = -nrmfld(:,1);
len         = sum(nrmfld .^ 2, 2) .^ -0.5;
nrmfld      = bsxfun(@times, nrmfld, len);

%% Affine Matrix
dsp  = -[dot(crv, tngfld, 2) , dot(crv, nrmfld, 2)];
taff = [tngfld , dsp(:,1)];
naff = [nrmfld , dsp(:,2)];
caff = [zeros(size(crv)) , ones(size(crv,1),1)];
affs = cat(3, taff, naff, caff);
affs = permute(affs, [1 , 3 , 2]);

end

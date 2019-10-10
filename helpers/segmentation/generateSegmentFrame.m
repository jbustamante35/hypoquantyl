function [z , l] = generateSegmentFrame(crv)
%% generateSegmentFrame: obtain the affine transformation of a curve
%
%
% Usage:
%   [z , l] = generateSegmentFrame(crv)
%
% Input:
%   crv: x-/y-coordinates of a curve in it's original reference frame
%
% Output:
%   z: tangent bundle representing the segment's normalized reference frame
%   l: normalization length of some sort
%

%%
mid = crv(1,:) + 0.5 * (crv(end,:) - crv(1,:));
tng = crv(end,:) - crv(1,:);
l   = norm(tng);
tng = tng / l;
nrm = [tng(2) , -tng(1)];
nrm = nrm / norm(nrm);

%%
z = [mid , tng , nrm];

end



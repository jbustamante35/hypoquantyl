function [smpl , simg , sdom] = sampleAtDomain(img, zvec, scls, dom, domSize, vis)
%% Sample Z-Vector slices using given domain
%
%
% Usage:
%   [smpl , simg , sdom , pval] = ...
%       sampleAtDomain(img, zvec, scls, dom, domSize, vis)
%
% Input:
%   img:
%   zvec:
%   scls:
%   dom:
%   domSize:
%   vis:
%
% Output:
%   smpl:
%   simg:
%   sdom:
%

% Affine transform of Tangent Bundles, then sample image at affines
aff                  = tb2affine(zvec, scls);
[smpl , simg , sdom] = tbSampler(double(img), double(aff), dom, domSize, vis);

% Return Patches sampled from the Core and Displacements along the Core
ssz  = size(smpl);
smpl = reshape(smpl, [ssz(1) , prod(ssz(2:end))]);

end

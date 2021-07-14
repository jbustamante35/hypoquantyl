function [smpl , simg , sdom] = sampleAtDomain(img, zvec, scls, dom, domSize, vis, sidx, dshp)
%% Sample Z-Vector slices using given domain
%
%
% Usage:
%   [smpl , simg , sdom] = sampleAtDomain(img, zvec, scls, dom, domSize, vis)
%
% Input:
%   img:
%   zvec:
%   scls:
%   dom:
%   domSize:
%   vis: figure handle for visualizing data
%   sidx: save index
%   dshp: shapes of domains (for text output)
%
% Output:
%   smpl:
%   simg:
%   sdom:
%

%%
if nargin < 7
    sidx = 0;
    dshp = '';
end

% Affine transform of Tangent Bundles, then sample image at affines
aff                  = tb2affine(zvec, scls);
[smpl , simg , sdom] =  ...
    tbSampler(double(img), double(aff), dom, domSize, vis, sidx, dshp);

% Return Patches sampled from the Core and Displacements along the Core
ssz  = size(smpl);
smpl = reshape(smpl, [ssz(1) , prod(ssz(2:end))]);

end

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
%   vis: figure handle index for visualizing image patches [0 for no figure]
%   sidx: unique index value for saving filename [0 for no save]
%   dshp: shape of domains (for text output) [default '']
%
% Output:
%   smpl:
%   simg:
%   sdom:
%

%%
if nargin < 6; vis  = 0;  end
if nargin < 7; sidx = 0;  end
if nargin < 8; dshp = ''; end

% Affine transform of Tangent Bundles, then sample image at affines
aff                  = tb2affine(zvec, scls);
[smpl , simg , sdom] =  ...
    tbSampler(double(img), double(aff), dom, domSize, vis, sidx, dshp);

% Return Patches sampled from the Core and Displacements along the Core
ssz  = size(smpl);
smpl = reshape(smpl, [ssz(1) , prod(ssz(2:end))]);
end

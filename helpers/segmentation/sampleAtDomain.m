function [smpl , simg , sdom] = sampleAtDomain(img, zvec, scls, dom, domSize, dsk, fidx, sidx, dshp)
%% Sample Z-Vector slices using given domain
%
%
% Usage:
%   [smpl , simg , sdom] = sampleAtDomain(img, zvec, ...
%       scls, dom, domSize, dsk, fidx, sidx, dshp)
%
% Input:
%   img:
%   zvec:
%   scls:
%   dom:
%   domSize:
%   dsk: disk size to smooth binary mask
%   fidx: figure handle index for visualizing image patches [0 for no figure]
%   sidx: unique index value for saving filename [0 for no save]
%   dshp: shape of domains (for text output) [default '']
%
% Output:
%   smpl:
%   simg:
%   sdom:

%%
if nargin < 6; dsk  = 3;  end
if nargin < 7; fidx = 0;  end
if nargin < 8; sidx = 0;  end
if nargin < 9; dshp = ''; end

% Affine transform of Tangent Bundles, then sample image at affines
aff                  = tb2affine(zvec, scls);
[smpl , simg , sdom] =  ...
    tbSampler(double(img), double(aff), dom, domSize, dsk, fidx, sidx, dshp);

% Return Patches sampled from the Core and Displacements along the Core
ssz  = size(smpl);
smpl = reshape(smpl, [ssz(1) , prod(ssz(2:end))]);
end

function smpl = sampleCorePatches(img, zvec, scls, doms, domSizes, vis, sidx, dshp)
%% sampleCorePatches: sample image from tangent bundle points
%
%
% Usage:
%   smpl = sampleCorePatches(img, zvec, scls, doms, domSizes, vis, dshp)
%
% Input:
%   img:
%   zvec:
%   scls:
%   doms:
%   domSizes:
%   vis: figure handle index to visualize image patches
%   sidx: save index
%   dshp: shapes of domains (for text output)
%
% Output:
%   smpl: concatenation of image patches sampled at all domains of each scale
%

%%
if nargin < 7
    sidx = 0;
    dshp = cell(size(doms));
end

%%
smpl = cellfun(@(s,d,ds,shp) ...
    sampleAtDomain(img, zvec, s, d, ds, vis, sidx, shp), ...
    scls, doms, domSizes, dshp, 'UniformOutput', 0);
smpl = cat(2, smpl{:});

end

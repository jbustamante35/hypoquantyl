function smpl = sampleCorePatches(img, zvec, scls, doms, domSizes, par, vis, sidx, dshp)
%% sampleCorePatches: sample image from tangent bundle points
%
%
% Usage:
%   smpl = sampleCorePatches(img, zvec, ...
%           scls, doms, domSizes, par, vis, sidx, dshp)
%
% Input:
%   img:
%   zvec:
%   scls:
%   doms:
%   domSizes:
%   par:
%   vis: figure handle index to visualize image patches
%   sidx: save index
%   dshp: shapes of domains (for text output)
%
% Output:
%   smpl: concatenation of image patches sampled at all domains of each scale
%

%%
switch nargin
    case 5
        par  = 0;
        vis  = 0;
        sidx = 0;
        dshp = cell(size(doms));
    case 6
        vis  = 0;
        sidx = 0;
        dshp = cell(size(doms));
    case 7
        sidx = 0;
        dshp = cell(size(doms));
    case 8
        dshp = cell(size(doms));
end

%%
if par
    smpl = cell(numel(scls, 1));
    parfor s = 1 : numel(scls)
        scl = scls{s};
        dom = doms{s};
        dsz = domSizes{s};
        shp = dshp{s};
        
        smpl{s} = sampleAtDomain(img, zvec, scl, dom, dsz, vis, sidx, shp);
    end
else
    smpl = cellfun(@(s,d,ds,shp) ...
        sampleAtDomain(img, zvec, s, d, ds, vis, sidx, shp), ...
        scls, doms, domSizes, dshp, 'UniformOutput', 0);
end

smpl = cat(2, smpl{:});
end

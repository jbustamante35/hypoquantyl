function smpl = sampleCorePatches(img, zvec, scls, doms, domSizes, par, dsk, fidx, sidx, dshp)
%% sampleCorePatches: sample image from tangent bundle points
%
%
% Usage:
%   smpl = sampleCorePatches(img, zvec, ...
%           scls, doms, domSizes, par, dsk, fidx, sidx, dshp)
%
% Input:
%   img:
%   zvec:
%   scls:
%   doms:
%   domSizes:
%   par:
%   dsk: disk size to smooth binary mask
%   fidx: figure handle index to visualize image patches
%   sidx: save index
%   dshp: shapes of domains (for text output)
%
% Output:
%   smpl: concatenation of image patches sampled at all domains of each scale
%

%%
if nargin < 6;  par  = 0;                                                    end
if nargin < 7;  dsk  = 3;                                                    end
if nargin < 8;  fidx = 0;                                                    end
if nargin < 9;  sidx = 0;                                                    end
if nargin < 10; dshp = arrayfun(@(x) '', 1:numel(doms), 'UniformOutput', 0); end

%%
if par
    smpl = cell(numel(scls, 1));
    parfor s = 1 : numel(scls) 
        scl = scls{s};
        dom = doms{s};
        dsz = domSizes{s};
        shp = dshp{s};

        smpl{s} = sampleAtDomain(img, zvec, scl, dom, dsz, ...
            dsk, fidx, sidx, shp);
    end
else
    smpl = cellfun(@(s,d,ds,shp) ...
        sampleAtDomain(img, zvec, s, d, ds, dsk, fidx, sidx, shp), ...
        scls, doms, domSizes, dshp, 'UniformOutput', 0);
end

smpl = cat(2, smpl{:});
end

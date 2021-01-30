function smpl = sampleCorePatches(img, zvec, scls, doms, domSizes, vis)
%% sampleCorePatches: sample image from tangent bundle points
%
%
% Usage:
%   smpl = sampleCorePatches(img, zvec, scls, doms, domSizes, vis)
%
% Input:
%   img:
%   zvec:
%   scls:
%   doms:
%   domSizes:
%   vis:
%
% Output:
%   smpl: concatenation of image patches sampled at all domains of each scale
%

%%
if vis
    figclr;
end

smpl = cellfun(@(s,d,ds) sampleAtDomain(img, zvec, s, d, ds, vis), ...
    scls, doms, domSizes, 'UniformOutput', 0);
smpl = cat(2, smpl{:});

end

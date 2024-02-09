function showPrediction_multi(NDOR, gens, pik, figs)
%% showPrediction_multi
%
% Usage:
%   showPrediction_multi(NDOR, gens, pik, figs)
%
% Input:
%   NDOR:
%   gens:
%   pik:
%   figs:
%

if nargin < 3; pik = 'best'; end
if nargin < 4; figs = 1 : 6; end

ngens = numel(gens);

figclr(figs);
for gidx = 1 : ngens
    g     = gens(gidx);
    gnm   = fixtitle(g.GenotypeName);
    sdls  = g.getSeedling;
    nsdls = g.NumberOfSeedlings;
    fidxs = arrayfun(@(x) x, (1 : nsdls)', 'UniformOutput', 0);
    nhyps = g.TotalImages;
    for hidx = 1 : nhyps
        imgs = arrayfun(@(x) x.MyHypocotyl.getImage(hidx, 'gray', 'upper'), ...
            sdls, 'UniformOutput', 0);
        hyps = NDOR{gidx}(hidx,:)';
        ttls = cellfun(@(x) sprintf('Normalized Models\n%s [%d of %d]\nSeedling %d of %d | Frame %d of %d', ...
            gnm, gidx, ngens, x, nsdls, hidx, nhyps), fidxs, 'UniformOutput', 0);
        cellfun(@(i,h,f,t) showPrediction(i,h.uhyp.(pik),f,t), ...
            imgs, hyps, fidxs, ttls);
    end
end

end
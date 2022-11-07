function [uregr , t , uvprf , regr , vprf] = averageTracking(t, sidxs, ftrp, ltrp, lthr, smth, rver, vis, gidx)
%% averageTracking: compile tracking data and compute average REGR
%
% Usage:
%   [uregr , t , uvprf , regr , vprf] = averageTracking( ...
%       t, sidxs, ftrp, ltrp, lthr, smth, rver, vis, gidx)
%
% Input:
%   t: output of trackingProcessor
%   sidxs: seedlings to exclude from averaging [default []]
%   ftrp: interpolation size for time (frames) [default 500]
%   ltrp: interpolation size for location (arclength) [default 1000]
%   lthr: threshold length from tip for normalization [default 300]
%   smth: smoothing disk size [default 1]
%   rver: use original lenghts and velocities instead of repaired (default 0)
%   vis: figure handle index to visualize intermediate steps [default 0]
%   gidx: genotype index for visualization [default 0]
%
% Output:
%   uregr: mean REGR of top 'lthr' pixels from tip
%   t: output returned with excluded seedlings
%   uvprf: mean velocity profile of top 'lthr' pixels from tip
%   regr: REGR per seedling
%   vprf: velocity profile per seedling
%

if nargin < 2; sidxs = [];   end
if nargin < 3; ftrp  = 500;  end
if nargin < 4; ltrp  = 1000; end
if nargin < 5; lthr  = 300;  end
if nargin < 6; smth  = 1;    end
if nargin < 7; rver  = 0;    end
if nargin < 8; vis   = 0;    end
if nargin < 9; gidx  = 0;    end

% Exclude Seedlings
t = excludeSeedlings(t, sidxs);

% Extract raw or repaired arclength and velocity
qq  = linspace(0, 1, ltrp);
if rver
    len = t.Output.Arclength.lraw;
    vel = t.Output.Velocity.traw;
else
    len = t.Output.Arclength.lrep;
    vel = t.Output.Velocity.trep;
end

%%
nsdls = numel(len);
vprf  = cell(nsdls,1);
for sidx = 1 : nsdls
    blen = len{sidx} < lthr;
    nv   = zeros(size(blen));

    % Show intermediate steps of filtering out by arclength
    if vis
        showArclengthProcessing(len{sidx}, blen, vel{sidx}, gidx, sidx);
    end

    % Interpolate velocity profile to threshold length from tip
    for i = 1 : size(blen,2)
        flen    = find(blen(:,i));
        nn      = linspace(0, qq(flen(end)), ltrp);
        vv      = vel{sidx}(flen,i);
        ff      = linspace(0, qq(flen(end)), numel(vv));
        nv(:,i) = interp1(ff, vv, nn)';
    end

    vprf{sidx} = nv;
end

% Measure REGR and get means across all seedlings
regr  = cellfun(@(x) measureREGR(x, 'fsmth', smth, ...
    'xtrp', ftrp, 'ytrp', ltrp), vprf, 'UniformOutput', 0);
uregr = mean(cat(3, regr{:}),3);
uvprf = mean(cat(3, vprf{:}),3);

% Show averaged REGR across seedlings
if vis
    figclr(4);
    imagesc(uregr); colorbar; colormap jet;
    title(sprintf('Averaged REGR\n%d seedlings', nsdls));
    drawnow;
end
end

function t = excludeSeedlings(t, sidxs)
%% excludeSeedlings: remove seedlings from averaging
%
% Usage:
%   t = excludeSeedlings(t, sidxs)
%
% Input:
%   tinn: full input data
%   sidxs: indices of seedlings to exclude
%
% Output:
%   tout: dataset with excluded seedlings

o = t.Output;

o.Tracking.raw(:,sidxs)   = [];
o.Tracking.lengths(sidxs) = [];
o.Tracking.ilens(sidxs)   = [];

o.Arclength.raw(sidxs) = [];
o.Arclength.rep(sidxs) = [];
o.Arclength.lraw(sidxs) = [];
o.Arclength.lrep(sidxs) = [];

o.Velocity.raw(sidxs) = [];
o.Velocity.rep(sidxs) = [];
o.Velocity.traw(sidxs) = [];
o.Velocity.trep(sidxs) = [];

o.Profile.raw(sidxs) = [];
o.Profile.rep(sidxs) = [];

o.REGR.raw(sidxs) = [];
o.REGR.rep(sidxs) = [];

t.Output        = o;
t.Data.Excluded = sidxs;
end

function showArclengthProcessing(len, blen, vel, gidx, sidx)
%% showArclengthProcessing
% Full arclength
figclr(1);
imagesc(len);
colormap jet;
title(sprintf('%d | %d', gidx, sidx));

% Arclength points above threshold
figclr(2);
imagesc(blen);
colormap jet;
title(sprintf('%d | %d', gidx, sidx));

% Velocities within length threshold
figclr(3);
imagesc(vel);
colormap jet;
title(sprintf('%d | %d', gidx, sidx));
drawnow;
end
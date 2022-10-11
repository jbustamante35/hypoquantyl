function [uregr , uvprf , regr , vprf] = averageTracking(t, gidx, ftrp, ltrp, lthr, smth, vis, raw)
%% averageTracking: compile tracking data and compute average REGR
%
% Usage:
%   [uregr , uvprf , regr , vprf] = averageTracking(t, gidx, ...
%       ftrp, ltrp, lthr, smth, vis, raw)
%
% Input:
%   t: output of trackingProcessor
%   gidx: genotype index
%   ftrp: interpolation size for time (frames)
%   ltrp: interpolation size for location (arclength)
%   lthr: threshold length from tip for normalization
%   smth: smoothing disk size
%   vis: visualize intermediate
%   raw: use original lenghts and velocities instead of repaired (default 0)
%
% Output:
%   uregr: mean REGR of top 'lthr' pixels from tip
%   uvprf: mean velocity profile of top 'lthr' pixels from tip
%   regr: REGR per seedling
%   vprf: velocity profile per seedling
%

if nargin < 2; gidx = 0;    end
if nargin < 3; ftrp = 500;  end
if nargin < 4; ltrp = 1000; end
if nargin < 5; lthr = 300;  end
if nargin < 6; smth = 1;    end
if nargin < 7; vis  = 0;    end
if nargin < 8; raw  = 0;    end

% Extract raw or repaired arclength and velocity
qq  = linspace(0, 1, ltrp);
if raw
    len = t.Output.Arclength.lraw;
    vel = t.Output.Velocity.traw;
else
    len = t.Output.Arclength.lrep;
    vel = t.Output.Velocity.trep;
end

%%
ns   = numel(len);
vprf = cell(ns,1);
for sidx = 1 : ns
    blen = len{sidx} < lthr;
    nv   = zeros(size(blen));

    % Show intermediate steps of filtering out by arclength
    if vis; showArclengthProcessing(len{sidx}, blen, vel{sidx}, gidx, sidx); end

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
    imagesc(uregr);
    colormap jet;
    title(sprintf('Averaged REGR\n%d seedlings', ns));
    drawnow;
end
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
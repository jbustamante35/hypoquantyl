function fnm = showTrackingProcessing(v, r, ttl, fidx, fdims, fblu, vaxis, raxis, fsz, fcnv)
%% showTrackingProcessing
%
% Usage:
%   fnm = showTrackingProcessing(v, r, ttl, fidx, ...
%       fdims, fblu, vaxis, raxis, fsz, fcnv)
%
% Input:
%   v: velocity
%   r: regr
%   ttl: figure title
%   fidx: figure handle index (default 1)
%   fblu: frame that blue light was turned on (default 0)
%   vaxis: velocity limit range and c-axis length (default [0 , 0.3 , 4])
%   raxis: regr limit range and c-axis length (default [0 , 8 , 5])
%   fsz: font size array (default [5 , 8 , 8])
%   fcnv: conversion functions (default [])

%%
if nargin < 1;  v     = [];            end
if nargin < 2;  r     = [];            end
if nargin < 3;  ttl   = [];            end
if nargin < 4;  fidx  = 1;             end
if nargin < 5;  fdims = [1 , 2 , 1];   end
if nargin < 6;  fblu  = 0;             end
if nargin < 7;  vaxis = [0 , 0.3 , 4]; end
if nargin < 8;  raxis = [0 , 8 , 5];   end
if nargin < 9;  fsz   = [5 , 8 , 8];   end
if nargin < 10; fcnv  = [];            end

if isempty(v); [ltrp , ftrp] = size(r); else; [ltrp , ftrp] = size(v); end
lax = 0 : round(ltrp / 4) : ltrp;
fax = 0 : 20 : ftrp;
blu = [[fblu , 5] ; [fblu , ltrp-5]];

if isempty(v) || isempty(r)
    rows = 1;
    cols = 1;
    sidx = 1;
else
    rows = fdims(1);
    cols = fdims(2);
    sidx = fdims(3);
end
[vttl , rttl] = deal(ttl);
if iscell(ttl); vttl = ttl{1}; rttl = ttl{2}; end

% Convert units
if ~isempty(fcnv)
    p2m = fcnv{1}; % Length in which REGR was sampled
    f2h = fcnv{2}; % Frames to hour conversion
    h2f = fcnv{3}; % Hour to Frames conversion

    % Some absurd nonsense to make y-axis look nicer
    nlax = numel(lax) - 1;
    yax  = round(0 : p2m / nlax : p2m);

    % Some absurd nonsense to make x-axis look nicer
    ntrp = round(ftrp, 1, 'significant');
    htrp = round(f2h(ntrp,2),1);
    nfax = numel(fax);
    fax  = h2f(1 : round(htrp / nfax) : htrp,2);
    xax  = f2h(fax,2);

    xu = 'h';
    yu = 'mm';
else
    xu  = 'frms';
    yu  = 'pix';
    xax = fax;
    yax = lax;
end

xlbl = sprintf('t (%s)', xu);
ylbl = sprintf('L (%s)', yu);
vttl = sprintf('V (%s / %s)\n%s', yu, xu, vttl);
rttl = sprintf('REGR (%% / %s)\n%s', xu, rttl);

% Velocity
figclr(fidx,1);
if ~isempty(v)
    subplot(rows, cols, sidx);
    imagesc(v);
    colormap jet;
    colorbar;
    clim(vaxis(1:2));
    hold on;
    plt(blu, 'r-', fsz(1));
    xlabel(xlbl, 'FontWeight', 'b', 'FontSize', fsz(2));
    ylabel(ylbl, 'FontWeight', 'b', 'FontSize', fsz(2));
    title(vttl, 'FontSize', fsz(3));
    xticks(fax);
    yticks(lax);
    axis square;

    setAxis(fidx, fsz(2), 'b');

    vax = interpolateVector(vaxis(1:2), vaxis(3));
    cb  = colorbar;
    cb.FontWeight = 'b';
    cb.FontSize   = fsz(3);
    cb.Ticks      = vax;

    xticklabels(xax);
    yticklabels(yax);

    sidx = sidx + 1;
end

% REGR
if ~isempty(r)
    subplot(rows, cols, sidx);
    imagesc(r);
    colormap jet;
    colorbar;
    clim(raxis(1:2));
    hold on;
    plt(blu, 'r-', fsz(1));
    xlabel(xlbl, 'FontWeight', 'b', 'FontSize', fsz(2));
    ylabel(ylbl, 'FontWeight', 'b', 'FontSize', fsz(2));
    title(rttl, 'FontSize', fsz(3));
    xticks(fax);
    yticks(lax);
    axis square;

    setAxis(fidx, fsz(2), 'b');

    rax = interpolateVector(raxis(1:2), raxis(3));
    cb  = colorbar;
    cb.FontWeight = 'b';
    cb.FontSize   = fsz(3);
    cb.Ticks      = rax;

    xticklabels(xax);
    yticklabels(yax);
end

fnm = sprintf('%s_velocity_regr_results', tdate);
end

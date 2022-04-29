function fnms = showTracking(t, vprf, regr, varargin)
%% showTracking:
%
%
% Usage:
%   fnms = showTracking(t, vprf, regr, varargin)
%
% Input:
%   t:
%   nlen:
%   regr:
%   varargin:
%       p.addOptional('ftrp', 500);
%       p.addOptional('ltrp', 1000);
%       p.addOptional('lthr', 300);
%       p.addOptional('gidx', 0);
%       p.addOptional('gset', '');
%       p.addOptional('clr', 'jet');
%       p.addOptional('eidx', 25 : 100);
%       p.addOptional('midx', 200 : 300);
%       p.addOptional('lidx', 400 : 500);
%       p.addParameter('fidxs', 1 : 6);
%       p.addParameter('sav', 0);
%
% Output:
%   fnms:
%

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

%%
gnm  = t.Data.Genotype;
gttl = fixtitle(gnm);
ns   = numel(vprf);
al   = cat(3, vprf{:});
el   = cat(3, regr{:});
alen = mean(al,3);
elen = mean(el,3);

% ---------------------------------------------------------------------------- %
% Velocity map of upper regions
if ns > 1;    cols = 3; else; cols = 1; end
if ns > cols; rows = 2; else; rows = 1; end

figclr(1);
for sidx = 1 : ns
    subplot(rows, cols, sidx);
    imagesc(vprf{sidx});
    colormap(clr);
    xlabel('t', 'FontSize', 10, 'FontWeight', 'b');
    ylabel('L', 'FontSize', 10, 'FontWeight', 'b');
    ttl = sprintf('%s [seedling %d]', gttl, sidx);
    title(ttl, 'FontSize', 8);

    ax          = gca;
    ax.FontSize = 8;
end
drawnow;

fnms{1} = sprintf('%s_velocitymaps_%s_genotype%02d_%02dseedlings_%s', ...
    tdate, gnm, gidx, ns, gset);

% ---------------------------------------------------------------------------- %
% REGR map of upper regions
figclr(2);
for sidx = 1 : ns
    subplot(rows, cols, sidx);
    imagesc(regr{sidx});
    colormap(clr);
    xlabel('t', 'FontSize', 10, 'FontWeight', 'b');
    ylabel('L', 'FontSize', 10, 'FontWeight', 'b');
    ttl = sprintf('%s [seedling %d]', gttl, sidx);
    title(ttl, 'FontSize', 8);

    ax          = gca;
    ax.FontSize = 8;
end
drawnow;

fnms{2} = sprintf('%s_regrmaps_%s_genotype%02d_%02dseedlings_%s', ...
    tdate, gnm, gidx, ns, gset);

% ---------------------------------------------------------------------------- %
epos = [eidx(1) , 5 , numel(eidx) - 1 , ltrp - 5];
mpos = [midx(1) , 5 , numel(midx) - 1 , ltrp - 5];
lpos = [lidx(1) , 5 , numel(lidx) - 1 , ltrp - 5];

rows = 1;
cols = 2;

% Map averaged Velocity and REGR
figclr(3);
subplot(rows, cols, 1);
imagesc(alen);
colormap(clr);
rectangle('Position', epos, 'EdgeColor', 'k', 'LineWidth', 2);
rectangle('Position', mpos, 'EdgeColor', 'r', 'LineWidth', 2);
rectangle('Position', lpos, 'EdgeColor', 'b', 'LineWidth', 2);

xlabel('t', 'FontSize', 10, 'FontWeight', 'b');
ylabel('L', 'FontSize', 10, 'FontWeight', 'b');
ttl = sprintf('Averaged Velocity\n%s [%d seedlings]', gttl, ns);
title(ttl, 'FontSize', 10);
drawnow;

subplot(rows, cols, 2);
imagesc(elen);
colormap(clr);
rectangle('Position', epos, 'EdgeColor', 'k', 'LineWidth', 2);
rectangle('Position', mpos, 'EdgeColor', 'r', 'LineWidth', 2);
rectangle('Position', lpos, 'EdgeColor', 'b', 'LineWidth', 2);

xlabel('t', 'FontSize', 10, 'FontWeight', 'b');
ylabel('L', 'FontSize', 10, 'FontWeight', 'b');
ttl = sprintf('Averaged REGR\n%s [%d seedlings]', gttl, ns);
title(ttl, 'FontSize', 10);
drawnow;

fnms{3} = sprintf('%s_averagedtracking_map_%s_genotype%02d_%02dseedlings_%s', ...
    tdate, gnm, gidx, ns, gset);

% ---------------------------------------------------------------------------- %
% Plot ranges of time from averaged V and REGR
figclr(4);
subplot(rows, cols, 1);
plt(mean(alen(:,eidx),2), 'k-', 2);
hold on;
plt(mean(alen(:,midx),2), 'r-', 2);
plt(mean(alen(:,lidx),2), 'b-', 2);

xlabel('L', 'FontSize', 10, 'FontWeight', 'b');
ylabel('V', 'FontSize', 10, 'FontWeight', 'b');
lgn = {sprintf('%d - %d', eidx(1), eidx(end)) , ...
    sprintf('%d - %d', midx(1), midx(end)) , ...
    sprintf('%d - %d', lidx(1), lidx(end))};
ttl = sprintf('Averaged Velocity [top %d pixels]\n%s [%d seedlings]', ...
    lthr, gttl, ns);
legend(lgn, 'Location', 'southeast', 'FontWeight', 'b');
title(ttl, 'FontSize', 10);

subplot(rows, cols, 2);
plt(mean(elen(:,eidx),2), 'k-', 2);
hold on;
plt(mean(elen(:,midx),2), 'r-', 2);
plt(mean(elen(:,lidx),2), 'b-', 2);

xlabel('L', 'FontSize', 10, 'FontWeight', 'b');
ylabel('REGR', 'FontSize', 10, 'FontWeight', 'b');
ttl = sprintf('Averaged REGR [top %d pixels]\n%s [%d seedlings]', ...
    lthr, gttl, ns);
title(ttl, 'FontSize', 10);

fnms{4} = sprintf('%s_averagedtracking_plot_%s_genotype%02d_%02dseedlings_%s', ...
    tdate, gnm, gidx, ns, gset);

% ---------------------------------------------------------------------------- %
% Map averaged Velocity [unmarked]
figclr(5);
imagesc(alen);
colormap(clr);
xlabel('t', 'FontSize', 10, 'FontWeight', 'b');
ylabel('L', 'FontSize', 10, 'FontWeight', 'b');
ttl = sprintf('Averaged Velocity\n%s [%d seedlings]', gttl, ns);
title(ttl, 'FontSize', 10);
drawnow;

fnms{5} = sprintf('%s_averagedtracking_map_velocity_%s_genotype%02d_%02dseedlings_%s', ...
    tdate, gnm, gidx, ns, gset);

% Map averaged REGR [unmarked]
figclr(6);
imagesc(elen);
colormap(clr);
xlabel('t', 'FontSize', 10, 'FontWeight', 'b');
ylabel('L', 'FontSize', 10, 'FontWeight', 'b');
ttl = sprintf('Averaged REGR\n%s [%d seedlings]', gttl, ns);
title(ttl, 'FontSize', 10);
drawnow;

fnms{6} = sprintf('%s_averagedtracking_map_regr_%s_genotype%02d_%02dseedlings_%s', ...
    tdate, gnm, gidx, ns, gset);

% Save figures
if sav
    figs = 1 : numel(fnms);
    tdir = sprintf('tracking_results/figures/%s/%s', tdate, gnm);
    saveFiguresJB(figs, fnms, tdir);
end
end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
p = inputParser;

% Misc Options
p.addOptional('ftrp', 500);
p.addOptional('ltrp', 1000);
p.addOptional('lthr', 300);
p.addOptional('gidx', 0);
p.addOptional('gset', '');
p.addOptional('clr', 'jet');
p.addOptional('eidx', 25 : 100);
p.addOptional('midx', 200 : 300);
p.addOptional('lidx', 400 : 500);

% Visualization Options
% p.addParameter('fidxs', 1 : 6);
p.addParameter('sav', 0);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end

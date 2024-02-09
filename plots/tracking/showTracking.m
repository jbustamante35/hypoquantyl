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
%       p.addOptional('bthr', 1);
%       p.addOptional('fblu', 0);
%       p.addOptional('fskp', []);
%       p.addOptional('gidx', 0);
%       p.addOptional('gset', '');
%       p.addOptional('sidxs', []);
%       p.addOptional('clr', 'jet');
%       p.addOptional('cbar', 0);
%       p.addOptional('eidx', 25 : 100);
%       p.addOptional('midx', 200 : 300);
%       p.addOptional('lidx', 400 : 500);
%       p.addParameter('fidxs', 1 : 6);
%       p.addParameter('sav', 0);
%
% Output:
%   fnms:

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

%%
% Exclude seedlings
if ~isempty(sidxs)
    vprf = cellfun(@(x) x, vprf(sidxs), 'UniformOutput', 0);
    regr = cellfun(@(x) x, regr(sidxs), 'UniformOutput', 0);
end

% Exclude frames
fexcl = ~ismember(1 : ftrp, fskp);
ffix  = ftrp - numel(fskp);
if ~isempty(fskp)
    vprf = cellfun(@(x) x(:,fexcl), vprf, 'UniformOutput', 0);
    regr = cellfun(@(x) x(:,fexcl), regr, 'UniformOutput', 0);
end

% Exclude partial lower midline
bmax = bthr * ltrp;
vprf = cellfun(@(x) x(1 : bmax,:), vprf, 'UniformOutput', 0);
regr = cellfun(@(x) x(1 : bmax,:), regr, 'UniformOutput', 0);

% Adjust early-middle-late indices
eidx = round(epct * ffix);
midx = round(mpct * ffix);
lidx = round(lpct * ffix);

%
if iscell(t.Data.Genotype)
    gnm = t.Data.Experiment{1};
else
    gnm = t.Data.Genotype;
end
gttl = fixtitle(gnm);
ns   = numel(vprf);

[rlen , vlen] = averageTracking( ...
        t, sidxs, finc, ftrp, ltrp, lthr, smth, rep, vis, eidx);
% vl   = cat(3, vprf{:});
% rl   = cat(3, regr{:});
% alen = mean(vlen,3);
% elen = mean(rlen,3);

% ---------------------------------------------------------------------------- %
% Velocity map of upper regions
fnms = cell(6, 1);
cols = 6;
if ismember(ns, 1);                   cols = 1;
elseif ismember(ns, [2 , 4]);         cols = 2;
elseif ismember(ns, [3 , 5 , 6 , 9]); cols = 3;
elseif ns >= 6  && ns <= 16;          cols = 4;
elseif ns >= 17 && ns <= 24;          cols = 5;
end

rows = 5;
if ns <= 3;              rows = 1; end
if ns >= 4  && ns <= 8;  rows = 2; end
if ns >= 9  && ns <= 12; rows = 3; end
if ns >= 13 && ns <= 24; rows = 4; end

figclr(1);
for sidx = 1 : ns
    subplot(rows, cols, sidx);
    imagesc(vprf{sidx});
    colormap(clr);
    if cbar; colorbar('FontSize', 6); end
    xlabel('t', 'FontSize', 6, 'FontWeight', 'b');
    ylabel('L', 'FontSize', 6, 'FontWeight', 'b');
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
    if cbar; colorbar('FontSize', 6); end
    xlabel('t', 'FontSize', 6, 'FontWeight', 'b');
    ylabel('L', 'FontSize', 6, 'FontWeight', 'b');
    ttl = sprintf('%s [seedling %d]', gttl, sidx);
    title(ttl, 'FontSize', 8);

    ax          = gca;
    ax.FontSize = 8;
end
drawnow;

fnms{2} = sprintf('%s_regrmaps_%s_genotype%02d_%02dseedlings_%s', ...
    tdate, gnm, gidx, ns, gset);

% ---------------------------------------------------------------------------- %
epos = [eidx(1) , 3 , eidx(2) - eidx(1) , bmax - 3];
mpos = [midx(1) , 3 , midx(2) - midx(1) , bmax - 3];
lpos = [lidx(1) , 2 , lidx(2) - lidx(1) , bmax - 3];
bpos = epos;
if fblu; bpos = [fblu - 5 , 3 , 5 , bmax - 3]; end

rows = 1;
cols = 2;

% Map averaged Velocity and REGR
figclr(3);
subplot(rows, cols, 1);
imagesc(vlen);
colormap(clr);
if cbar; colorbar; end
rectangle('Position', bpos, 'EdgeColor', 'k', 'LineWidth', 3);
rectangle('Position', epos, 'EdgeColor', 'g', 'LineWidth', 3);
rectangle('Position', mpos, 'EdgeColor', 'r', 'LineWidth', 3);
rectangle('Position', lpos, 'EdgeColor', 'b', 'LineWidth', 3);

xlabel('t', 'FontSize', 10, 'FontWeight', 'b');
ylabel('L', 'FontSize', 10, 'FontWeight', 'b');
ttl = sprintf('Averaged Velocity\n%s [%d seedlings]', gttl, ns);
title(ttl, 'FontSize', 10);

subplot(rows, cols, 2);
imagesc(rlen);
colormap(clr);
if cbar; colorbar; end
rectangle('Position', bpos, 'EdgeColor', 'k', 'LineWidth', 3);
rectangle('Position', epos, 'EdgeColor', 'g', 'LineWidth', 3);
rectangle('Position', mpos, 'EdgeColor', 'r', 'LineWidth', 3);
rectangle('Position', lpos, 'EdgeColor', 'b', 'LineWidth', 3);

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
plt(mean(vlen(:,eidx),2), 'k-', 2);
hold on;
plt(mean(vlen(:,midx),2), 'r-', 2);
plt(mean(vlen(:,lidx),2), 'b-', 2);

xlabel('L', 'FontSize', 10, 'FontWeight', 'b');
ylabel('V', 'FontSize', 10, 'FontWeight', 'b');
lgn = {sprintf('%d - %d', eidx(1), eidx(2)) , ...
    sprintf('%d - %d', midx(1), midx(2)) , ...
    sprintf('%d - %d', lidx(1), lidx(2))};
ttl = sprintf('Averaged Velocity [top %d pixels]\n%s [%d seedlings]', ...
    lthr, gttl, ns);
legend(lgn, 'Location', 'southeast', 'FontWeight', 'b');
title(ttl, 'FontSize', 10);

subplot(rows, cols, 2);
plt(mean(rlen(:,eidx),2), 'k-', 2);
hold on;
plt(mean(rlen(:,midx),2), 'r-', 2);
plt(mean(rlen(:,lidx),2), 'b-', 2);

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
imagesc(vlen);
colormap(clr);
if cbar; colorbar; end
xlabel('t', 'FontSize', 10, 'FontWeight', 'b');
ylabel('L', 'FontSize', 10, 'FontWeight', 'b');
ttl = sprintf('Averaged Velocity\n%s [%d seedlings]', gttl, ns);
title(ttl, 'FontSize', 10);
drawnow;

fnms{5} = sprintf('%s_averagedtracking_map_velocity_%s_genotype%02d_%02dseedlings_%s', ...
    tdate, gnm, gidx, ns, gset);

% Map averaged REGR [unmarked]
figclr(6);
imagesc(rlen);
colormap(clr);
if cbar; colorbar; end
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
p.addOptional('ftrp', []);
p.addOptional('ltrp', []);
p.addOptional('lthr', 300);
p.addOptional('bthr', 1);
p.addOptional('fblu', 0);
p.addOptional('fskp', []);
p.addOptional('gidx', 0);
p.addOptional('gset', '');
p.addOptional('sidxs', []);
p.addOptional('clr', 'jet');
p.addOptional('cbar', 0);
p.addOptional('epct', [0.05 , 0.20]);
p.addOptional('mpct', [0.40 , 0.60]);
p.addOptional('lpct', [0.80 , 1.00]);

% Visualization Options
p.addParameter('sav', 0);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end

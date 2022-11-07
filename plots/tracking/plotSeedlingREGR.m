function fnm = plotSeedlingREGR(T, tnm, fidx, rnm)
%% plotSeedlingRegr: show REGR of each Seedling after tracking
%
% Usage:
%   plotSeedlingREGR(T, tnm, fidx, rnm)
%
% Input:
%   T: Tracking output
%   tnm: Name of tracking data (default 'tracking_regr'
%   fidx: Index to figure handle (default 1)
%   rnm: REGR version to plot [raw|rep] (default rep)
%
if nargin < 2; tnm  = 'tracking_regr'; end
if nargin < 3; fidx = 1;               end
if nargin < 4; rnm  = 'rep';           end

%
rr = cellfun(@(x) x.Output.REGR.(rnm), T, 'UniformOutput', 0);
ss = cellfun(@(x) x.Data.Seedlings, T);
tt = max(ss) - ss;
uu = arrayfun(@(x) [rr{x} , cell(1,tt(x))], 1 : numel(rr), 'UniformOutput', 0)';
vv = cat(2, uu{:});
ww = numel(vv);

%
rows = numel(ss);
cols = max(ss);

%
gnms  = cellfun(@(x) fixtitle(x.Data.Genotype), T, 'UniformOutput', 0);
gnms  = reshape(repmat(gnms, 1, cols)', 1, ww);
sidxs = repmat(1 : cols, 1, rows);
sidxs = arrayfun(@(x) x, sidxs, 'UniformOutput', 0);
ttls  = cellfun(@(x,y) sprintf('%s [Seedling %d]', x, y), ...
    gnms, sidxs, 'UniformOutput', 0);

figclr(fidx);
for i = 1 : ww
    subplot(rows,cols,i);
    imagesc(vv{i});
    colormap jet;
    title(ttls{i}, 'FontSize', 10);
    drawnow;
end

%
fnm = sprintf('%s_%s_%dgenotypes_%dseedlings_regr_%s', ...
    tdate, tnm, rows, ww, rnm);

end
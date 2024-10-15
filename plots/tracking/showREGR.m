function showREGR(gimgs, gmids, glens, uregr, ginfo, msample, fidx, sav, rdir)
%% showREGR: overlay seedling time lapse with REGR
%
% Usage:
%   showREGR(gimgs, gmids, glens, uregr, ginfo, msample, fidx, sav)
%
% Input:
%   gimgs:
%   gmids:
%   glens:
%   urer:
%   ginfo:
%   msample:
%   fidx:
%   sav:

%%
if nargin < 7; fidx = 1; end
if nargin < 8; sav  = 0; end

[gnm , gidx , sidx , cc , HC , ctrn , lwid , rdate] = getInfo(ginfo, uregr);

hc              = arrayfun(@(x) cc(x,:), HC, 'UniformOutput', 0);
[ltrp , nfrms]  = size(glens);

enm   = gnm(getDim(strfind(gnm, '_'), 1) + 1 : end);
gttl  = fixtitle(gnm);
rdir  = pprintf(sprintf('%s/regroverlays/%s/%s/%s/s%02d', ...
    rdir, rdate, enm, gnm, sidx));

% Set crop to highest point from time lapse
xlft = min(cellfun(@(x) min(x(:,1), [], 'all'), gmids)) - 100;
xrgt = max(cellfun(@(x) max(x(:,1), [], 'all'), gmids)) + 100;
ybot = size(gimgs{1},1);
ytop = min(cellfun(@(x) min(x(:,2), [], 'all'), gmids)) - 150;

%% Prepare Data for Plotting
gls = flipud(glens);
lis = arrayfun(@(x) getCutIndex(gls(:,x), ltrp), ...
    1 : size(gls,2), 'UniformOutput', 0)';
gms = cellfun(@(x) interpolateOutline(x, ltrp), gmids, 'UniformOutput', 0);
gms = cellfun(@(m,l) interpolateOutline(m(l,:), ltrp), ...
    gms, lis, 'UniformOutput', 0);

% Sample image along cut midline
[~ , mgrds] = cellfun(@(i,m) msample(i,m), gimgs, gms, 'UniformOutput', 0);
cms         = cellfun(@(y) flipud(arrayfun(@(x) ...
        [y.InnerData.eBnds(x,:) ; y.OuterData.eBnds(x,:)], ...
        1 : size(y.OuterData.eBnds,1), 'UniformOutput', 0)'), ...
        mgrds, 'UniformOutput', 0);

%% Plot REGR Overlays
figclr(fidx);
for frm = 1 : nfrms
    gi = gimgs{frm};
    cm = cms{frm};

    ttl = sprintf('%s (g%02d | s%02d)\nfrm %02d of %02d', ...
        gttl, gidx, sidx, frm, nfrms);

    figclr(fidx,1);
    myimagesc(gi);
    hold on;
    mm = arrayfun(@(x) plot(cm{x}(:,1), cm{x}(:,2), ...
        'LineStyle', '-', 'Color', hc{x,frm}, 'LineWidth', lwid), 1 : ltrp);
    %     for i = 1 : numel(mm); mm(i).Color = [mm(i).Color , 0.04]; end
    for i = 1 : numel(mm); mm(i).Color = [mm(i).Color , ctrn]; end
    xlim([xlft , xrgt]);
    ylim([ytop , ybot]);
    title(ttl, 'FontSize', 10, 'FontWeight', 'n');
    hold off;
    drawnow;

    %
    if sav
        fnm = sprintf('%s_regrseedling_%s_g%02d_s%02d_frm%02d', ...
            tdate, gnm, gidx, sidx, frm);
        saveFiguresJB(fidx, {fnm}, rdir);
    end
end
end


function [gnm , gidx , sidx , cc , HC , ctrn , lwid , rdate] = getInfo(ginfo, regr)
%% getInfo: retrieve figure information
% Data labels
try
    % From segmentation output
    gnm   = ginfo.GenotypeName;
    gidx  = ginfo.GenotypeIndex;
    sidx  = ginfo.SeedlingIndex;
catch
    % From tracking output
    gnm   = ginfo.Genotype;
    gidx  = ginfo.GenoIndex;
    sidx  = ginfo.SeedIndex;
end

% Colormap
if isfield(ginfo, 'ColorMap')
    cc = colormap(ginfo.ColorMap);
else
    cc = colormap('jet');
end

% Color vector
if isfield(ginfo, 'ColorVec')
    [~ , ~ , HC] = histcounts(regr, ginfo.ColorVec, 'Normalization', 'count');

    % Replace 0 with max value
    HC(HC == 0) = max(HC(:));
else
    [~ , ~ , HC] = histcounts(regr, 256, 'Normalization', 'count');
end

% Line Transparency
if isfield(ginfo, 'ColorTrans')
    ctrn = ginfo.ColorTrans;
else
    ctrn = 0.6;
end

% Line Width
if isfield(ginfo, 'LineWidth')
    lwid = ginfo.LineWidth;
else
    lwid = 2;
end

% Date for directory storage
if isfield(ginfo, 'Date')
    rdate = ginfo.Date;
else
    rdate = tdate;
end
end

function lidxs = getCutIndex(lens, ltrp)
%% getCutIndex: get midline indices at cut threshold
if sum(lens) == ltrp
    lidxs = 1 : ltrp;
else
    lidxs = [getDim(find(lens)', 1) - 1 ; find(lens)];
end
end
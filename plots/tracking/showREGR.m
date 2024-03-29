function showREGR(gimgs, gmids, glens, uregr, ginfo, msample, fidx, sav)
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

%
cc              = colormap('jet');
[~ , ~ , HC]    = histcounts(uregr, 256);
hc              = arrayfun(@(x) cc(x,:), HC, 'UniformOutput', 0);
[ltrp , nfrms]  = size(glens);

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

enm   = gnm(getDim(strfind(gnm, '_'), 1) + 1 : end);
gttl  = fixtitle(gnm);
rdir  = sprintf('regrseeds/%s/%s/s%02d', enm, gnm, sidx);

% Set crop to highest point from time lapse
xlft = min(cellfun(@(x) min(x(:,1), [], 'all'), gmids)) - 100;
xrgt = max(cellfun(@(x) max(x(:,1), [], 'all'), gmids)) + 100;
% ybot = max(cellfun(@(x) max(x(:,2), [], 'all'), gmids));
ybot = size(gimgs{1},1);
ytop = min(cellfun(@(x) min(x(:,2), [], 'all'), gmids)) - 150;

%%
figclr(fidx);
for frm = 1 : nfrms

    %
    gi = gimgs{frm};
    gm = gmids{frm};
    gl = flipud(glens(:,frm));

    %
    [~ , mgrd] = msample(gi,gm);
    gsz        = mgrd.OuterData.GridSize ./ [1 , 2];
    cout       = mgrd.OuterData.eCrds;
    cinn       = mgrd.InnerData.eCrds;
    cox        = reshape(cout(:,1)', gsz);
    cix        = reshape(cinn(:,1)', gsz);
    coy        = reshape(cout(:,2)', gsz);
    ciy        = reshape(cinn(:,2)', gsz);

    %
    co = interpolateOutline([cox(end,:) ; coy(end,:)]', ltrp);
    ci = interpolateOutline([cix(end,:) ; ciy(end,:)]', ltrp);
    
    try
        co = co([getDim(find(gl)', 1) - 1 ; find(gl)],:);
    catch
        co = unique(co([getDim(find(gl)', 1) ; find(gl)],:), 'rows', 'stable');
    end

    try
        ci = ci([getDim(find(gl)', 1) - 1 ; find(gl)],:);
    catch
        ci = unique(ci([getDim(find(gl)', 1) ; find(gl)],:), 'rows', 'stable');
    end

    co = flipud(interpolateOutline(co, ltrp + 1));
    ci = flipud(interpolateOutline(ci, ltrp + 1));
    %
    %     ll  = [gm(end,1) - 100 , gm(end,2) - 150];
    %     lr  = [gm(1,1)   + 150 , gm(1,2)];
    ttl = sprintf('%s (g%02d | s%02d)\nfrm %02d of %02d', ...
        gttl, gidx, sidx, frm, nfrms);

    %
    cm = arrayfun(@(x) [co(x-1,:) ; ci(x-1,:) ; ci(x,:) ; ...
        co(x,:) ; co(x-1,:)], 2 : size(co,1), 'UniformOutput', 0)';

    figclr(fidx,1);
    myimagesc(gi);
    hold on;
    mm = arrayfun(@(x) plot(cm{x}(:,1), cm{x}(:,2), ...
        'LineStyle', '-', 'Color', hc{x,frm}, 'LineWidth', 5), 1 : ltrp);
    for i = 1 : numel(mm); mm(i).Color = [mm(i).Color , 0.02]; end
    %     xlim([ll(1) , lr(1)]);
    %     ylim([ll(2) , lr(2)]);
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
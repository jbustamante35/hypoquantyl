function fnms = showVelandREGR(uvel, uregr, figs, enm, nsdls, sav, mdir, asz, alims)
%% showVelandREGR: plot velocity, velocity profile, regr and regr profile
%
% Usage:
%   fnms = showVelandREGR(uvel, uregr, figs, enm, nsdls, sav, mdir, asz)
%
% Input:
%   uvel: velocity map
%   uregr: regr map
%   figs: figures indices to plot onto [default 1 : 4]
%   enm: Experiment name
%   nsdls: number of seedlings averaged [default 0]
%   sav: boolean save each figure 
%   mdir: directory to save into [default 'regrmaps']
%   asz: font size for all text [default 20]
%   alims: limits for velocity and regr colormaps [default [0,3],[0.003,0.004]
%
% Output:
%   fnms: filenames for outputted figures

if nargin < 3; figs  = 1 : 4;                       end
if nargin < 4; enm   = 'light_genotype';            end
if nargin < 5; nsdls = 0;                           end
if nargin < 6; sav   = 0;                           end
if nargin < 7; mdir  = 'regrmaps';                  end
if nargin < 8; asz   = 20;                          end
if nargin < 9; alims = {[0 , 3] ; [0.003 , 0.004]}; end

lttl = sprintf('Distance from Apex (mm)');
% ltix = 0 : 250 : 1000;
% llbl = 0 : 2.5 : 10;
ltix = 0 : 100 : 1000;
llbl = 0 :  1  : 10;

fttl = 'Time (h)';
% ftix = 12 : 24 : 96;
% flbl = 1 : 2 : 8;
ftix = 0 : 12 : 96;
flbl = 0 : 1 : 8;

vttl = sprintf('Velocity Map');
uttl = sprintf('Velocity Profile');
vtax = sprintf('Velocity (mm / h)');
vtix = 0 : 15 : 50;
vtix = vlims(1) : (vlims(2) / 6) : vlims(2);
vlbl = vtix;

rttl  = sprintf('REGR Map');
qttl  = sprintf('REGR Profile');
rtax  = sprintf('Relative Elemental Growth Rate (%% / h)');
rtix  = 0 : 1 : rmax;
% rtix  = 0 : 1 : 4;
rtix = rlims(1) : (rlims(2) / 6) : rlims(2);
rlbl  = rtix;

vtix  = 0 : 0.5 : 3;
vlims = [0 , 3];
rtix  = 0 : 0.001 : 0.06;
rlims = [0.0003 , 0.004];

efrms = 1 : 8;
mfrms = 20 : 30;
lfrms = 65 : 75;

% Velocity Map
if figs(1)
    figclr(figs(1));
    imagesc(uvel); colormap jet; axis square; hold on; colorbar;
    clim([vtix(1) , vtix(end)]);
    ylabel(lttl, 'FontSize', asz); yticks(ltix); yticklabels(llbl);
    xlabel(fttl, 'FontSize', asz); xticks(ftix); xticklabels(flbl);
    jlabel(vtax, 'FontSize', asz); jticks(vtix); jticklabels(vlbl);
    title(vttl, 'FontSize', asz, 'FontWeight', 'n');
    setAxis(figs(1), asz, 'n', 1);
    set(gca, 'TickDir', 'out');
end

% REGR Map
if figs(2)
    figclr(figs(2));
    imagesc(uregr); colormap jet; axis square; hold on; colorbar;
    clim([rtix(1) , rtix(end)]);
    ylabel(lttl, 'FontSize', asz); yticks(ltix); yticklabels(llbl);
    xlabel(fttl, 'FontSize', asz); xticks(ftix); xticklabels(flbl);
    jlabel(rtax, 'FontSize', asz); jticks(rtix); jticklabels(rlbl);
    title(rttl, 'FontSize', asz, 'FontWeight', 'n');
    setAxis(figs(2), asz, 'n', 1);
    set(gca, 'TickDir', 'out');
end

% Velocity Profile
if figs(3)
    figclr(figs(3));
    plt(mean(uvel(:, efrms), 2), 'k-', 4);
    hold on;
    plt(mean(uvel(:, mfrms), 2), 'r-', 4);
    plt(mean(uvel(:, lfrms), 2), 'b-', 4);
    axis square;
    xlabel(lttl, 'FontSize', asz); xticks(ltix); xticklabels(llbl);
    ylabel(vtax, 'FontSize', asz); yticks(vtix); yticklabels(vlbl);
    ylim([vlbl(1) , vlbl(end)]);
    title(uttl, 'FontSize', asz, 'FontWeight', 'n');
    setAxis(figs(3), asz, 'n');
    set(gca, 'TickDir', 'out');
end

% REGR Profile
if figs(4)
    figclr(figs(4));
    plt(mean(uregr(:, efrms), 2), 'k-', 4);
    hold on;
    plt(mean(uregr(:, mfrms), 2), 'r-', 4);
    plt(mean(uregr(:, lfrms), 2), 'b-', 4);
    axis square;
    xlabel(lttl, 'FontSize', asz); xticks(ltix); xticklabels(llbl);
    ylabel(rtax, 'FontSize', asz); yticks(rtix); yticklabels(rlbl);
    ylim([rlbl(1) , rlbl(end)]);
    title(qttl, 'FontSize', asz, 'FontWeight', 'n');
    setAxis(figs(4), asz, 'n');
    set(gca, 'TickDir', 'out');
end

drawnow;

%
fnms{1} = sprintf('%s_%s_%02dseedlings_velocitymap',     tdate, enm, nsdls);
fnms{2} = sprintf('%s_%s_%02dseedlings_regrmap',         tdate, enm, nsdls);
fnms{3} = sprintf('%s_%s_%02dseedlings_velocityprofile', tdate, enm, nsdls);
fnms{4} = sprintf('%s_%s_%02dseedlings_regrprofile',     tdate, enm, nsdls);

if sav
    if ~isfolder(mdir); mkdir(mdir); end
    saveFiguresJB(figs, fnms(1 : 4), mdir);
end
end
function fnms = showTrackingResults_remote(T, gimgs, gmids, varargin)
%% showTrackingResults_remote
%
% Usage:
%   fnms = showTrackingResults_remote(T, gimgs, gmids, fidxs, varargin)
%
% Input:
%   T: output structure from processing tracking data
%   gimgs: grayscale images from analysis
%   gmids: raw midlines inputted to tracking
%   fidxs: figure handle indices [default 1 : 6]
%   varargin: various options
%       D: frames to split time course [default 4 arrays]
%       apcts: indices to display (default [1 : npcts : pintrp , pintrp])
%
% Output:
%   fnms: figure names
%

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

%%
enm  = T.Data.Experiment;
gnm  = T.Data.Genotype;
gidx = T.Data.GenoIndex;

%
P               = T.Output.Tracking.raw;
[npcts , nsdls] = size(P);

%
nfrms  = numel(gimgs);
fwin   = T.Data.Window;
nwin   = numel(fwin);
ipcts  = T.Data.Percentages;
pintrp = size(T.Output.Arclength.interp,1);

%
if isempty(D)
    d1 = 1 : 15;
    d2 = d1(end) + 1 : 30;
    d3 = d2(end) + 1 : 50;
    d4 = d3(end) + 1 : nwin;
    D  = {d1 , d2 , d3 , d4};
end

%% Prep data
w     = cellfun(@(x) fiberBundle1d(x), gmids);
ws    = w(fwin,:);
wt    = w(fwin + skp,:);
wimgs = gimgs(fwin);
wmids = gmids(fwin,:);
apcts = [1 : npcts : pintrp , pintrp];
apcts = [1 : 5 : pintrp , pintrp];

%
pism = T.Output.Arclength.ismooth;
Ls   = T.Output.Tracking.lengths;
vism = T.Output.Velocity.ismooth;
vpsm = T.Output.Profile.interp;

%
fnms  = arrayfun(@(x) sprintf('%s_blank', tdate), 1 : 6, 'UniformOutput', 0)';
fidx1 = fidxs(1);
fidx2 = fidxs(2);
fidx3 = fidxs(3);
fidx4 = fidxs(4);
fidx5 = fidxs(5);
fidx6 = fidxs(6);

%% Source and Target midlines on images
figclr(fidx1);
for frm = 1 : dbug : nwin - 1
    xsrc = arrayfun(@(x) ws(frm,x).evalCurve(ipcts, 'normalized'), ...
        1 : nsdls, 'UniformOutput', 0);
    xsrc = cellfun(@(y) arrayfun(@(x) y(x,:), ...
        (1 : numel(ipcts))', 'UniformOutput', 0), xsrc, 'UniformOutput', 0);
    xsrc = cat(2, xsrc{:});

    %     xtrg = arrayfun(@(x) x.tpt(frm,:), P, 'UniformOutput', 0);
    xtrg = arrayfun(@(x) x.percent(frm), P);
    xtrg = arrayfun(@(y) arrayfun(@(x) wt(frm,y).evalCurve(x, 'normalized'), ...
        xtrg(:,y), 'UniformOutput', 0), 1 : nsdls, 'UniformOutput', 0);
    xtrg = cat(2, xtrg{:});

    xdst = cellfun(@(x,y) [x ; y], xsrc, xtrg, 'UniformOutput', 0);

    myimagesc(wimgs{frm});
    hold on;
    cellfun(@(x) plt(x, 'r-', 1), wmids(frm,:));
    cellfun(@(x) plt(x, 'b-', 1), wmids(frm + 1,:));
    cellfun(@(x) plt(x, 'g.', 10), xsrc);
    cellfun(@(x) plt(x, 'y.', 10), xtrg);
    cellfun(@(x) plt(x, 'w-', 1), xdst);

    ttl = sprintf('Tracking [Frame %d of %d]', frm, nwin);
    title(ttl, 'FontSize', 10);
    hold off;

    drawnow;

    fnms{fidx1} = sprintf('%s_arclength_%dpoints_tracking_frame%02dof%02d', ...
        tdate, npcts, frm, nwin);

    if sav
        tdir = sprintf('tracking_results/%s/tracking', gnm);
        saveFiguresJB(fidx1, fnms(fidx1), tdir);
    end
end

% ---------------------------------------------------------------------------- %
%% Iterate through each Seedling
% plen = T.Output.Arclength.raw;
% vlen = T.Output.Velocity.raw;
for sidx = 1 : nsdls
    % ArcLengths through frames
    figclr(fidx2);
    hold on;
    cellfun(@(x) plt(x, '-', 2), pism(apcts, sidx));
    %     cellfun(@(x) plt(x, '-', 2), plen([1 : 2 : npcts , npcts], sidx));
    plt(Ls{sidx}, 'k--', 2);

    ttl = sprintf('ArcLength through %d frames [%d of %d points]', ...
        nwin, numel(apcts), pintrp);
    title(ttl, 'FontSize', 10);
    ylabel('L (ArcLength from tip)', 'FontWeight', 'b');
    xlabel('t (frames)', 'FontWeight', 'b');

    fnms{fidx2} = sprintf('%s_arclength_%dpoints_%dframes_arclength', ...
        tdate, npcts, nwin);

    if sav
        tdir = sprintf('tracking_results/%s/seedling%02d/', ...
            gnm, sidx);
        saveFiguresJB(fidx2, fnms(fidx2), tdir);
    end

    % ---------------------------------------------------------------------------- %
    % Veclocity through frames
    figclr(fidx3);
    hold on;
    cellfun(@(x) plt(x, '-', 2), vism(apcts,sidx));
    %     cellfun(@(x) plt(x, '-', 2), vlen([1 : 2 : npcts , npcts],sidx));
    ttl = sprintf('Velocity through %d frames [%d of %d points]', ...
        nwin, numel(apcts), pintrp);
    title(ttl, 'FontSize', 10);
    ylabel('Velocity (pix / frm)', 'FontWeight', 'b');
    xlabel('t (frames)', 'FontWeight', 'b');

    fnms{fidx3} = sprintf('%s_arclength_%dpoints_%dframes_velocity', ...
        tdate, npcts, nwin);

    if sav
        tdir = sprintf('tracking_results/%s/seedling%02d/', ...
            gnm, sidx);
        saveFiguresJB(fidx3, fnms(fidx3), tdir);
    end

    % ---------------------------------------------------------------------------- %
    % Velocity at arclength at each frame [movie]
    figclr(fidx4);
    minL = 0;
    maxL = max(cat(1, pism{:,sidx}));
    minV = min(cat(1, vism{:,sidx}));
    maxV = max(cat(1, vism{:,sidx}));
    for frm = 1 : dbug : nwin
        plt([0 , 0], 'k.', 1);
        hold on;
        cellfun(@(x) plt(x(frm,:), 'k.', 5), vpsm(:,sidx));
        ttl = sprintf('Velocity at %d Locations [frm = %d]', pintrp, frm);
        title(ttl, 'FontSize', 10);
        ylabel('Velocity (pix / frm)', 'FontWeight', 'b');
        xlabel('L (pix) [ArcLength from tip]', 'FontWeight', 'b');
        xlim([minL , maxL]);
        ylim([minV , maxV]);
        hold off;
        drawnow;

        fnms{fidx4} = sprintf('%s_arclength_%dpoints_velocity_frame%02dof%02d', ...
            tdate, npcts, frm, nfrms);

        if sav
            tdir = sprintf('tracking_results/%s/seedling%02d/velocity', ...
                gnm, sidx);
            saveFiguresJB(fidx4, fnms(fidx4), tdir);
        end
    end

    % ---------------------------------------------------------------------------- %
    % All velocities along arclength
    figclr(fidx5);
    hold on;
    cellfun(@(x) plt(x, 'k.', 5), vpsm(:,sidx));
    ttl = sprintf('Velocity at all Locations [%d frames]', nfrms);
    title(ttl, 'FontSize', 10);
    ylabel('Velocity', 'FontWeight', 'b');
    xlabel('L [ArcLength from tip]', 'FontWeight', 'b');
    drawnow;

    fnms{fidx5} = sprintf('%s_arclength_%dpoints_%02dframes_velocity_all', ...
        tdate, npcts, nwin);

    if sav
        tdir = sprintf('tracking_results/%s/seedling%02d/', ...
            gnm, sidx);
        saveFiguresJB(fidx5, fnms(fidx5), tdir);
    end

    % ---------------------------------------------------------------------------- %
    % Show velocity at arclengths from sub-divisions of frames
    figclr(fidx6);
    hold on;
    plt(vpsm{1,sidx}(D{4}(1:2),:), 'k-', 3);
    plt(vpsm{1,sidx}(D{4}(1:2),:), 'r-', 3);
    plt(vpsm{1,sidx}(D{4}(1:2),:), 'b-', 3);
    plt(vpsm{1,sidx}(D{4}(1:2),:), 'g-', 3);
    cellfun(@(x) plt(x(D{1},:), 'k.', 5), vpsm(:,sidx));
    cellfun(@(x) plt(x(D{2},:), 'r.', 5), vpsm(:,sidx));
    cellfun(@(x) plt(x(D{3},:), 'b.', 5), vpsm(:,sidx));
    cellfun(@(x) plt(x(D{4},:), 'g.', 5), vpsm(:,sidx));

    lgn = cellfun(@(x) sprintf('Frames %d-%d', x(1), x(end)), ...
        D, 'UniformOutput', 0);
    ttl = sprintf('Velocity along Midline with Subdivisions [%d frames]', ...
        nfrms);
    legend(lgn, 'FontSize', 10, 'FontWeight', 'b', 'Location', 'southeast');
    title(ttl, 'FontSize', 10);
    ylabel('Velocity', 'FontWeight', 'b');
    xlabel('L [ArcLength from tip]', 'FontWeight', 'b');
    drawnow;

    fnms{fidx6} = sprintf('%s_arclength_%dpoints_%02dframes_velocity_subdivisions', ...
        tdate, npcts, nwin);

    if sav
        tdir = sprintf('tracking_results/%s/seedling%02d/', ...
            gnm, sidx);
        saveFiguresJB(fidx6, fnms(fidx6), tdir);
    end
end

% ---------------------------------------------------------------------------- %
%% Show velocity at arclengths from sub-divisions of frames

end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
p = inputParser;

% Misc Options
p.addOptional('ipcts', 0 : 0.05 : 1);
p.addOptional('ifrm', []);
p.addOptional('ffrm', []);
p.addOptional('skp', 1);
p.addOptional('dbug', 1);
p.addOptional('D', []);

% Visualization Options
p.addParameter('fidxs', 1 : 6);
p.addParameter('sav', 0);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end

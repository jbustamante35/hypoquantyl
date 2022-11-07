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
%       pver: processed points to show [raw|rep] (default rep)
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
% dintrp   = numel(fwin);
ipcts  = T.Data.Percentages;
% pintrp = size(T.Output.Tracking.raw, 1);

[pintrp , dintrp] = size(T.Output.Arclength.raw{1});
[fintrp , eintrp] = size(T.Output.REGR.(pver){1});

%
if isempty(D)
    dwin = 1 : round(dintrp / 4) : dintrp;
    d1 = dwin(1) : dwin(2) - 1;
    d2 = dwin(2) : dwin(3) - 1;
    d3 = dwin(3) : dwin(end) - 1;
    d4 = dwin(end) : dintrp;
    D = {d1 , d2 , d3 , d4};

    ewin = 1 : round(eintrp/4) : eintrp;
    e1 = ewin(1) : ewin(2) - 1;
    e2 = ewin(2) : ewin(3) - 1;
    e3 = ewin(3) : ewin(end) - 1;
    e4 = ewin(end) : eintrp;
    E  = {e1 , e2 , e3 , e4};

    %     d1 = 1 : 15;
    %     d2 = d1(end) + 1 : 30;
    %     d3 = d2(end) + 1 : 50;
    %     d4 = d3(end) + 1 : nwin;
    %     D  = {d1 , d2 , d3 , d4};
end

%% Prep data
w     = cellfun(@(x) fiberBundle1d(x), gmids);
ws    = w(fwin,:);
wt    = w(fwin + skp,:);
wimgs = gimgs(fwin);
wmids = gmids(fwin,:);
% apcts = [1 : npcts : pintrp , pintrp];
dpcts = 1 : round(pintrp / 4) : pintrp;
fpcts = [1 : round(fintrp / 4) : fintrp , fintrp];
tpcts = [1 : round(dintrp / 4) : dintrp , dintrp];

%
% aver = sprintf('l%s', pver);
vver = sprintf('t%s', pver);
aism = T.Output.Arclength.(pver);
Ls   = T.Output.Tracking.lengths;
% aism = T.Output.Arclength.(aver);
% Li   = T.Output.Tracking.ilens;
vism = T.Output.Velocity.(vver);
vpsm = T.Output.Profile.(pver);
regr = T.Output.REGR.(pver);

%
fnms  = arrayfun(@(x) sprintf('%s_blank', tdate), 1 : 6, 'UniformOutput', 0)';
fidx1 = fidxs{1};
fidx2 = fidxs{2};
fidx3 = fidxs{3};
fidx4 = fidxs{4};
fidx5 = fidxs{5};
fidx6 = fidxs{6};
fidx7 = fidxs{7};


%% Source and Target midlines on images
if fidx1
    figclr(fidx1);
    for frm = 1 : dbug : dintrp - 1
        xsrc = arrayfun(@(x) ws(frm,x).evalCurve(ipcts, 'normalized'), ...
            1 : nsdls, 'UniformOutput', 0);
        xsrc = cellfun(@(y) arrayfun(@(x) y(x,:), ...
            (1 : numel(ipcts))', 'UniformOutput', 0), xsrc, 'UniformOutput', 0);
        xsrc = cat(2, xsrc{:});

        xtrg = arrayfun(@(x) x.percent(frm), P);
        xtrg = arrayfun(@(y) arrayfun(@(x) wt(frm,y).evalCurve(x, 'normalized'), ...
            xtrg(:,y), 'UniformOutput', 0), 1 : nsdls, 'UniformOutput', 0);
        xtrg = cat(2, xtrg{:});

        xdst = cellfun(@(x,y) [x ; y], xsrc, xtrg, 'UniformOutput', 0);

        tends  = cellfun(@(x) x(end,:), ...
            wmids(frm,:), 'UniformOutput', 0);
        tspots = cellfun(@(x) x + soff, tends, 'UniformOutput', 0);
        tstrs  = arrayfun(@(x) sprintf('%d', x), ...
            1 : numel(tspots), 'UniformOutput', 0);

        %
        myimagesc(wimgs{frm});
        hold on;
        plt(xsrc{1,1}, 'g.', 10);
        plt(xtrg{1,1}, 'y.', 10);
        cellfun(@(x) plt(x, 'r-', 1), wmids(frm,:));
        cellfun(@(x) plt(x, 'b-', 1), wmids(frm + 1,:));
        cellfun(@(x) plt(x, 'g.', 10), xsrc);
        cellfun(@(x) plt(x, 'y.', 10), xtrg);
        cellfun(@(x) plt(x, 'w-', 1), xdst);

        cellfun(@(t,s) text(t(1), t(2), s, 'FontSize', 10, 'Color', 'r'), ...
            tspots, tstrs);

        lgn = {'Source' , 'Target'};
        ttl = sprintf('Tracking [Frame %d of %d]', frm, dintrp);
        legend(lgn, 'FontSize', 10, 'Location', 'southeastoutside');
        title(ttl, 'FontSize', 10);
        hold off;

        drawnow;

        fnms{fidx1} = sprintf('%s_%dpoints_frame%02dof%02d_midlines', ...
            tdate, npcts, frm, dintrp);

        if sav
            tdir = sprintf('tracking_results/%s/%s/tracking', enm, gnm);
            saveFiguresJB(fidx1, fnms(fidx1), tdir);
        end
    end
end

% ---------------------------------------------------------------------------- %
%% Iterate through each Seedling
for sidx = 1 : nsdls
    % ArcLengths through frames
    if fidx2
        figclr(fidx2);
        hold on;
        %         plt(aism{sidx}(fpcts,:)', '-', 2);
        %         plt(Li{sidx}, 'k--', 2);
        plt(aism{sidx}(dpcts,:)', '-', 2);
        plt(Ls{sidx}, 'k--', 2);

        ttl = sprintf('ArcLength through %d frames [%d of %d points]', ...
            dintrp, numel(dpcts), pintrp);
        title(ttl, 'FontSize', 10);
        ylabel('L (ArcLength from tip)', 'FontWeight', 'b');
        xlabel('t (frames)', 'FontWeight', 'b');

        lgn = arrayfun(@(x) sprintf('%d', x), dpcts, 'UniformOutput', 0);
        legend(lgn, ...
            'FontSize', 10, 'FontWeight', 'b', 'Location', 'southeastoutside');

        fnms{fidx2} = sprintf('%s_%dpoints_%dframes_arclength', ...
            tdate, npcts, dintrp);

        if sav
            tdir = sprintf('tracking_results/%s/%s/seedling%02d/', ...
                enm, gnm, sidx);
            saveFiguresJB(fidx2, fnms(fidx2), tdir);
        end
    end

    % ---------------------------------------------------------------------------- %
    % Veclocity through frames
    if fidx3
        figclr(fidx3);
        hold on;
        plt(vism{sidx}(fpcts,:)', '-', 2);

        ttl = sprintf('Velocity through %d frames [%d of %d points]', ...
            dintrp, numel(tpcts), pintrp);
        title(ttl, 'FontSize', 10);
        ylabel('Velocity (pix / frm)', 'FontWeight', 'b');
        xlabel('t (frames)', 'FontWeight', 'b');

        lgn = arrayfun(@(x) sprintf('%d', x), dpcts, 'UniformOutput', 0);
        legend(lgn, ...
            'FontSize', 10, 'FontWeight', 'b', 'Location', 'southeastoutside');

        fnms{fidx3} = sprintf('%s_%dpoints_%dframes_velocity', ...
            tdate, npcts, dintrp);

        if sav
            tdir = sprintf('tracking_results/%s/%s/seedling%02d/', ...
                enm, gnm, sidx);
            saveFiguresJB(fidx3, fnms(fidx3), tdir);
        end
    end

    % ---------------------------------------------------------------------------- %
    % Velocity at arclength at each frame [movie]
    if fidx4
        figclr(fidx4);
        minL = 0;
        maxL = max(aism{sidx}(:));
        minV = min(vism{sidx}(:));
        maxV = max(vism{sidx}(:));
        for frm = [1 : dbug : dintrp , dintrp]
            plt([0 , 0], 'k.', 1);
            hold on;
            cellfun(@(x) plt(x{frm}, 'k.', 5), vpsm(:,sidx));
            ttl = sprintf('Velocity at %d Locations [frm = %d]', pintrp, frm);
            title(ttl, 'FontSize', 10);
            ylabel('Velocity (pix / frm)', 'FontWeight', 'b');
            xlabel('L (pix) [ArcLength from tip]', 'FontWeight', 'b');
            xlim([minL , maxL]);
            ylim([minV , maxV]);
            hold off;
            drawnow;

            fnms{fidx4} = sprintf('%s_%dpoints_velocity_frame%02dof%02d', ...
                tdate, npcts, frm, dintrp);

            if sav
                tdir = sprintf('tracking_results/%s/%s/seedling%02d/velocity', ...
                    enm, gnm, sidx);
                saveFiguresJB(fidx4, fnms(fidx4), tdir);
            end
        end
    end

    % ---------------------------------------------------------------------------- %
    % All velocities along arclength
    if fidx5
        figclr(fidx5);
        hold on;
        cellfun(@(x) plt(x, 'k.', 5), vpsm{sidx});
        ttl = sprintf('Velocity at all Locations [%d frames]', nfrms);
        title(ttl, 'FontSize', 10);
        ylabel('Velocity', 'FontWeight', 'b');
        xlabel('L [ArcLength from tip]', 'FontWeight', 'b');
        drawnow;

        fnms{fidx5} = sprintf('%s_%dpoints_%02dframes_velocity_all', ...
            tdate, npcts, dintrp);

        if sav
            tdir = sprintf('tracking_results/%s/%s/seedling%02d/', ...
                enm, gnm, sidx);
            saveFiguresJB(fidx5, fnms(fidx5), tdir);
        end
    end

    % ---------------------------------------------------------------------------- %
    % Show velocity at arclengths from sub-divisions of frames
    if fidx6
        figclr(fidx6);
        hold on;
        plt(vpsm{sidx}{D{1}(1)}(1,:), 'k-', 3);
        plt(vpsm{sidx}{D{2}(1)}(1,:), 'r-', 3);
        plt(vpsm{sidx}{D{3}(1)}(1,:), 'b-', 3);
        plt(vpsm{sidx}{D{4}(1)}(1,:), 'g-', 3);
        cellfun(@(x) plt(x, 'k.', 5), vpsm{sidx}(D{1}));
        cellfun(@(x) plt(x, 'r.', 5), vpsm{sidx}(D{2}));
        cellfun(@(x) plt(x, 'b.', 5), vpsm{sidx}(D{3}));
        cellfun(@(x) plt(x, 'g.', 5), vpsm{sidx}(D{4}));

        lgn = cellfun(@(x) sprintf('Frames %d-%d', x(1), x(end)), ...
            D, 'UniformOutput', 0);
        ttl = sprintf('Velocity along Midline with Subdivisions [%d frames]', ...
            nfrms);
        legend(lgn, ...
            'FontSize', 10, 'FontWeight', 'b', 'Location', 'southeastoutside');
        title(ttl, 'FontSize', 10);
        ylabel('Velocity', 'FontWeight', 'b');
        xlabel('L [ArcLength from tip]', 'FontWeight', 'b');
        drawnow;

        fnms{fidx6} = sprintf('%s_%dpoints_%02dframes_velocity_subdivisions', ...
            tdate, npcts, dintrp);

        if sav
            tdir = sprintf('tracking_results/%s/%s/seedling%02d/', ...
                enm, gnm, sidx);
            saveFiguresJB(fidx6, fnms(fidx6), tdir);
        end
    end

    % ---------------------------------------------------------------------------- %
    % Show REGR at arclengths from sub-divisions of frames
    if fidx7
        figclr(fidx7);
        hold on;
        plt(mean(regr{sidx}(:,E{1})), 'k-', 2);
        plt(mean(regr{sidx}(:,E{2})), 'r-', 2);
        plt(mean(regr{sidx}(:,E{3})), 'b-', 2);
        plt(mean(regr{sidx}(:,E{4})), 'g-', 2);

        lgn = cellfun(@(x) sprintf('Frames %d-%d', x(1), x(end)), ...
            D, 'UniformOutput', 0);
        ttl = sprintf('REGR along Midline with Subdivisions [%d frames]', ...
            nfrms);
        legend(lgn, ...
            'FontSize', 10, 'FontWeight', 'b', 'Location', 'southeastoutside');
        title(ttl, 'FontSize', 10);
        ylabel('REGR', 'FontWeight', 'b');
        xlabel('L [ArcLength from tip]', 'FontWeight', 'b');

        drawnow;

        fnms{fidx7} = sprintf('%s_%dpoints_%02dframes_regr_subdivisions', ...
            tdate, npcts, dintrp);

        if sav
            tdir = sprintf('tracking_results/%s/%s/seedling%02d/', ...
                enm, gnm, sidx);
            saveFiguresJB(fidx7, fnms(fidx7), tdir);
        end
    end
end
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
p.addOptional('pver', 'rep');

% Visualization Options
% p.addParameter('fidxs', 1 : 7);
p.addParameter('fidxs', {1 , 2 , 3 , [] , [] , [] , 7}); % Skip 4,5,6
p.addParameter('sav', 0);
p.addParameter('soff', [-50 , -30]);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end

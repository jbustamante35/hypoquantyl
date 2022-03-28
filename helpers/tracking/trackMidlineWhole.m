function [fa , tpt , fnm] = trackMidlineWhole(gimgs, gmids, ipcts, ifrm, ffrm, skp, fidx, sav)
%% trackMidlineWhole: Follow all points through all frames
%
%
% Usage:
%   [fa , tpt , fnm] = trackMidlineWhole(gimgs, gmids, ...
%       ipcts, ifrm, ffrm, skp, fidx, sav)
%
% Input:
%   gimgs:
%   gmids:
%   ipcts:
%   ifrm:
%   ffrm:
%   skp:
%   fidx:
%   sav:
%
% Output:
%   fa:
%   tpt:
%   fnm:
%

%%
if nargin < 3; ipcts = 0 : 1 / (size(gmids{1},1)) : 1; end
if nargin < 4; ifrm  = 1;                              end
if nargin < 5; ffrm  = numel(gimgs) - 1;               end
if nargin < 6; skp   = 1;                              end
if nargin < 7; fidx  = 0;                              end
if nargin < 8; sav   = 0;                              end

%
wsrcs = ifrm : skp : ffrm; % With skipping
if wsrcs(end) ~= ffrm; wsrcs = [wsrcs , ffrm]; end

%
isrcs = gimgs(wsrcs);
itrgs = gimgs(wsrcs + skp);
msrcs = gmids(wsrcs);
mtrgs = gmids(wsrcs + skp);
nfrms = numel(isrcs);
npcts = numel(ipcts);

%
if fidx
    figclr(fidx);
    w  = cellfun(@(x) fiberBundle1d(x), gmids);
    ws = w(wsrcs);
    wt = w(wsrcs + skp);
end

%%
% 1) Get percentages --> set points along source midline
% 2) Track matching points from source to target midline
% 3) Iterate to next frame --> Repeat 1-2
[fa , tpt] = deal(cell(nfrms, npcts));
for frm = wsrcs
    fsrc = frm;
    ftrg = fsrc + 1;
    for pct = 1 : npcts
        % Initial percentages to evaluate first frame
        ipct = ipcts(pct);

        % Set lower bound to 0 or previous percentage
        if pct > 1; ppct = ipcts(pct - 1); else; ppct = []; end

        %
        t = tic;
        fprintf('Finding matching point for point %.04f on frames %d and %d...', ...
            ipct, fsrc, ftrg);
        [fa{frm,pct} , tpt{frm,pct}] = domainFinder(isrcs{frm}, itrgs{frm}, ...
            msrcs{frm}, mtrgs{frm}, ipct, 'ppct', ppct, 'fidx', fidx);
        fprintf('DONE! (target at %.04f) [%.03f sec]\n', ...
            fa{frm,pct}(1), toc(t));
    end

    %% Show all tracked points from this frame
    if fidx
        fnm = showTrackingFrame(ipcts, cat(1, fa{frm,:}), ws(frm), wt(frm), ...
            npcts, isrcs{frm}, msrcs{frm}, mtrgs{frm}, fsrc, ftrg, fidx, sav);
    end
end

%% Remove empty cells [if not starting at 1 and ending at nfrms]
fa  = fa(~cellfun(@isempty,fa(:,1)),:);
tpt = tpt(~cellfun(@isempty,tpt(:,1)),:);
end

function fnm = showTrackingFrame(tsrcs, fa, ws, wt, npcts, isrc, msrc, mtrg, fsrc, ftrg, fidx, sav)
%% showTrackingFrame:
%
if nargin < 11; fidx = 1; end
if nargin < 12; sav  = 0; end

ttrgs = fa(:,1);
psrcs = ws.evalCurve(tsrcs, 'normalized');
ptrgs = wt.evalCurve(ttrgs, 'normalized');
pmtcs = arrayfun(@(x) [psrcs(x,:) ; ptrgs(x,:)], ...
    (1 : npcts)', 'UniformOutput', 0);

myimagesc(isrc);
hold on;
plt(msrc, 'r-', 2);
plt(mtrg, 'b-', 2);
plt(psrcs, 'g.', 10);
plt(ptrgs, 'y.', 10);
cellfun(@(x) plt(x, 'w-', 2), pmtcs);

ttl = sprintf('Frame %d to %d [%d Points]', fsrc, ftrg, npcts);
title(ttl, 'FontSize', 10);

drawnow;
hold off;

%
fnm = [];
if sav
    fdir = 'tracking/frames';
    fnm  = sprintf('%s_frame%02dto%02d_%03dpoints', ...
        tdate, fsrc, ftrg, npcts);
    saveFiguresJB(fidx, {fnm}, fdir);
end
end

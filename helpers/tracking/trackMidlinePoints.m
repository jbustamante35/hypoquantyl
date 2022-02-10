function [fa , tpt] = trackMidlinePoints(isrcs, itrgs, msrcs, mtrgs, ipcts, ifrm, ffrm, fidx, sav)
%% trackMidlinePoints: Follow set of points on frame 1 through all frames
%
%
% Usage:
%   [fa , tpt] = trackMidlinePoints(isrc, itrg, msrc, mtrg, ...
%       ipcts, ifrm, ffrm, fidx, sav)
%
% Input:
%   isrc:
%   itrg:
%   msrc:
%   mtrg:
%   ipcts:
%   ifrm:
%   ffrm:
%   fidx:
%   sav
%
% Output:
%   fa:
%   tpt:
%

%%
if nargin < 5; ipcts = 0 : 1 / (size(msrcs{1},1)) : 1; end
if nargin < 6; ifrm  = 1;                              end
if nargin < 7; ffrm  = numel(isrcs);                   end
if nargin < 8; fidx  = 0;                              end
if nargin < 9; sav   = 0;                              end

%
fwindow = ifrm : ffrm;
nfrms   = numel(isrcs);
npcts   = numel(ipcts);

%
if fidx
    ws = cellfun(@(x) fiberBundle1d(x), msrcs);
    wt = cellfun(@(x) fiberBundle1d(x), mtrgs);
    figclr(fidx);
end

%%
[fa , tpt] = deal(cell(nfrms, npcts));
for frm = fwindow
    fsrc = frm;
    ftrg = fsrc + 1;

    %%
    for pct = 1 : npcts
        %
        if frm == ifrm
            % Initial percentages to evaluate first frame
            ipct = ipcts(pct);
        else
            % Percentage from previous frame [sets upper bound]
            ipct = fa{frm-1,pct}(1);
        end

        if pct == 1
            % Initial percentages to evaluate first frame
            ppct = [];
        else
            % Percentage from previous point [sets lower bound]
            ppct = fa{frm,pct-1}(1);
        end

        %
        t = tic;
        fprintf('Finding matching point for point %.04f on frames %d and %d...', ...
            ipct, fsrc, ftrg);
        [fa{frm,pct} , tpt{frm,pct}] = domainFinder( ...
            isrcs{frm}, itrgs{frm}, msrcs{frm}, mtrgs{frm}, ipct, 'ppct', ppct);
        fprintf('DONE! (target at %.04f) [%.03f sec]\n', ...
            fa{frm,pct}(1), toc(t));

        %% Show tracked point on source and target
        if fidx
            showTrackingPoints(ipct, fa{frm,pct}(1), ws(frm), wt(frm), ...
                isrcs{frm}, msrcs{frm}, mtrgs{frm}, fsrc, ftrg, fidx);
        end
    end

    %% Show all tracked points from this frame
    if fidx
        fnm = showTrackingFrame(ipcts, fa{frm,:}, ws(frm), wt(frm), npcts, ...
            isrcs{frm}, msrcs{frm}, mtrgs{frm}, fsrc, ftrg, fidx, sav);
    end
end

%% Remove empty cells [if not starting at 1 and ending at nfrms]
fa  = fa(~cellfun(@isempty,fa(:,1)),:);
tpt = tpt(~cellfun(@isempty,tpt(:,1)),:);
end

function showTrackingPoints(tsrc, ttrg, ws, wt, isrc, msrc, mtrg, fsrc, ftrg, fidx)
%% showTrackingPoints:
%
if nargin < 10; fidx = 1; end

psrc = ws.evalCurve(tsrc, 'normalized');
ptrg = wt.evalCurve(ttrg, 'normalized');
pmtc = [psrc ; ptrg];

myimagesc(isrc);
hold on;
plt(msrc, 'r-', 2);
plt(mtrg, 'b-', 2);
plt(psrc, 'g.', 10);
plt(ptrg, 'y.', 10);
plt(pmtc, 'w-', 2);

ttl = sprintf('Frame %d to %d\nPoint %.03f to %.03f', ...
    fsrc, ftrg, tsrc, ttrg);
title(ttl, 'FontSize', 10);

drawnow;
hold off;
end

function fnm = showTrackingFrame(tsrcs, fa, ws, wt, npcts, isrc, msrc, mtrg, fsrc, ftrg, fidx, sav)
%% showTrackingFrame:
%
if nargin < 11; fidx = 1; end;
if nargin < 12; sav  = 0; end;

ttrgs = getDim(cat(1, fa{:}), 1);
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
if sav
    fdir = 'tracking/frames';
    fnm  = sprintf('%s_frame%02dto%02d_%03dpoints', ...
        tdate, fsrc, ftrg, npcts);
    saveFiguresJB(fidx, {fnm}, fdir);
end
end
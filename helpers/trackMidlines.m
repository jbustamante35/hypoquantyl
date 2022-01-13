function [fa , tpt] = trackMidlines(isrc, itrg, msrc, mtrg, ipcts, ifrm, ffrm, fidx, sav)
%% trackMidlines: Follow a single point through multiple frames
%
%
% Usage:
%   [fa , tpt] = trackMidlines(isrc, itrg, msrc, mtrg, ipcts, ...
%       ifrm, ffrm, fidx, sav)
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
if nargin < 5; ipcts = 0 : 1 / (size(msrc{1},1)) : 1; end
if nargin < 6; ifrm  = 1;                             end
if nargin < 7; fidx  = 0;                             end
if nargin < 8; sav   = 0;                             end

%
fwin       = ifrm : ffrm;
nfrms      = numel(isrc);
npcts      = numel(ipcts);
[fa , tpt] = deal(cell(nfrms, npcts));

%
if fidx
    ws = cellfun(@(x) fiberBundle1d(x), msrc);
    wt = cellfun(@(x) fiberBundle1d(x), mtrg);
    figclr(fidx);
end

%%
for frm = fwin
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
            isrc{frm}, itrg{frm}, msrc{frm}, mtrg{frm}, ipct, 'ppct', ppct);
        fprintf('DONE! (target at %.04f) [%.03f sec]\n', ...
            fa{frm,pct}(1), toc(t));

        %%
        if fidx
            tsrc = ipct;
            ttrg = fa{frm,pct}(1);
            psrc = ws(frm).evalCurve(tsrc, 'normalized');
            ptrg = wt(frm).evalCurve(ttrg, 'normalized');
            pmtc = [psrc ; ptrg];

            myimagesc(isrc{frm});
            hold on;
            plt(msrc{frm}, 'r-', 2);
            plt(mtrg{frm}, 'b-', 2);
            plt(psrc, 'g.', 10);
            plt(ptrg, 'y.', 10);
            plt(pmtc, 'w-', 2);

            ttl = sprintf('Frame %d to %d\nPoint %.03f to %.03f', ...
                fsrc, ftrg, tsrc, ttrg);
            title(ttl, 'FontSize', 10);

            drawnow;
            hold off;

            %             if sav
            %                 pdir = 'tracking/points';
            %                 fnm  = sprintf('%s_frame%02dto%02d_point%03dof%03d', ...
            %                     tdate, fsrc, ftrg, pct, npcts);
            %                 saveFiguresJB(fidx, {fnm}, pdir);
            %             end
        end
    end

    %%
    if fidx
        tsrcs = ipcts;
        ttrgs = getDim(cat(1, fa{frm,:}),1);
        psrcs = ws(frm).evalCurve(tsrcs, 'normalized');
        ptrgs = wt(frm).evalCurve(ttrgs, 'normalized');
        pmtcs = arrayfun(@(x) [psrcs(x,:) ; ptrgs(x,:)], ...
            (1 : npcts)', 'UniformOutput', 0);

        myimagesc(isrc{frm});
        hold on;
        plt(msrc{frm}, 'r-', 2);
        plt(mtrg{frm}, 'b-', 2);
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
end

%% Remove empty cells [if not starting at 1 and ending at nfrms]
fa  = fa(~cellfun(@isempty,fa(:,1)),:);
tpt = tpt(~cellfun(@isempty,tpt(:,1)),:);

end
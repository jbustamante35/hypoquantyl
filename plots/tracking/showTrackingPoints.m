function showTrackingPoints(gimgs, gmids, tpt, ipcts, pidx, dsk, frms, lims, fidx)
%% showTrackingPoints: show particles through time
%
% Usage:
%   showTrackingPoints(gimgs, gmids, tpt, ipcts, pidx, dsk, nfrms, lims, fidx)
%
% Input:
%   gimgs: images
%   gmids: midlines
%   tpt: tracked coordinates
%   ipcts: tracked percentages
%   pidx: specific points along midline to view
%   dsk: disk radius
%   frms: range of frames to show
%   lims: [xlims ; ylims] for viewing region
%   fidx: figure handle index

if nargin < 4; ipcts = []; end
if nargin < 5; pidx  = []; end
if nargin < 6; dsk   = 10; end
if nargin < 7; frms  = []; end
if nargin < 8; lims  = []; end
if nargin < 9; fidx  = 1;  end

if isempty(lims)
    xlims = [0 , size(gimgs{1},2)];
    ylims = [0 , size(gimgs{1},1)];
else
    xlims = lims(1,:);
    ylims = lims(2,:);
end

[nfrms , npcts] = size(tpt);
if isempty(frms);  frms  = 1 : nfrms;           end
if isempty(ipcts); ipcts = 0 : (1 / npcts) : 1; end

ww = cellfun(@(x) fiberBundle1d(x), gmids);
PP = arrayfun(@(x) x.evalCurve(ipcts, 'normalized'), ww, 'UniformOutput', 0);

%%
figclr(fidx);
for frm1 = frms
    frm2 = frm1 + 1;
    isrc = gimgs{frm1};
    msrc = gmids{frm1};
    itrg = gimgs{frm2};
    mtrg = gmids{frm2};
    ttl  = sprintf('%02d --> %02d', frm1, frm2);

    if isempty(pidx)
        tsrc = cat(1, tpt{frm1,:});
%         ttrg = cat(1, tpt{frm2,:});
        psrc = PP{frm1};
%         ptrg = PP{frm2};
    else
        tsrc = cat(1, tpt{frm1,pidx});
%         ttrg = cat(1, tpt{frm1,pidx});
        psrc = PP{frm1}(pidx,:);
%         ptrg = PP{frm2}(pidx,:);
    end

    % Show source and points on source
    myimagesc(isrc);
    xlim(xlims);
    ylim(ylims);
    hold on;
    plt(msrc, 'b-', 1);
    plt(psrc, 'b.', 3);
    viscircles(psrc, dsk, 'Color', 'b', 'LineWidth', 1);
    title(ttl(1:6), 'FontSize', 10);
    pause(0.2);
    hold off;

    % Show target and points landed on
    myimagesc(itrg);
    xlim(xlims);
    ylim(ylims);
    hold on;
    plt(mtrg, 'b-', 1);
    viscircles(psrc, dsk, 'Color', 'b', 'LineWidth', 0.5);
    viscircles(tsrc, dsk, 'Color', 'g', 'LineWidth', 1);
    title(ttl, 'FontSize', 10);
    pause(0.2);
    hold off;
end

if isempty(lims); axis on; end
end
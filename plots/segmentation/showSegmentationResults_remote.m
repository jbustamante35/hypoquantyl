function showSegmentationResults_remote(hyps, UOUT, LOUT, fidx, sav)
%% showSegmentationResults_remote
%
%
% Usage:
%   hyps: Hypocotyl objects
%   UOUT: output structures from upper hypocotyl segmentation on CONDOR
%   LOUT: output structures from lower hypocotyl segmentation on CONDOR
%   fidx: figure handle index
%   sav: save results

%
if nargin < 4; fidx = 0; end
if nargin < 5; sav  = 0; end
if ~fidx; return; end % Don't show if 0

%%
[nhyps , nsdls] = size(UOUT);
rows = 2;
cols = nsdls;
figclr(fidx);
for hidx = 1 : nhyps
    for sidx = 1 : nsdls
        hyp  = hyps(sidx);
        gnm  = hyp.GenotypeName;

        uimg = hyp.getImage(hidx, 'gray', 'upper');
        try
            limg = hyp.getImage(hidx, 'gray', 'lower');
        catch
            limg = [];
        end

        uout = UOUT{hidx,sidx};
        lout = LOUT{hidx,sidx};

        %
        subplot(rows, cols, sidx);
        myimagesc(uimg);
        hold on;
        plt(uout.opt.c, 'g-', 2);
        plt(uout.opt.m, 'r-', 2);
        hold off;
        ttl = sprintf('S%d', sidx);
        title(ttl, 'FontSize', 10);

        subplot(rows, cols, sidx + nsdls);
        myimagesc(limg);
        hold on;
        plt(lout.cntr, 'g-', 2);
        plt(lout.mline, 'r-', 2);
        hold off;
        ttl = sprintf('[%d of %d]', hidx, nhyps);
        title(ttl, 'FontSize', 10);
    end
    drawnow;

    if sav
        fdir = sprintf('segmentation_condor/plots/%s', gnm);
        fnm  = sprintf('%s_%s_%dseedlings_frame%02dof%02d', ...
            tdate, gnm, nsdls, hidx, nhyps);
        saveFiguresJB(fidx, {fnm}, fdir);
    end

end
end
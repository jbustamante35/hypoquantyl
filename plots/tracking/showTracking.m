function fnm = showTracking
%% showTracking:
%

% Show results!
tfrms = ifrm : ffrm;
t     = (ifrm-1 : ffrm)';
fidx  = 1;
% pidx  = 1 : 5 : numel(plen);
pidx  = 1 : numel(plen);

figclr(fidx);
hold on;
cellfun(@(x) plt([t , x], '-', 2), plen(pidx));
ttl = sprintf('ArcLength through %d frames [%d points]', numel(tfrms), npcts);
title(ttl, 'FontSize', 10);
ylabel('L (ArcLength from tip)', 'FontWeight', 'b');
xlabel('t (frames)', 'FontWeight', 'b');
xlim([min(t) , max(t)]);

if sav
    tdir = 'arclength_tracking';
    fnm  = sprintf('%s_arclength_%dpoints_%dframes', ...
        tdate, npcts, numel(tfrms));
    saveFiguresJB(fidx, {fnm}, tdir);
end
end
function showDomainInputs_remote(gen, gmids, gcnts, fidx)
%% showDomainInputs_remote
%
if nargin < 4; fidx = 0; end

% Don't show if 0
if ~fidx; return; end

%
[nhyps , nsdls] = size(gmids);
gttl = fixtitle(gen.GenotypeName);
figclr(fidx,1);
for hidx = 1 : nhyps
    gimg = gen.getImage(hidx);

    myimagesc(gimg);
    hold on;
    cellfun(@(x) plt(x, 'g-', 2), gcnts(hidx,:));
    cellfun(@(x) plt(x, 'r-', 2), gmids(hidx,:));
    ttl = sprintf('%s\n%d Seedlings [Frame %d of %d]', ...
        gttl, nsdls, hidx, nhyps);
    title(ttl, 'FontSize', 10);
    hold off;
    drawnow;
end
end
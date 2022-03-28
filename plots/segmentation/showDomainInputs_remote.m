function showDomainInputs_remote(gen, gmids, gsrcs, fidx)
%% showDomainInputs_remote
%
if nargin < 4; fidx = 0; end

% Don't show if 0
if ~fidx; return; end

%
[nhyps , nsdls] = size(gmids);
gttl = fixtitle(gen.GenotypeName);
figclr(fidx);
for hidx = 1 : nhyps
    gimg = gen.getImage(hidx);

    myimagesc(gimg);
    hold on;
    cellfun(@(x) plt(x, '-', 2), gmids(hidx,:));
    cellfun(@(x) plt(x.cupp, '--', 1), gsrcs(hidx,:), 'UniformOutput', 0);
    cellfun(@(x) plt(x.clow, '--', 1), gsrcs(hidx,:), 'UniformOutput', 0);
    hold off;
    ttl = sprintf('%s\n%d Seedlings [Frame %d of %d]', ...
        gttl, nsdls, hidx, nhyps);
    title(ttl, 'FontSize', 10);
    drawnow;
end
end
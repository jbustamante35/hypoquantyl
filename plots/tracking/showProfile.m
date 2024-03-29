function showProfile(v, r, c, fidx, vttl, rttl, laxis, vaxis, raxis, uaxis, fsz, fcnv)
%% showProfile: plot velocity and regr profile

if nargin < 12; fcnv  = [];          end


% Convert units
if ~isempty(fcnv)
    % Some absurd nonsense to make x-axis look nicer
    p2m  = fcnv{1}; % Length in which REGR was sampled
    nlax = numel(laxis) - 1;
    xax  = round(0 : p2m / nlax : p2m);

    xu = 'h';
    yu = 'mm';
else
    xu  = 'frms';
    yu  = 'pix';
    xax = laxis;
end

xlbl = sprintf('L (%s)', yu);
vlbl = sprintf('V (%s / %s)\n%s', yu, xu);
rlbl = sprintf('REGR (%% / %s)\n%s', xu);

%
figclr(fidx);
subplot(121); hold on;
cellfun(@(x,k) plt(x, sprintf('%s-', k), fsz(1)), v, c);
xticks(laxis); yticks(vaxis); ylim(uaxis{1}); axis square;
ylabel(vlbl, 'FontWeight', 'b', 'FontSize', fsz(3));
xlabel(xlbl, 'FontWeight', 'b', 'FontSize', fsz(3));
title(vttl, 'FontSize', fsz(3)); hold off;
setAxis(fidx, fsz(3), 'b');
xticklabels(xax);

subplot(122); hold on;
cellfun(@(x,k) plt(x, sprintf('%s-', k), fsz(1)), r, c);
xticks(laxis); yticks(raxis); ylim(uaxis{2}); axis square;
ylabel(rlbl, 'FontWeight', 'b', 'FontSize', fsz(3));
xlabel(xlbl, 'FontWeight', 'b', 'FontSize', fsz(3));
title(rttl, 'FontSize', fsz(3)); hold off;
setAxis(fidx, fsz(3), 'b');
xticklabels(xax);
end
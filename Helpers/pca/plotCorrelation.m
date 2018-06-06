function fig = plotCorrelation(NA, CA, RA, PA, NB, CB, RB, PB, sv)
%% plotCorrelation: plot principal components against each other
% This function extracts pca output from x-/y-coordinates (CA,CB), desired Route segments (RA,RB),
% and a principal component (PA,PB) and plots them against each other. This is used to find
% correlations amongst the principal components. The resulting figure can be saved with the boolean
% sv parameter as the filename nm.
%
% Usage:
%   fig = plotCorrelation(CA, RA, PA, CB, RB, PB, nm, sv)
%
% Input:
%   NA: name of coordinate for first data ('X' or 'Y')
%   CA: first coordinate pca data to extract from (x-/y-coordinate)
%   RA: segment number for CA
%   PA: principal component number for CA
%   NB: name of coordinate for second data ('X' or 'Y')
%   CB: second coordinate pca data to extract from (x-/y-coordinate)
%   RB: segment number for CB
%   PB: principal component number for CB
%   sv: boolean to save figure
%
% Output:
%   fig: resulting figure from this function
%

%% Create new figure or replace current figure
% if nf
%     fig = figure;
% else
%     %     cla;clf;
% end

%% Function handle for plotting
plt = @(a,b,c,d,e,f) plot(a(b).PCAscores(:,c), d(e).PCAscores(:,f), '.');
fig = plt(CA,RA,PA,CB,RB,PB);
set(gcf, 'Color', 'w');
set(gca, 'FontSize', 7);
xlabel(sprintf('%s | R%d | PC%d', NA, RA, PA), 'FontSize', 10);
ylabel(sprintf('%s | R%d | PC%d', NB, RB, PB), 'FontSize', 10);

%% Save figure as filename
if sv
    nm = sprintf('%s_PCAcorrelation_%s_R%d_P%d_%s_R%d_P%d',...
        datestr(now, 'yymmdd'), NA, RA, PA, NB, RB, PB);
    savefig(fig, nm);
    saveas(fig, nm, 'tiffn');
end

end
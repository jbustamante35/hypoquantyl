function fig = plotCorrelationMulti(Nm, Cm, Rm, Pm, X, Y, sv, nf)
%% plotCorrelationMulti: plot pca data of a single PC from a Route against all other PCs
% This function takes the main PC data from A and plots it against all other PCs from
% x-/y-coordinate pca data. User can save output in new figure or replace current figure.
%
% Usage:
%   fig = plotCorrelationMulti(A, X, Y, sv, nf)
%
% Input:
%   A: main to plot all other PCs against
%   X: pca data for all Routes from x-coordinates
%   Y: pca data for all Routes from y-coordinates
%   sv: boolean to save resulting figure
%   nf: boolean to create new figure or overwrite current figure
%
% Output:
%   fig: handle to resulting figure
%

%% Create new figure or replace current figure
if nf
    fig = figure;
    set(gcf, 'Color', 'w');
else
    % cla;clf;
    set(gcf, 'Color', 'w');
end

%% Function handle for plotting and retrieving sizes of data
mplt = @(nb,cb,rb,pb) plotCorrelation(Nm, Cm, Rm, Pm, nb, cb, rb, pb, 0);
sz   = @(s) cellfun(@(z) z(2), s, 'UniformOutput', 0);

%% Determine total number of figure will be generated
% Calculate total PCs
x = sz(arrayfun(@(x) size(x.PCAscores), X, 'UniformOutput', 0));
y = sz(arrayfun(@(x) size(x.PCAscores), Y, 'UniformOutput', 0));
x = sum(cat(1, x{:}));
y = sum(cat(1, y{:}));
t = sum([x ; y]) - 1; % Ignore plotting against itself

% Sort out subplot size (currently doesn't work for odd totals)
r = round(t / 5);
c = round(t / r);

%% Iterate through all data and plot on new subplots
f = 1;
for i = 1 : numel(X)
    for ii = 1 : size(X(i).PCAscores,2)
        n = 'X';
        chk = checkMatch({Nm, Rm, Pm}, {n, i, ii});
        if ~chk
            subplot(r,c,f);
            mplt(n, X, i, ii);
            title(f, 'FontSize', 10);
            f = f + 1;
            fprintf('%d,%d,%d\n', i, ii, f);
        end
    end
end

for j = 1 : numel(Y)
    for jj = 1 : size(Y(j).PCAscores,2)
        n = 'Y';
        chk = checkMatch({Nm, Rm, Pm}, {n, j, jj});
        if ~chk
            subplot(r,c,f);
            mplt(n, Y, j, jj);
            title(f, 'FontSize', 10);
            f = f + 1;
            fprintf('%d,%d,%d\n', j, jj, f);
        end
    end
end


%% Save figure as filename
if sv
    nm = sprintf('%s_MultiPCAcorrelation_%s_R%d_P%d', datestr(now, 'yymmdd'), Nm, Rm, Pm);
    fprintf('Saved %s\n', nm);
    savefig(fig, nm);
    saveas(fig, nm, 'tiffn');
end

end

function c = checkMatch(a,b)
%% checkMatch: subfunction to check for matching arrays
c = isequal(a, b);

end

function [CTR, fig] = meanContour(C, Dx, Dy, fc, sv, f)
%% meanContour: obtain the mean contour from the training set based on PCA results
% This function combines results from PCA (see pcaAnalysis) and training data (see CircuitJB and
% Routes) to synthetically construct the average contour shape based on the mean of the PCA scores
% of each Route from the training set.
%
% Usage:
%   CTR = meanContour(C, D, sv, f)
%
% Input:
%   C: CircuitJB object array containing contour data
%   Dx: pca results from training set for x-coordinates
%   Dy: pca results from training set for y-coordinates
%   fc: direction contours are facing 'Left' or 'Right' (for figure title)
%   sv: boolean to save results in mat-file format
%   f: boolean to (0) create new figure or (1) overwrite current figure
%
% Output:
%   CTR: structure containing mean contour data
%

%% Figure
if f
    cla;cla;
    fig = gcf;
else
    fig = figure;
end

%% Function Handles: general plotting function, get random from set, convert contours
m        = @(x) randi([1 length(x)], 1);
norm2raw = @(o, m, x, t) reverseMidpointNorm([o{x, 1} ; o{x, 2}]', m(:, :, x))' + t(:, 2:3, x);

%% Extract P-matrix and P-parameters from all Routes of CircuitJB array
D        = [Dx Dy];
N        = numel(C.getRoute);
[Gm, Gp] = gatherParams(C);
Pm       = reshape(mean(Gm, 3), 3, 3, N);
Pp       = reshape(mean(Gp, 3), 1, 3, N);

%% Synthetic data: extract PCA Scores, Eigenvectors, and means
S = arrayfun(@(x) x.PCAscores, D, 'UniformOutput', 0);
V = arrayfun(@(x) x.EigVectors, D, 'UniformOutput', 0);
U = arrayfun(@(x) x.MeanVals, D, 'UniformOutput', 0);

%% Convert mean PCAscore to NormalTrace, convert NormalTrace to InterpTrace
M = cellfun(@(x) mean(x), S, 'UniformOutput', 0);
O = cellfun(@(x, y, z) pca2norm(x, y, z), M, V, U, 'UniformOutput', 0);
R = arrayfun(@(x) norm2raw(O, Pm, x, Pp), 1:N, 'UniformOutput', 0);

%% Plot average contour
set(fig, 'Color', 'w');
hold on;
axis ij;
cellfun(@(x) plt(x,'.',5), R, 'UniformOutput', 0);
ttl = sprintf('Mean Contour \n %d %s-facing Contours', numel(C), fc);
title(ttl);

%% Final Output Structure
FUNCS = v2struct(m, pca2norm, norm2raw);
CTR   = v2struct(FUNCS, C, D, Pm, Pp, S, V, U, M, O, R);

if sv
    nm = sprintf('%s_meanContourRepresentation_%dContours_%s-Facing', ...
        datestr(now, 'yymmdd'), numel(C), fc);
    save(nm, '-v7.3', 'CTR');
    savefig(fig, nm);
    saveas(fig, nm, 'tiffn');
end
end

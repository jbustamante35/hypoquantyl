function [P, fig] = createProbabilityImage(C, fc, m, sv, f)
%% createProbabilityImage: generate probability matrix from normalized contour coordinates
% Use this function to test the rescaleNormMethod function
%
% Usage:
%   [P, fig] = createProbabilityImage(C, fc, m, sv, f)
%
% Input:
%   C: object array of CircuitJB contours
%   fc: direction CircuitJB contours are facing
%   m: boolean to (0) use current mask or (1) re-generate masks at 2.5x image size
%   sv: boolean to save figure and updated CircuitJB data
%   f: boolean to (0) overwrite current figure or (1) create new figure
%
% Output:
%   P: resulting [m x n] probability matrix from input data
%   fig: resulting figure
%

%% Create new figure or overwrite existing
if f
    fig = figure;
    set(fig, 'Color', 'w');
else
    fig = gcf;
    set(fig, 'Color', 'w');
end

%% Generate probability matrix with normalized outline
if m
    n = 2.5;
    arrayfun(@(x) x.NormalizeOutline, C, 'UniformOutput', 0);
    arrayfun(@(x) x.generateMasks(n), C, 'UniformOutput', 0);
end

P = probabilityMatrix(C, 0);

%% Show resulting figure
imagesc(P);
colormap gray;
ttl = sprintf('Probability Matrix | %d Contours \n %s-Facing', numel(C), fc);
title(ttl);

if sv
    %% Save figures
    nm = sprintf('%s_ProbabilityMatrix_%dcircuits%s', datestr(now, 'yymmdd'), numel(C), fc);
    savefig(fig, nm);
    saveas(fig, nm, 'tiffn');
    
    %% Save probability image
    nm = sprintf('%s_probabilityMatrix_%dcircuits%s', datestr(now,'yymmdd'), numel(C), fc);
    save(nm, '-v7.3', 'P');
end
end
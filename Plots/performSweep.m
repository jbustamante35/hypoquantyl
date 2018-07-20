function performSweep(pcaX, pcaY, nsteps, sv, name, eqlax)
%% performSweep: run pcaSweep through all principal components n times
% This function performs a sweep through each principal component of 2 sets of PCA structures. The
% function used to make iterative steps of each PC is defined at the top of this file as
% 'upFn'/'dwnFn', and as of now they just iteratively add/subtract StDev of the given PC.
%
% The user can set the number of steps with 'nsteps', which defines both the number of steps up
% and down from the mean PC score.
%
% Output is in the form of 2 separate figures, representing iterative steps of each principal
% component from both inputted PCA structures. Structures don't need to have an equal number PCs.
%
% Usage:
%   performSweep(pcaX, pcaY, nsteps, name, eqlax)
%
% Input:
%   pcaX: structure containing x-coordinate output from custom pcaAnalysis
%   pcaY: structure containing y-coordinate output from custom pcaAnalysis
%   nsteps: number of steps to sweep PCs with iterative function
%   sv: save figures in .fig and .tiff files
%   name: set name to use if you want to normalize axes limits
%   eqlax: set to true if you want to normalize axes limits using 'name' values
%
% Output: n/a
%   This function outputs 2 individual plots of the original synthetic contour (dotted black line)
%   and all n iterative steps up (solid green line) and down (solid red line). Each subplot
%   is created by the n iterative steps  through each PC for both inputted PCA structures.
%
% Example:
%   performSweep(pcaX, pcaY, 5, 'scott', 1)
%   pcaX has 2 PCs, pcaY has 5 PCs --> figure(1) will 2 subplots, figure(2) will have 5 subplots,
%   and both figures will have equal axes limits
%

% Set up function handle for iterative functions and easy use of pcaSweep
upFn  = @(x,y) x + y;
dwnFn = @(x,y) x - y;
pcSwp = @(x,y,z) pcaSweep(pcaX, pcaY, x, y, upFn, dwnFn, z);
stps  = 1 : nsteps; % Number of iterative steps up and down

% Dimensions and PCs to iterate through
dim = [1 2];
pcX = 1 : size(pcaX.PCAscores, 2);
pcY = 1 : size(pcaY.PCAscores, 2);
pcA = {pcX pcY};

% Equalize axes limits if you want each plot to have same axes (SET 'eqlax' TO TRUE)
% You can set these limits to whatever values you want
% Format is [xMin xMax ; yMin yMax]
axs  = struct('julian', [-150 0; -150 150], ...
    'scott',[-10 1200 ; -600 2500]);

% Create 2 sets of figures for x- and y-coordinates
for d = dim
    fig = figure;
    set(gcf,'color','w');
    tot = numel(pcA{d});
    row = 2;
    col = ceil(tot / row);
    for k = 1 : tot
        subplot(row, col, k);
        arrayfun(@(x) pcSwp(d, pcA{d}(k), x), stps, 'UniformOutput', 0);
        
        % Equalize axes limits if set to TRUE
        if isfield(axs, name) && eqlax
            xlim(axs.(name)(2,:));
            ylim(axs.(name)(1,:));
            typ = {'pcaXeql' 'pcaYeql'};
        else
            typ = {'pcaX' 'pcaY'};
        end
    end
    
    if sv
        num = numel(pcA{d});
        fnm = sprintf('%s_PCSweepFull_%s_%dPCs', datestr(now,'yymmdd'), typ{d}, num);
        savefig(fig, fnm);
        saveas(fig, fnm, 'tiffn');
    end
end

end

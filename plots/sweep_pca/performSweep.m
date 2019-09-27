function [scoresAll, simsAll, figs] = performSweep(varargin)
%% performSweep: run pcaSweep through all principal components n times
% This function performs a sweep through each principal component of 2 sets
% of PCA structures. The function used to make iterative steps of each PC is
% defined at the top of this file as 'upFn'/'dwnFn', and as of now they just
% iteratively add/subtract StDev of the given PC.
%
% The user can set the number of steps with 'nsteps', which defines both the
% number of steps up and down from the mean PC score (1 step = 1 standard
% deviation from the mean).
%
% Output is in the form of 2 separate figures, representing iterative steps
% of each principal component from both inputted PCA structures. Structures
% don't need to have an equal number PCs.
%
% The up and down functions [upFn|dwnFn] are an anonymous function that takes in
% as input the PC score (x) and the value to increment by (y): 
%    upFn  = @(x,y) x+y;
%    dwnFn = @(x,y) x-y;
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
%   This function outputs 2 individual plots of the original synthetic
% contour (dotted black line) and all n iterative steps up (solid green line)
% and down (solid red line). Each subplot is created by the n iterative
% steps  through each PC for both inputted PCA structures.
%
% Example:
%   performSweep(pcaX, pcaY, 5, 'scott', 1)
%   pcaX has 2 PCs, pcaY has 5 PCs --> figure(1) will have 2 subplots, figure(
%   2) will have 5 subplots, and both figures will have equal axes limits

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    % MATLAB's assignin function only assigns variables for the caller of the
    % function calling assignin, rather than in the function it is being
    % called from. This neat little trick creates a temporary anonymous
    % function to assign variables to this local workspace.
    % See Alec Jacobson's blog post at
    % (http://www.alecjacobson.com/weblog/?p=3792)
    
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

%% Set up function handle for iterative functions and easy use of pcaSweep
pcSwp = @(x,y,z) sweep2('pcaX', pcaX, 'pcaY', pcaY, 'dim2chg', x, ...
    'pc2chg', y, 'stp', z, 'f', 1);
stps  = 1 : nsteps; % Number of iterative steps up and down

% Dimensions and PCs to iterate through
dim = [1 2];
pcX = 1 : size(pcaX.PCAscores, 2);
pcY = 1 : size(pcaY.PCAscores, 2);
pcA = {pcX pcY};

%% Equalize axes limits if you want each plot to have same axes (SET 'eqlax' TO TRUE)
% You can set these limits to whatever values you want
% Format is [xMin xMax ; yMin yMax]
% axs  = struct('j', [-150 0; -150 150], ...
%     's',[-10 1200 ; -600 2500]);

%% Create 2 sets of figures for x- and y-coordinates
figs = [1 2];
for d = dim
    figs(d) = figure;
    set(gcf,'color','w');
    tot = numel(pcA{d});
    row = 2;
    col = ceil(tot / row);
    for k = 1 : tot
        subplot(row, col, k);
        [scoresAll{d,k}, simsAll{d,k}] = ...
            arrayfun(@(x) pcSwp(d, pcA{d}(k), x), stps, 'UniformOutput', 0);
        
        % Equalize axes limits if set to TRUE
        %         if isfield(axs, usr) && eqlax
        %             xlim(axs.(usr)(2,:));
        %             ylim(axs.(usr)(1,:));
        %             typ = {'pcaXeql' 'pcaYeql'};
        %         else
        %             typ = {'pcaX' 'pcaY'};
        %         end
        % Equalize axes limits
        %         xlim([-2000 0]);
        %         ylim([-1000 1000]);
        typ = {'pcaX' 'pcaY'};
    end
    
    if sv
        num = numel(pcA{d});
        fnm = sprintf('%s_PCSweepFull_%s_%dPCs', tdate, typ{d}, num);
        savefig(figs(d), fnm);
        saveas(figs(d), fnm, 'tiffn');
    end
end

end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
% Need descriptions for all these parameters
% pcaX, pcaY, chg, mns, eigs, scrs, pc, upFn, dwnFn, stp, f
% pcaX, pcaY, nsteps, sv, usr, eqlax

p = inputParser;
p.addOptional('pcaX', struct());
p.addOptional('pcaY', struct());
p.addOptional('nsteps', 1);
p.addOptional('upFn', @(x,y) x+y);
p.addOptional('dwnFn', @(x,y) x-y);
p.addOptional('f', 0);
p.addOptional('sv', 0);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end

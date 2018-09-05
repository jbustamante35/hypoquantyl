function [scoresStruct, simsStruct] = sweep2(varargin)
%% sweep2: perform pcaSweep with x-/y-coordinates
% This function outputs a single plot of the original synthetic contour (dotted black line) and a
% single step up (solid green line) or down (solid red line) defined by inputted function handles.
%
% This function performs an iterative step up and down through a single principal component, where
% the iterative step is defined by user input. User also determines which principal component to
% iterate through.
%
% After calculating the new PCA scores, a single new plot generates synthetic images of the
% original mean PCA scores and 2 synthetic images representing an iterative step up and down
% overlaid on the same plot.
%
% See the performSweep function to use this to sweep through all principal components for multiple
% iterative steps. [or read help performSweep]
%
% Usage:
%   [scoresStruct, simsStruct] = sweep2(pcaX, pcaY, dim2chg, pc2chg, upFn, dwnFn, stp, f)
%
% Input:
%   pcaX: structure containing x-coordinate output from custom pcaAnalysis
%   pcaY: structure containing y-coordinate output from custom pcaAnalysis
%   dim2chg: 1 to iteratively change x-coordinate PCs, 2 to change y-coordinate PCs
%   pc2chg: principal component to iteratively sweep
%   upFn: function handle to positively sweep PCs
%   dwnFn: function handle to negatively sweep PCs
%   stp: size of step for iterative function
%   f: boolean to overwrite on old figure (0) or create new figure (1)
%
% Output:
%   scoresStruct: structure containing PC values after iterative step [see below for contents]
%       up: PC values after upFn
%       mean: mean PC values from dataset
%       down: PC values after dwnFn
%   simsStruct: structure containing synthetic values after transformations [see below for contents]
%       up: synthetic values after transformation in positive step
%       mean: synthetic values after transformation in neutral step
%       down: synthetic values after transformation in negative step
%

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    % MATLAB's assignin function only assigns variables for the caller of the function calling
    % assignin, rather than in the function it is being called from. This neat little trick creates
    % a temporary anonymous function to assign variables to this local workspace.
    % See Alec Jacobson's blog post at (http://www.alecjacobson.com/weblog/?p=3792)
    
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

%% Store data in easier variables if inputting full pca structures
% Check if using full structures or individual vectors [scores, eigenvectors, and means]
if ~isempty(fieldnames(pcaX)) || ~isempty(fieldnames(pcsY))
    mnsD = {pcaX.MeanVals   ; pcaY.MeanVals};
    eigV = {pcaX.EigVectors ; pcaY.EigVectors};
    scrD = {pcaX.PCAscores  ; pcaY.PCAscores};
else
    mnsD = {meansX  ; meansY};
    eigV = {eigsX   ; eigsY};
    scrD = {scoresX ; scoresY};
end

%% Run pcaSweep for PCA data for either x-/y-coordinates [hold values of opposite
pSweep = @(m, e, s, p) pcaSweep(m, e, s, p, upFn, dwnFn, stp, 0);

if dim2chg == 1
    [scrsX, simsX] = pSweep(mnsD{1}, eigV{1}, scrD{1}, pc2chg);
    [scrsY, simsY] = pSweep(mnsD{2}, eigV{2}, scrD{2}, 0);
    
else
    [scrsX, simsX] = pSweep(mnsD{1}, eigV{1}, scrD{1}, 0);
    [scrsY, simsY] = pSweep(mnsD{2}, eigV{2}, scrD{2}, pc2chg);
end

%% Create output structures
scoresStruct = struct('up', {scrsX.up , scrsY.up}, ...
    'mean', {scrsX.mean , scrsY.mean}, ...
    'down', {scrsX.down , scrsY.down});

simsStruct = struct('up', [simsX.up , simsY.up], ...
    'mean', [simsX.mean , simsY.mean], ...
    'down', [simsX.down , simsY.down]);

%% Plot original, up, and down iterative steps on single plot
% DO NOT CREATE A NEW FIGURE (figures created with multi-sweep functions)
if f
    plt(simsStruct.mean, 'k--', 1);
    hold on;
    plt(simsStruct.down, 'r-', 1);
    plt(simsStruct.up, 'g-', 1);
    
    ttl = sprintf('Dim_%d|PC_%d|Steps_%d', dim2chg, pc2chg, stp);
    title(ttl);
    axis ij;
end

end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
% Need descriptions for all these parameters
% pcaX, pcaY, dim2chg, mns, eigs, scrs, pc2chg, upFn, dwnFn, stp, f

p = inputParser;
p.addOptional('pcaX', struct());
p.addOptional('pcaY', struct());
p.addOptional('meansX', []);
p.addOptional('eigsX', []);
p.addOptional('scoresX', []);
p.addOptional('meansY', []);
p.addOptional('eigsY', []);
p.addOptional('scoresY', []);
p.addOptional('dim2chg', 1);
p.addOptional('pc2chg', 1);
p.addOptional('upFn', @(x,y) x+y);
p.addOptional('dwnFn', @(x,y) x-y);
p.addOptional('stp', 1);
p.addOptional('f', 0);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end

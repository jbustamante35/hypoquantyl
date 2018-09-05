function [newScoresUp, meanScores, newScoresDwn] = pSweep(pcaX, pcaY, chg, pc, upFn, dwnFn, stpSz)
%% pcaSweep: sweep through mean principal component scores
% NOTE: This function only works for my custom PCA for now, but I'll work on generalizing it to be
% more flexible in the future. Run the testSweep function for testing and debugging.
%
% This function performs an iterative step up and down through a single principal component, where
% the iterative step is defined by user input. User also determines which principal component to
% iterate through.
%
%  After calculating the new PCA scores, a single new plot generates synthetic images of the
%  original mean PCA scores and 2 synthetic images representing an iterative step up and down
%  overlaid on the same plot.
%
%  See the testSweep function below to see how you can use this to sweep through all principal
%  components for multiple iterative steps. [or read help performSweep]
%
% Usage:
%   [newScoresUp, meanScores, newScoresDwn] = pcaSweep(pcaX, pcaY, chg, pc, upFn, dwnFn, stpSz)
%
% Input:
%   pcaX: structure containing x-coordinate output from custom pcaAnalysis
%   pcaY: structure containing y-coordinate output from custom pcaAnalysis
%   chg: 1 to iteratively change x-coordinate PCs, 2 to change y-coordinate PCs
%   pc: principal component to iteratively sweep
%   upFn: function handle to positively sweep PCs
%   dwnFn: function handle to negatively sweep PCs
%   stpSz: size of step for iterative function
%
% Output:
%   newScoresUp:
%   meanScores:
%   newScoresDwn:
%
%   This function outputs a single plot of the original synthetic contour (dotted black line) and a
%   single step up (solid green line) or down (solid red line) defined by inputted function handles.
%

%% Store data in easier variables
mnsD = {pcaX.MeanVals;   pcaY.MeanVals};
eigV = {pcaX.EigVectors; pcaY.EigVectors};
scrD = {pcaX.PCAscores;  pcaY.PCAscores};

%% Mean and StDev of all PCs in x and y coords
meanScores = cellfun(@(x) mean(x), scrD, 'UniformOutput', 0);
sdvScores  = cellfun(@(x) std(x), scrD, 'UniformOutput', 0);

%% PCn of x-coord +1 StDev above mean
% Hold unchanged PC scores and compute value for iterative step 
hld = 3 - chg;
val = sdvScores{chg}(pc) * stpSz;

% Compute function to change PC score
itrUp  = upFn(meanScores{chg}(pc), val);
itrDwn = dwnFn(meanScores{chg}(pc), val);

% Replace old with new values and store updated mean PC scores 
[upScores, dwnScores] = deal(meanScores{chg});
upScores(pc)          = itrUp;
dwnScores(pc)         = itrDwn;

if chg == 1
    newScoresUp  = {upScores ; meanScores{hld}};
    newScoresDwn = {dwnScores ; meanScores{hld}};
else
    newScoresUp  = {meanScores{hld} ; upScores};
    newScoresDwn = {meanScores{hld} ; dwnScores};
end

%% Create new synthetic images with updated PC scores
orgSim = cellfun(@(x, y, z) input2sim(x, y, z), meanScores, eigV, mnsD, 'UniformOutput', 0);
upSim  = cellfun(@(x, y, z) input2sim(x, y, z), newScoresUp, eigV, mnsD, 'UniformOutput', 0);
dwnSim = cellfun(@(x, y, z) input2sim(x, y, z), newScoresDwn, eigV, mnsD, 'UniformOutput', 0);

%% Plot original, up, and down iterative steps on single plot
plot(dwnSim{2}, dwnSim{1}, 'r');
hold on;
plot(orgSim{2}, orgSim{1}, 'k--', 'MarkerSize', 12);
plot(upSim{2}, upSim{1}, 'g');
ttl = sprintf('Dim_%d|PC_%d|Steps_%d', chg, pc, stpSz);
title(ttl);
axis ij; 

end

%% ---------------------------------------------------------------------------------------------- %%

function testSweep
%% testSweep: DEBUGGING AND TESTING PCASWEEP
% USE performSweep INSTEAD 
% Set up function handle for ease-of-use
upFn  = @(x,y) x + y;
dwnFn = @(x,y) x - y;
pcswp = @(x,y,z) pcaSweep(pcaX, pcaY, x, y, upFn, dwnFn, z);
stps  = 1 : 5; % Number of iterative steps up and down

% Decide dimension and PC to change
d    = 1;
pcX  = 1 : size(pcaX.PCAscores, 2);
pcY  = 1 : size(pcaY.PCAscores, 2);

% Equalize axes limits if you want each plot to have same axes (SET 'eql' TO TRUE)
% You can set these limits to whatever values you want
% Format is [xMin xMax ; yMin yMax]
axs  = struct('julian', [-50 150  ; -150  200], ...
    'scott',[-10 1200 ; -600 2500]);
name = 'scott';
eql  = false;

% Create 2 sets of figures for x- and y-coordinates
figure;
nX  = numel(pcX);
row = 2;
col = ceil(nX / row);
for k = 1 : nX
    subplot(row, col, k);
    arrayfun(@(x) pcswp(d,pcX(k),x), stps, 'UniformOutput', 0);
    
    if eql
        xlim(axs.(name)(2,:));
        ylim(axs.(name)(1,:));
    end
end

figure;
nY = numel(pcY);
row = 2;
col = ceil(nY / row);
for k = 1 : nY
    subplot(row, col, k);
    arrayfun(@(x) pcswp(d+1,pcY(k),x), stps, 'UniformOutput', 0);
    
    if eql
        xlim(axs.(name)(2,:));
        ylim(axs.(name)(1,:));
    end
end

end


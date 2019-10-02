function [scrStruct, simStruct] = pcaSweep(mns, eigs, scrs, pc, upFn, dwnFn, stp, f, sngl)
%% pcaSweep: sweep through mean principal component scores
% This function performs an iterative step up and down through a single
% principal component, where the iterative step is defined by the user. User
% also determines which principal component to iterate through.
%
% After calculating the new PCA scores, a single new plot generates synthetic
% images of the original mean PCA scores and 2 synthetic images representing
% an iterative step up and down overlaid on the same plot.
%
% The up and down functions [upFn|dwnFn] are an anonymous function that takes in
% as input the PC score (x) and the value to increment by (y):
%    upFn  = @(x,y) x+y;
%    dwnFn = @(x,y) x-y;
%
% Usage:
%   [scoreStruct, simStruct] = pcaSweep(mns, eigs, scrs, pc, upFn, dwnFn, stp, f, sngl)
%
% Input:
%   mns: mean values subtracted from rasterized dataset
%   eigs: eigenvectors from PCA output
%   scrs: principal component (PC) scores from PCA output
%   pc: principal component to sweep
%   upFn: function handle to positively sweep PC
%   dwnFn: function handle to negatively sweep PC
%   stp: size of step to iteratively sweep by sweeping function [usually 1]
%   f: boolean to hide figure output (0) or generate figure (1)
%   sngl: single row from PC scores to check iteration with individual scores
%
% Output:
%   scoreStruct: structure containing PC values after iterative step
%       scoreUp: PC values after upFn
%       scoreMn: mean PC values from dataset
%       scoreDown: PC values after dwnFn
%   simStruct: structure containing synthetic values after transformations
%       simUp: synthetic values after transformation in positive step
%       simMn: synthetic values after transformation in neutral step
%       simDown: synthetic values after transformation in negative step
%

%% Mean and StDev of all PCs in x and y coords
% Take mean if sngl parameter is true
if nargin < 9
    scoreMn = mean(scrs);
else
    scoreMn = scrs(sngl,:);
end

stDevs  = std(scrs);

%% PCn (xstp) StDevs above mean
if pc > 0
    % Compute value for iterative step and iterative PC score
    val    = stDevs(pc) * stp;
    itrUp  = upFn(scoreMn(pc), val);
    itrDwn = dwnFn(scoreMn(pc), val);

    % Replace old with new values and store updated mean PC scores
    [scoreUp, scoreDown] = deal(scoreMn);
    scoreUp(pc)          = itrUp;
    scoreDown(pc)        = itrDwn;
else
    % Hold up and down scores if no pc to change
    [scoreUp, scoreDown] = deal(scoreMn);
end

%% Create new synthetic images with updated PC scores
orgSim = [pcaProject(scoreMn,   eigs, mns, 'scr2sim') ; 1:length(eigs)]';
upSim  = [pcaProject(scoreUp,   eigs, mns, 'scr2sim') ; 1:length(eigs)]';
dwnSim = [pcaProject(scoreDown, eigs, mns, 'scr2sim') ; 1:length(eigs)]';

%% Create output structures
scrStruct = struct('up', scoreUp, 'mean', scoreMn, 'down', scoreDown);
simStruct = struct('up', upSim(:,1), 'mean', orgSim(:,1), 'down', dwnSim(:,1));

%% Plot original, up, and down iterative steps on single plot
% DO NOT CREATE A NEW FIGURE (figures created with multi-sweep functions)
if f
    plt(orgSim, 'k--', 1);
    hold on;
    plt(dwnSim, 'r-', 1);
    plt(upSim, 'g-', 1);

    ttl = sprintf('PC_%d|Steps_%d', pc, stp);
    title(ttl);
    axis ij;
end

end

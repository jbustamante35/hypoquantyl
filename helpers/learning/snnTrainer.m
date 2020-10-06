function [IN, OUT] = snnTrainer(SSCR, ZSLC, NLAYERS, TRNFN, splts, sav, par, isSkls)
%% snnTrainer: simple fitnet to predict contour segments from Z-Vector slices
%
%
% Usage:
%   [IN, OUT] = snnTrainer(SSCR, ZSLC, NLAYERS, TRNFN, splts, sav, par, isSkls)
%
% Input:
%   SSCR: PCA scores of S-Vectors [concatenated X-/Y-coordinates]
%   ZSLC: Z-Vectors slices with vectorized Z-Patch
%   NLAYERS: number of hidden layers
%   TRNFN: training function to run neural net on
%   splts: dataset splits of training, validation, testing indices
%   sav: boolean to save output structure in a .mat file
%   par: boolean to use parallel computing if available
%   isSkls: dataset is from Skeleton Patches
%
% Output:
%   IN: structure containing the inputs used for the neural net run
%   OUT: structure containing predictions, network objects, and data splits
%

%% Check if dealing with Skeleton Patches
if nargin < 7
    isSkls = 0;
end

%% Extract some info about the dataset
% Total observations and number of scores used
[NSEGS , pcs] = size(SSCR);
% allSegs       = 1 : NSEGS;
% TRNFN         = 'trainlm';

tAll              = tic;
[~ , sepA , sepB] = jprintf('', 0, 0);
fprintf('%s\nTraining S-Vectors from %d Images to %d PC Scores using %d layers of the %s function [Save %d | Par %d | Verbose %d]\n%s\n', ...
    sepA, NSEGS, pcs, NLAYERS, TRNFN, sav, par, vrb, sepB);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Split into training, validation, and testing sets
t = tic;

if isempty(splts)
    % Do the split
    n      = fprintf('Splitting data into training/validation/testing sets');
    trnPct = 0.8;
    valPct = 1 - trnPct;
    tstPct = 0;
    splts  = splitDataset(1 : NCRVS, trnPct, valPct, tstPct);
    
    X = ZSLC(splts.trnIdx,:);
    Y = SSCR(splts.trnIdx,:);
else
    % Input is already the training set
    n = fprintf('Data already split into training sets');
    X = ZSLC;
    Y = SSCR;
end

jprintf(' ', toc(t), 1, 80 - n);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Start training Convolution Neural Net
t = tic;
n = fprintf('Training NN |');

snet = cell(1, size(Y,2)); % Iteratively predicts all PCs

% Determine parallelization
if par
    % Run with parallel processing [less stable]
    pll = 'yes';
else
    % Run with basic for loop [slower]
    pll = 'no';
end

% Run CNN to predict all PCs of the S-vector
for pc = 1 : pcs
    % for pc = 1 : 1 % Debug by running only 1 PC
    nnX = X';
    nnY = Y(:,pc)';
    
    % Run CNN
    snet{pc} = fitnet(NLAYERS, TRNFN);
    snet{pc} = train(snet{pc}, nnX, nnY, 'UseParallel', pll);
    
    n(pc+1) = fprintf(' %d |', pc);
end

jprintf(' ', toc(t), 1, 80 -sum(n));

%% Store Networks in a structure and make model's predictions
t = tic;
n = fprintf('Making predictions from %d-layer model', NLAYERS);

netStr = arrayfun(@(x) sprintf('N%d', x), 1 : pcs, 'UniformOutput', 0);
snet   = cell2struct(snet, netStr, 2);
ypre   = struct2array(structfun(@(n) n(ZSLC')', snet, 'UniformOutput', 0)');

jprintf(' ', toc(t), 1, 80 - n);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save Output Structures
t = tic;
n = fprintf('Saving outputs');

IN  = struct('SSCR', SSCR, 'ZSLC', ZSLC, 'NLAYERS', NLAYERS);
OUT = struct('SplitSets', splts, 'Predictions', ypre, 'Net', snet);

% Save results in structure
if sav
    if isSkls
        pnm = sprintf('%s_SklsNN_%dPatches_s%dPCs', tdate, NSEGS, pcs);
    else
        pnm = sprintf('%s_SScoreNN_%dSegment_s%dPCs', tdate, NSEGS, pcs);
    end
    
    save(pnm, '-v7.3', 'IN', 'OUT');
end

jprintf(' ', toc(t), 1, 80 - n);

fprintf('%s\nFinished training S-Vector NN [%.03f sec]\n%s', ...
    sepA, toc(tAll), sepB);

end

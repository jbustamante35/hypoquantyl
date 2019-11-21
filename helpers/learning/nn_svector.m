function [IN, OUT] = nn_svector(SSCR, ZSLC, NLAYERS, sav, par)
%% cnn_svector: CNN to predict contour segments given a Z-Vector slice
%
%
% Usage:
%   [IN, OUT] = nn_svector(SSCR, ZSLC, NLAYERS, sav, par)
%
% Input:
%   SSCR: PCA scores of S-Vectors [concatenated X-/Y-coordinates]
%   ZSLC: Z-Vectors slices with vectorized Z-Patch
%   NLAYERS: number of hidden layers
%   sav: boolean to save output structure in a .mat file
%   par: boolean to use parallel computing if available
%
% Output:
%   IN: structure containing the inputs used for the neural net run
%   OUT: structure containing predictions, network objects, and data splits
%

%% Extract some info about the dataset
% Total observations and number of scores used
[nSegs , pcs] = size(SSCR);
allSegs       = 1 : nSegs;
trnfn         = 'trainlm';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Split into training, validation, and testing sets
trnPct                   = 0.8;
valPct                   = 0.1;
tstPct                   = 1 - (trnPct + valPct);
[trnIdx, valIdx, tstIdx] = splitDataset(allSegs, trnPct, valPct, tstPct);

% Do the split
X = ZSLC(trnIdx,:);
Y = SSCR(trnIdx,:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Start training Convolution Neural Net
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
    snet{pc} = fitnet(NLAYERS, trnfn);
    snet{pc} = train(snet{pc}, nnX, nnY, 'UseParallel', pll);
end

% Store Networks in a structure
netStr = arrayfun(@(x) sprintf('N%d', x), 1 : pcs, 'UniformOutput', 0);
snet   = cell2struct(snet, netStr, 2);

%% PC Predictions using network model
ypre = zeros(size(SSCR));
for n = 1 : numel(netStr)
    ypre(:,n) = snet.(netStr{n})(ZSLC');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save Output Structure
% Split Datasets
Splt = struct('trnIdx', trnIdx, 'valIdx', valIdx, 'tstIdx', tstIdx);

% Full structure
IN  = struct('SSCR', SSCR, 'ZSLC', ZSLC, 'NLAYERS', NLAYERS);
OUT = struct('SplitSets', Splt, 'Predictions', ypre, 'Net', snet);

% Save results in structure
if sav
    pnm = sprintf('%s_SScoreNN_%dSegment_s%dPCs', ...
        tdate('s'), nSegs, pcs);
    save(pnm, '-v7.3', 'IN', 'OUT');    
end

end

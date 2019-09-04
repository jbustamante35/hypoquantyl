function [IN, OUT] = nn_svector(SSCR, ZSLC, NLAYERS, sav, par)
%% cnn_svector: CNN to predict contour segments given a Z-Vector slice
%
%
% Usage:
%   [IN, OUT] = nn_svector(SSCR, ZSLC, px, py, sav, vis, par)
%
% Input:
%   SSCR: PCA scores of S-Vectors [concatenated X-/Y-coordinates]
%   ZSLC: Z-Vectors slices
%   NLAYERS: number of hidden layers
%   sav:
%   par:
%
% Output:
%   IN:
%   OUT:
%

%% Extract some info about the dataset
% Input scale
[segs , pcs] = size(SSCR);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Split into training, validation, and testing sets
trnPct                   = 0.8;
valPct                   = 1 - trnPct;
tstPct                   = 0;
[trnIdx, valIdx, tstIdx] = divideblock(Shuffle(1:segs), trnPct, valPct, tstPct);

% Sort numerically
trnIdx = sort(trnIdx);
valIdx = sort(valIdx);
tstIdx = sort(tstIdx);

% Do the split
X = ZSLC(trnIdx,:);
Y = SSCR(trnIdx,:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Start training Convolution Neural Net
net = cell(1, size(Y,2)); % Iteratively predicts all PCs

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
    net{pc} = fitnet(NLAYERS, 'trainbr');
    net{pc} = train(net{pc}, nnX, nnY, 'UseParallel', pll);
end

%% Predictions per PC
ypre = zeros(size(Y));
for pc = 1 : pcs
    ypre(:,pc) = net{pc}(nnX);
end

% Convert from PCs to Midpoint-Normalized Segments
% predS = bsxfun(@plus, (ypreNet * pz.EigVectors'), pz.MeanVals);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save Output Structure
% Input (raw inputs)
Din  = struct('SSCR', SSCR, 'ZSLC', ZSLC, 'NLAYERS', NLAYERS);

% Output (predictions)
Splt = struct('trnIdx', trnIdx, 'valIdx', valIdx, 'tstIdx', tstIdx);
Dout = struct('Predictions', ypre, 'Net', net);

% Full structure
IN  = struct('DataIn', Din);
OUT = struct('SplitSets', Splt, 'DataOut', Dout);

% Save results in structure
if sav
    pnm = sprintf('%s_SScoreNN_%dSegment_s%dPCs', ...
        tdate('s'), segs, pcs);
    save(pnm, '-v7.3', 'IN', 'OUT');
    
end

end

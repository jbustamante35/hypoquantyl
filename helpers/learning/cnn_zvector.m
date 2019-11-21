function [IN, OUT] = cnn_zvector(IMGS, SCRS, sav, par)
%% cnn_zvector: CNN to predict Z-Vector slices given grayscale images
%
%
% Usage:
%   [IN, OUT] = cnn_zvector(SCRS, IMGS, px, py, pz, skp, sav, vis, par)
%
% Input:
%   SCRS: PCA scores of Z-Vector data set [N pcz]
%   IMGS: reshaped and rescaled hypocotyl images [x x 1 N]
%   px: output from PCA of X-coordinates
%   py: output from PCA of Y-coordinates
%   pz: output from PCA of Z-vectors
%   skp: boolean to skip running PLSR if not needed
%   sav: boolean to save output in a .mat file
%   par: boolean to use parallel computing if available
%
% Output:
%   IN: structure containing the inputs used for the neural net run
%   OUT: structure containing predictions, network objects, and data splits
%

%% Extract some info about the dataset
% Image input scale
% SCALE = 1;
nCrvs   = size(SCRS,1);
allCrvs = 1 : nCrvs;
pcs     = size(SCRS,2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Split into training, validation, and testing sets
trnPct                   = 0.8;
valPct                   = 1 - trnPct;
tstPct                   = 0;
[trnIdx, valIdx, tstIdx] = splitDataset(allCrvs, trnPct, valPct, tstPct);

% Do the split
X = IMGS(:,:,:,trnIdx); % For CNN
Y = SCRS(trnIdx,:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Start training Convolution Neural Net [midpoint CNN method]
znet = cell(1, size(Y,2)); % Iteratively predicts all PCs

% Determine parallelization
if par
    % Run with parallel processing [less stable]
    exenv = 'parallel';
else
    % Run with basic for loop [slower]
    exenv = 'cpu';
end

% Run CNN to predict all 6 parts of the Z-vector
for pc = 1 : pcs
    % for e = 1 : 1 % Debug by running only 1 PC
    cnnX = X;
    cnnY = Y(:,pc);
    
    % Create CNN Layers
    layers = [
        %         imageInputLayer([size(imgs,1) , size(imgs,2) , 1], ...
        imageInputLayer([size(IMGS,1) , size(IMGS,2) , 1], ...
        'Normalization', 'none');
        
        % Layer 1
        convolution2dLayer(7, 10, 'Padding', 'same');
        batchNormalizationLayer;
        reluLayer;
        maxPooling2dLayer(2,'Stride',2);
        
        %         averagePooling2dLayer(2,'Stride',2);
        
        % Layer 2
        convolution2dLayer(7, 5,'Padding','same');
        batchNormalizationLayer;
        reluLayer;
        maxPooling2dLayer(2,'Stride',2);
        
        % Layer 3
        convolution2dLayer(7, 3,'Padding','same');
        batchNormalizationLayer;
        reluLayer;
        maxPooling2dLayer(2,'Stride',2);
        
        %
        %     averagePooling2dLayer(2,'Stride',2)
        %
        %     convolution2dLayer(3,32,'Padding','same')
        %     batchNormalizationLayer
        %     reluLayer
        %
        %     convolution2dLayer(3,32,'Padding','same')
        %     batchNormalizationLayer
        %     reluLayer
        
        dropoutLayer(0.2);
        fullyConnectedLayer(size(cnnY,2));
        regressionLayer;
        ];
    
    % Configure CNN options
    miniBatchSize = 128;
    options = trainingOptions( ...
        'sgdm', ...
        'MiniBatchSize',         miniBatchSize, ...
        'MaxEpochs',             300, ...
        'InitialLearnRate',      1e-4, ...
        'Shuffle',              'every-epoch', ...
        'Plots',                'none', ...
        'Verbose',              true, ...
        'ExecutionEnvironment', exenv);
    
    % Removed [02-18-19]
    %     'LearnRateSchedule',     'piecewise', ...
    %     'LearnRateDropFactor',   0.1, ...
    %     'LearnRateDropPeriod',   20, ...
    %     'Plots',                'training-progress', ...
    
    % Run CNN
    znet{pc} = trainNetwork(cnnX, cnnY, layers, options);
end

% Store Networks in a structure
netStr = arrayfun(@(x) sprintf('N%d', x), 1 : pcs, 'UniformOutput', 0);
znet   = cell2struct(znet, netStr, 2);

%% Predictions per PC
ypre = zeros(size(SCRS));
for pc = 1 : pcs
    ypre(:,pc) = znet.(netStr{pc}).predict(IMGS);
end

%
% predZ_cnn = bsxfun(@plus, (ypre * pz.EigVectors'), pz.MeanVals);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save Output Structure
% Split Set Indices
Splt = struct('trnIdx', trnIdx, 'valIdx', valIdx, 'tstIdx', tstIdx);

% Full structure
IN  = struct('IMGS', IMGS, 'ZSCRS', SCRS);
OUT = struct('SplitSets', Splt, 'Predictions', ypre, 'Net', znet);

% Save results in structure
if sav
    pnm = sprintf('%s_ZScoreCNN_%dContours_z%dPCs', ...
        tdate('s'), nCrvs, pcs);
    save(pnm, '-v7.3', 'IN', 'OUT');
    
end

end

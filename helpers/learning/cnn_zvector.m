function [IN, OUT] = cnn_zvector(SCRS, IMGS, px, py, pz, skp, sav, vis, par)
%% cnn_zvector: CNN to predict Z-Vector slices given grayscale images
% 
%
% Usage:
%   [IN, OUT] = cnn_zvector(SCRS, IMGS, px, py, pz, skp, sav, vis, par)
%
% Input:
%   SCRS: PCA scores of Z-Vector data set [N pcz]
%   IMGS: reshaped and rescaled hypocotyl images [x x 1 N]
%   px:
%   py:
%   pz:
%   skp: skip running PLSR 
%   sav:
%   vis:
%   par:
%
% Output:
%   IN:
%   OUT:
%

%% Extract some info about the dataset
% Principal Components
PCX = length(px.EigValues);
PCY = length(py.EigValues);
PCZ = length(pz.EigValues);
PCR = 10;

% Image input scale
% SCALE = 1;
% nCrvs = numel(CRVS);
nCrvs = length(pz.PCAscores);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Split into training, validation, and testing sets
trnPct                   = 0.8;
valPct                   = 1 - trnPct;
tstPct                   = 0;
[trnIdx, valIdx, tstIdx] = ...
    divideblock(Shuffle(1:nCrvs), trnPct, valPct, tstPct);

% Sort numerically
trnIdx = sort(trnIdx);
valIdx = sort(valIdx);
tstIdx = sort(tstIdx);

% Do the split
X = IMGS(:,:,:,trnIdx); % For CNN
Y = SCRS(trnIdx,:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Start training PLS Regression [midpoint PLSR method]
% Skip if skp set to true
if ~skp
    % Prep image data
    PLSRX = double(reshape(imgs, [prod(imSize(1:2)) imSize(3)])'); % For PLSR
    plsrX = PLSRX(trnIdx, :);
    
    % PLSR on midpoint coordinates and cropped images
    rttl = sprintf('r%dHypocotylsTrained_%dHypocotylsTotal', ...
        length(trnIdx), nCrvs);
    pr   = plsrAnalysis(plsrX, Y, PCR, sav, rttl, 0);
    
    % Project beta onto X values to make predictions of midpoint locations
    beta       = pr.Beta;
    ypre       = [ones(size(PLSRX,1) , 1) PLSRX] * beta;
    ypre       = bsxfun(@plus, (ypre * pz.EigVectors'), pz.MeanVals);
    predZ_plsr = reshape(ypre', size(pz.InputData));
else
    predZ_plsr = [];
    pr         = [];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Start training Convolution Neural Net [midpoint CNN method]
net = cell(1, size(Y,2)); % Iteratively predicts all PCs

% Determine parallelization
if par    
    % Run with parallel processing [less stable]
    exenv = 'parallel';
else
    % Run with basic for loop [slower]
    exenv = 'cpu';
end

% Run CNN to predict all 6 parts of the Z-vector
for e = 1 : size(Y,2)
    % for e = 1 : 1 % Debug by running only 1 PC
    cnnX = X;
    cnnY = Y(:,e);
    
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
        'Plots',                'training-progress', ...
        'Verbose',              true, ...
        'ExecutionEnvironment', exenv);
    
    % Removed [02-18-19]
    %     'LearnRateSchedule',     'piecewise', ...
    %     'LearnRateDropFactor',   0.1, ...
    %     'LearnRateDropPeriod',   20, ...
    
    % Run CNN
    net{e} = trainNetwork(cnnX, cnnY, layers, options);
end

%% Predictions per PC
ypreNet = [];
for e = 1 : numel(net)
    ypreNet(:,e) = net{e}.predict(IMGS);
end

%
predZ_cnn = bsxfun(@plus, (ypreNet * pz.EigVectors'), pz.MeanVals);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plotting functions to visualize predictions
% This will be replaced with the plotPredictions function once I reshape the
% predicted matrices correctly.
if vis
    fprintf('\n\nNote [%s]\nVisualization does nothing yet!\n\n', tdate('l'));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save Output Structure
% Input (raw and PCA data)
Din  = struct('Xcrd', px.InputData, 'Ycrd', py.InputData, 'Zvec', pz.InputData);

% Output (predictions)
Trng = struct('trnIdx', trnIdx, 'valIdx', valIdx, 'tstIdx', tstIdx, ...
    'IMGS', IMGS, 'MIDS', SCRS);
Dout = struct('plsrPredictions', predZ_plsr, 'cnnPredictions', predZ_cnn, ...
    'PLSR', pr, 'NET', net);

% Full structure
IN  = struct('DataIn', Din);
OUT = struct('TrainingProcessed', Trng, 'DataOut', Dout);

% Save results in structure
if sav
    pnm = sprintf('%s_PredictionsCNN_%dContours_m%dPCs_x%dPCs_y%dPCs', ...
        tdate('s'), nCrvs, PCZ, PCX, PCY);
    save(pnm, '-v7.3', 'IN', 'OUT');
    
end

end

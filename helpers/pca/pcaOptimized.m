function [IN, OUT, figs] = pcaOptimized(C, D, sav, vis)
%% Constants
figs = 1 : 6;
flp  = 0;
pcx  = 3;
pcy  = 3;
pcz  = 6;
pcr  = 0;

%%
[T,Z]   = collectTrainingSet(D, sav);
ttlSegs = D(1).NumberOfSegments;
numCrvs = numel(D);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Contour Predictions by Regressing Images on Midpoint Coordinates
% Collect and reshape midpoints of all segments from all contours
rastMids = Z.zVect(:,1:2);
rastSz   = size(rastMids);
nSegs    = ttlSegs;   % number of segments per contour
nDims    = rastSz(2); % x and y dimensions
nObsv    = numCrvs;   % number of observations

% Reshape-Transpose method
mids   = zeros(nObsv , (nSegs * nDims));
midsSz = size(mids);
midsX  = reshape(rastMids(:,1), [midsSz(2)/2 midsSz(1)])';
midsY  = reshape(rastMids(:,2), [midsSz(2)/2 midsSz(1)])';
mids   = [midsX , midsY];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Run PCA with defined number of coordinates
% PCA on x-coordinates
rastX = Z.xCrds;
xttl  = sprintf('x%dHypocotyls', numCrvs);
px    = pcaAnalysis(rastX, pcx, [1 size(rastX,2)], sav, xttl, 0);

% PCA on y-coordinates
rastY = Z.yCrds;
yttl  = sprintf('y%dHypocotyls', numCrvs);
py    = pcaAnalysis(rastY, pcy, [1 size(rastY,2)], sav, yttl, 0);

% PCA on Midpoint Coordinates
zttl = sprintf('m%dHypocotyls', numCrvs);
pz   = pcaAnalysis(mids, pcz, [1 size(mids,2)], sav, zttl, 0);

%% Prep input data for CNN
% Resize hypocotyl images to isz x isz
isz      = 101;
imgs_raw = arrayfun(@(x) x.getImage('gray'), C, 'UniformOutput', 0);
imgs_rsz = cellfun(@(x) imresize(x, [isz isz]), imgs_raw, 'UniformOutput', 0);
imgs     = cat(3, imgs_rsz{:});
imSize   = size(imgs);

% Reshape image data as X values and use Midpoint PCA scores as Y values
X = double(reshape(imgs, [imSize(1:2), 1, imSize(3)]));
Y = pz.PCAscores;

% Split into training, validation, and testing sets
trnPct              = 0.8;
valPct              = 1 - trnPct;
tstPct              = 0;
[trnIdx, valIdx, ~] = divideblock(Shuffle(1:numCrvs), trnPct, valPct, tstPct);
trnIdx              = sort(trnIdx);
valIdx              = sort(valIdx);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Run PCA on optimal number of PCs [midpoint CNN method]
netT = cell(1, size(Y,2)); % Iteratively predicts all PCs

for e = 1 : size(Y,2)
    % for e = 1 : 1
    cnnX = reshape(imgs, [size(imgs,1) , size(imgs,2) , 1 , size(imgs,3)]);
    cnnY = Y(:,e);
    
    % Create CNN Layers
    layers = [
        imageInputLayer([size(imgs,1) , size(imgs,2) , 1], 'Normalization', 'none');
        
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
        'ExecutionEnvironment', 'cpu');
    
    % Removed [02-18-19]
    %     'LearnRateSchedule',     'piecewise', ...
    %     'LearnRateDropFactor',   0.1, ...
    %     'LearnRateDropPeriod',   20, ...
    
    % Run CNN
    netT{e} = trainNetwork(cnnX, cnnY, layers, options);
end

%% Predictions per PC
ypreNet = [];
for e = 1 : numel(netT)
    ypreNet(:,e) = netT{e}.predict(cnnX);
end

%
preMids     = bsxfun(@plus, (ypreNet * pz.EigVectors'), pz.MeanVals);
preMids_cnn = preMids;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plotting functions to visualize predictions
if vis
    figs(1) = figure(1);
    figs(2) = figure(2);
    figs(3) = figure(3);
    figs(4) = figure(4);
    figs(5) = figure(5);
    figs(6) = figure(6);
    
    %% Plot Frankencotyls to show backbone predictions [single]
    [idx1 , idx2] = deal(3);
    %
    %     tmpX = pz.SimData(:, 1:(end/2))';
    %     tmpY = pz.SimData(:, (end/2 + 1) : end)';
    %     preMids = [tmpX(:) , tmpY(:)];
    tmpX    = preMids(:, 1:(end/2))';
    tmpY    = preMids(:, (end/2 + 1) : end)';
    preMids = [tmpX(:) , tmpY(:)];
    
    [segInp_truth, ~] = ...
        plotFrankencotyls(idx1, idx2, px, py, pz, preMids, D, ...
        'truth',     flp, sav, 4);
    [~, segSim_pred] = ...
        plotFrankencotyls(idx1, idx2, px, py, pz, preMids, D, ...
        'predicted', flp, sav, 5);
    
    % Plot predictions and truths
    chkX = segInp_truth{1};
    chkY = segSim_pred{1};
    I    = C(idx1).getImage('gray');
    P    = [pcr, pcz, pcx, pcy];
    plotGroundTruthAndPrediction(chkX, chkY, I, idx1, P, sav, 6);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Show n Frankencotyls to show backbone predictions [looping, training]
    for n = trnIdx
        [segInp_truth, ~] = ...
            plotFrankencotyls(n, n, px, py, pz, preMids, D, ...
            'truth',     flp, sav, 4);
        
        [~, segSim_pred] = ...
            plotFrankencotyls(n, n, px, py, pz, preMids, D, ...
            'predicted', flp, sav, 5);
        
        % Plot predictions and truths
        chkX = segInp_truth{1};
        chkY = segSim_pred{1};
        I    = C(n).getImage('gray');
        P    = [pcr, pcz, pcx, pcy];
        plotGroundTruthAndPrediction(chkX, chkY, I, n, P, sav, 6);
        
    end
    
    %% Show n Frankencotyls to show backbone predictions [looping, validation]
    for n = valIdx
        [segInp_truth, ~] = ...
            plotFrankencotyls(n, n, px, py, pz, preMids, D, ...
            'truth',     flp, sav, 4);
        
        [~, segSim_pred] = ...
            plotFrankencotyls(n, n, px, py, pz, preMids, D, ...
            'predicted', flp, sav, 5);
        
        % Plot predictions and truths
        chkX = segInp_truth{1};
        chkY = segSim_pred{1};
        I    = C(n).getImage('gray');        
        P    = [pcr, pcz, pcx, pcy];
        plotGroundTruthAndPrediction(chkX, chkY, I, n, P, sav, 6);
        
    end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save Output Structure
% Input (raw and PCA data)
TSet = struct('T', T, 'Z', Z);
Din  = struct('X', X, 'Y', Y, 'Z', mids);

% Output (predictions)
Trng = struct('trnIdx', trnIdx, 'valIdx', valIdx, 'IMGS', X, 'MIDS', Y);
Dout = struct('preds', preMids_cnn);

% Full structure
IN  = struct('TrainingRaw',       TSet, 'DataIn', Din);
OUT = struct('TrainingProcessed', Trng, 'DataOut', Dout);

% Save results in structure
if sav
    pnm = sprintf('%s_PredictionsCNN_%dContours_m%dPCs_x%dPCs_y%dPCs', ...
        tdate('s'), numCrvs, pcz, pcx, pcy);
    save(pnm, '-v7.3', 'IN', 'OUT');
end

end

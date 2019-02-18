function [IN, OUT] = pcaOptimized(C, D, vis)
%% Constants
figs = 1 : 5;
sav = 0;
flp = 0;
pct = 0.99999999;
maxPC = 10;

%%
[T,Z] = collectTrainingSet(D, sav);

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
mids   = reshape(rastMids, [midsSz(2) midsSz(1)])';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Run PCA multiple times to get variance explained [midpoint coordinates]
% Run pcaCheck n times
% pczRange = 1 : size(mids,2);
pczRange = 1 : maxPC;
zttl     = sprintf('m%dHypocotyls', numCrvs);
pzAll    = cell(1 , max(pczRange));

for z = pczRange
    fprintf('Running PCA on Midpoints...%d PCs\n', z);
    pzAll{z} = pcaAnalysis(mids, z, [1 size(mids,2)], sav, zttl, 0);
end

%% Run PCA multiple times to get variance explained [x-coordinates]
% Run pcaCheck n times
rastX    = Z.xCrds;
xttl     = sprintf('x%dHypocotyls', numCrvs);
% pcxRange = 1 : size(rastX,2);
pcxRange = 1 : maxPC;
pxAll    = cell(1 , max(pcxRange));

for x = pcxRange
    fprintf('Running PCA on x-coordinates...%d PCs\n', x);
    pxAll{x} = pcaAnalysis(rastX, x, [1 size(rastX,2)], sav, xttl, 0);
end

%% Run PCA multiple times to get variance explained [y-coordinates]
% Run pcaCheck n times
rastY    = Z.yCrds;
yttl     = sprintf('y%dHypocotyls', numCrvs);
% pcyRange = 1 : size(rastY,2);
pcyRange = 1 : maxPC;
pyAll    = cell(1 , max(pcyRange));

for y = pcyRange
    fprintf('Running PCA on y-coordinates...%d PCs\n', y);
    pyAll{y} = pcaAnalysis(rastY, y, [1 size(rastY,2)], sav, yttl, 0);
end

%% Run PCA on optimal number of PCs [midpoint coordinates]
ZZ          = cat(1, pzAll{:});
scrZ        = arrayfun(@(z) nonzeros(z.EigValues), ZZ, 'UniformOutput', 0);
[varZ, pcz] = variance_explained(scrZ{end}, pct);

% Run PCA and compare with multi-run (cuz i is stoopehd)
pzOpt = pzAll{pcz};
pz    = pcaAnalysis(mids, pcz, [1 size(mids,2)], sav, zttl, 0);

%% Run PCA on optimal number of PCs [x-coordinates]
XX          = cat(1, pxAll{:});
scrX        = arrayfun(@(x) nonzeros(x.EigValues), XX, 'UniformOutput', 0);
[varX, pcx] = variance_explained(scrX{end}, pct);
pxOpt       = pxAll{pcx};
px          = pcaAnalysis(rastX, pcx, [1 size(rastX,2)], sav, xttl, 0);

%% Run PCA on optimal number of PCs [y-coordinates]
YY          = cat(1, pyAll{:});
scrY        = arrayfun(@(y) nonzeros(y.EigValues), YY, 'UniformOutput', 0);
[varY, pcy] = variance_explained(scrY{end}, pct);
pyOpt       = pyAll{pcy};
py          = pcaAnalysis(rastY, pcy, [1 size(rastY,2)], sav, yttl, 0);

%% PLS Regression on optimal number of PCs [midpoint coordinates]
% Resize hypocotyl images to 25x25
isz      = 101;
imgs_raw = arrayfun(@(x) x.getImage('gray'), C, 'UniformOutput', 0);
imgs_rsz = cellfun(@(x) imresize(x, [isz isz]), imgs_raw, 'UniformOutput', 0);
imgs     = cat(3, imgs_rsz{:});
imSize   = size(imgs);

% Reshape image data as X values and use Midpoint PCA scores as Y values
X = double(reshape(imgs, [prod(imSize(1:2)) imSize(3)])');
Y = pz.PCAscores;

% Split into training, validation, and testing sets
trnPct  = 0.8;
valPct  = 1 - trnPct;
tstPct  = 0;
[trnIdx, valIdx, ~] = divideblock(numCrvs, trnPct, valPct, tstPct);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Run PCA multiple times to get variance explained [midpoint PLSR method]
% Run pcaCheck n times
pxls     = X(trnIdx,:);
mpts     = Y(trnIdx,:);
% pcrRange = 1 : 49; % plsregress has max NCOMP of 49
pcrRange = 1 : 8; % plsregress has max NCOMP of 8
prAll    = cell(1 , max(pcrRange));

% Iteratively run linear regression and predict midpoints based on images
for r = pcrRange
    fprintf('Running PLSR on midpoint coordinates...%d PCs\n', r);
    %     [Xloadings, Yloadings, Xscores, Yscores, beta, pctVar, mse, stats, Weights] = ...
    [Xloadings, Yloadings, Xscores, Yscores, beta, pctVar, mse, stats] = ... % laptop version of plsr has no Weights output
        plsregress(pxls, mpts, r);
    
    prAll{r} = struct('Xloadings', Xloadings, 'Yloadings', Yloadings, ...
        'Xscores', Xscores, 'Yscores', Yscores, 'beta', beta, ...
        'pctVar', pctVar, 'mse', mse, 'stats', stats); % laptop version of plsr has no Weights output
    %         'pctVar', pctVar, 'mse', mse, 'stats', stats, 'Weights', Weights);
    
    % Save results in structure
    if sav
        pnm = sprintf('%s_MidpointPLS_%dContours_r%dPCs_m%dPCs_x%dPCs_y%dPCs', ...
            tdate('s'), numCrvs, r, pcz, pcx, pcy);
        midPredictions = prAll{r};
        save(pnm, '-v7.3', 'midPredictions');
    end
    
end

%% Run PCA on optimal number of PCs [midpoint PLSR method]
RR    = cat(1, prAll{:});
varR  = find(cumsum(RR(end).pctVar(1,:)) > pct);

try
    pcr   = varR(1);
    prOpt = prAll{pcr};
catch
    pcr   = numel(RR);
    prOpt = prAll{pcr};
end

% Project beta onto X values to make predictions of midpoint locations
beta    = prOpt.beta;
ypre    = [ones(size(X,1) , 1) X] * beta;
ypre    = bsxfun(@plus, (ypre * pz.EigVectors'), pz.MeanVals);
preMids = reshape(ypre', rastSz);

%
preMids_plsr = preMids;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Run PCA on optimal number of PCs [midpoint CNN method]
for e = 1 : size(Y,2)
    % for e = 1 : 1
    cnnX = reshape(imgs, [size(imgs,1) , size(imgs,2) , 1 , size(imgs,3)]);
    cnnY = Y(:,e);
    
    %
    %     layers = [
    %         imageInputLayer([size(imgs,1) , size(imgs,2) , 1], 'Normalization', 'none');
    %
    %         convolution2dLayer(3,8,'Padding','same');
    %         batchNormalizationLayer;
    %         reluLayer;
    %
    %         averagePooling2dLayer(2,'Stride',2);
    %
    %         convolution2dLayer(3,16,'Padding','same')
    %         batchNormalizationLayer
    %         reluLayer
    %
    %         averagePooling2dLayer(2,'Stride',2)
    %
    %         convolution2dLayer(3,32,'Padding','same')
    %         batchNormalizationLayer
    %         reluLayer
    %
    %         convolution2dLayer(3,32,'Padding','same')
    %         batchNormalizationLayer
    %         reluLayer
    %
    %         dropoutLayer(0.2)
    %         fullyConnectedLayer(size(cnnY,2));
    %         regressionLayer
    %         ];
    
    %
    layers = [
        imageInputLayer([size(imgs,1) , size(imgs,2) , 1], 'Normalization', 'none');
        
        convolution2dLayer(25, 20, 'Padding', 'same');
        batchNormalizationLayer;
        reluLayer;
        
        maxPooling2dLayer(2,'Stride',2);
        %     averagePooling2dLayer(2,'Stride',2);
        %
        %     convolution2dLayer(3,16,'Padding','same')
        %     batchNormalizationLayer
        %     reluLayer
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
    
    %
    miniBatchSize = 128;
    options = trainingOptions( ...
        'sgdm', ...
        'MiniBatchSize',         miniBatchSize, ...
        'MaxEpochs',             20, ...
        'InitialLearnRate',      1e-6, ...
        'LearnRateSchedule',     'piecewise', ...
        'LearnRateDropFactor',   0.1, ...
        'LearnRateDropPeriod',   20, ...
        'Shuffle',              'every-epoch', ...
        'Plots',                'training-progress', ...
        'Verbose',              true, ...
        'ExecutionEnvironment', 'cpu');
    
    %
    netT{e} = trainNetwork(cnnX, cnnY, layers, options);
end

%% Predictions on all PCs
% ypreNet = net.predict(cnnX);
% ypreNet = bsxfun(@plus, (ypreNet * pz.EigVectors'), pz.MeanVals);
% preMids = reshape(ypreNet', rastSz);
%
% %
% preMids_cnn = preMids;

%% Predictions per PC
for e = 1 : numel(netT)
    ypreNet(:,e) = netT{e}.predict(cnnX);
end

%
ypreNet = bsxfun(@plus, (ypreNet * pz.EigVectors'), pz.MeanVals);
preMids = reshape(ypreNet', rastSz);

%
preMids_cnn = preMids;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Check midpoint predictions
midPredictions = struct('Images', X, 'Scores', Y, 'Predictions', preMids);

% Save results in structure
if sav
    pnm = sprintf('%s_MidpointPLS_%dContours_p%dPCs_m%dPCs_x%dPCs_y%dPCs', ...
        tdate('s'), numCrvs, pcr, pcz, pcx, pcy);
    save(pnm, '-v7.3', 'midPredictions');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plot Frankencotyls to show backbone predictions [single]
if vis
    figs(1) = figure(1);
    figs(2) = figure(2);
    figs(3) = figure(3);
    figs(4) = figure(4);
    figs(5) = figure(5);
    figs(6) = figure(6);
    
    %% Plot optimized PCA results [x-/y-/z-coordinates]
    set(0, 'CurrentFigure', figs(4));
    cla;clf;
    
    hold on;
    plot([0 ; varX], 'LineStyle', '-', 'LineWidth', 4, 'Color', 'b');
    plot([0 ; varY], 'LineStyle', '-', 'LineWidth', 4, 'Color', 'r');
    plot([0 ; varZ], 'LineStyle', '-', 'LineWidth', 4, 'Color', 'k');
    
    xlim([1 maxPC]);
    xlabel('Principal Components', 'FontWeight', 'bold', 'FontSize', 12);
    ylabel('% Variance', 'FontWeight', 'bold', 'FontSize', 12);
    legend('x-coordinates', 'y-coordinates', 'midpoint coordinates');
    ttl = sprintf('Variance Explained\nx-coordinates | y-coordinates | midpoint coordinates');
    title(ttl, 'FontWeight', 'bold', 'FontSize', 12);
    
    %%
    idx1 = 3;
    idx2 = 3;
    [segInp_truth, segSim_truth] = ...
        plotFrankencotyls(idx1, idx2, px, py, pz, preMids, D, ...
        'truth',     flp, sav, 4);
    [segInp_pred, segSim_pred] = ...
        plotFrankencotyls(idx1, idx2, px, py, pz, preMids, D, ...
        'predicted', flp, sav, 5);
    
    % Plot predictions and truths
    chkX = segInp_truth{1};
    chkY = segSim_pred{1};
    I = C(idx1).getImage('gray');
    P = [pcr, pcz, pcx, pcy];
    
    plotGroundTruthAndPrediction(chkX, chkY, I, idx1, P, sav, 6);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %     %% Plot Frankencotyls to show backbone predictions [looping, same]
    %     nIdx = 1 : numCrvs;
    %     for n = nIdx
    %         [segInp_truth, segSim_truth] = ...
    %             plotFrankencotyls(n, n, px, py, pz, preMids, D, ...
    %             'truth',     flp, sav, 1);
    %
    %         [segInp_pred, segSim_pred] = ...
    %             plotFrankencotyls(n, n, px, py, pz, preMids, D, ...
    %             'predicted', flp, sav, 2);
    %
    %         % Plot predictions and truths
    %         chkX = segInp_truth{1};
    %         chkY = segSim_pred{1};
    %         I = C(n).getImage('gray');
    %         P = [pcr, pcz, pcx, pcy];
    %
    %         plotGroundTruthAndPrediction(chkX, chkY, I, n, P, sav, 3);
    %
    %     end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Output structure
% Input (raw and PCA data)
TSet = struct('T', T, 'Z', Z);
Din  = struct('X', X, 'Y', Y, 'Z', mids);
POpt = struct('pX', pxOpt, 'pY', pyOpt, 'pZ', pzOpt);
PAll = struct('pX', pxAll, 'pY', pyAll, 'pZ', pzAll);

% Output (predictions)
Trng = struct('trnIdx', trnIdx, 'valIdx', valIdx, 'IMGS', X, 'MIDS', Y);
yPLS = struct('pRall', prAll, 'pRopt', prOpt, 'preds', preMids_plsr);
yCNN = struct('preds', preMids_cnn);

% Full structure
IN  = struct('TSet', TSet, 'Din', Din, 'POpt', POpt, 'PAll', PAll);
OUT = struct('TIdx', Trng, 'PLSR', yPLS, 'CNN', yCNN, 'P', midPredictions);

end

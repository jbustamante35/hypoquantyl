function [IN, OUT, figs] = cnn_zvector(C, D, px, py, pz, predMethod, sav, vis)
%% cnn_zvector:
%
%
% Usage:
%   [IN, OUT, figs] = cnn_zvector(C, D, px, py, pz, predMethod, sav, vis)
%
% Input:
%   C:
%   D:
%   px:
%   py:
%   pz:
%   predMethod:
%   sav:
%   vis:
%
% Output:
%   IN:
%   OUT:
%   figs:
%

%% Constants
% Misc constants
figs = 1 : 3;
flp  = 0;

% Principal Components
pcx = length(px.EigValues);
pcy = length(py.EigValues);
pcz = length(pz.EigValues);
pcr = 10;

% Image input scale
imScl = 1;

%% Concatenate necessary training data into single structure
ttlSegs = D(1).NumberOfSegments;
numCrvs = numel(D);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Prep input data for CNN
% Resize hypocotyl images to isz x isz
isz      = ceil(size(C(1).getImage('gray')) * imScl);
imgs_raw = arrayfun(@(x) x.getImage('gray'), C, 'UniformOutput', 0);
imgs_rsz = cellfun(@(x) imresize(x, isz), imgs_raw, 'UniformOutput', 0);
imgs     = cat(3, imgs_rsz{:});
imSize   = size(imgs);

% Reshape image data as X values and use Midpoint PCA scores as Y values
IMGS = double(reshape(imgs, [imSize(1:2), 1, imSize(3)]));
SCRS = pz.PCAscores;

%% Split into training, validation, and testing sets
trnPct              = 0.8;
valPct              = 1 - trnPct;
tstPct              = 0;
[trnIdx, valIdx, ~] = divideblock(Shuffle(1:numCrvs), trnPct, valPct, tstPct);
% [trnIdx, valIdx, ~] = divideblock(numCrvs, trnPct, valPct, tstPct);
trnIdx              = sort(trnIdx);
valIdx              = sort(valIdx);

% Do the split
X = IMGS(:,:,:,trnIdx); % For CNN
Y = SCRS(trnIdx,:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Start training PLS Regression [midpoint PLSR method]
% Prep image data
PLSRX = double(reshape(imgs, [prod(imSize(1:2)) imSize(3)])'); % For PLSR
plsrX = PLSRX(trnIdx, :);

% PLSR on midpoint coordinates and cropped images
rttl = sprintf('r%dHypocotylsTrained_%dHypocotylsTotal', ...
    length(trnIdx), numCrvs);
pr   = plsrAnalysis(plsrX, Y, pcr, sav, rttl, 0);

% Project beta onto X values to make predictions of midpoint locations
beta       = pr.Beta;
ypre       = [ones(size(PLSRX,1) , 1) PLSRX] * beta;
ypre       = bsxfun(@plus, (ypre * pz.EigVectors'), pz.MeanVals);
predZ_plsr = reshape(ypre', size(pz.InputData));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Start training Convolution Neural Net [midpoint CNN method]
net = cell(1, size(Y,2)); % Iteratively predicts all PCs

for e = 1 : size(Y,2)
    % for e = 1 : 1
    cnnX = X;
    cnnY = Y(:,e);
    
    % Create CNN Layers
    layers = [
        imageInputLayer([size(imgs,1) , size(imgs,2) , 1], ...
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
        'ExecutionEnvironment', 'cpu');
    %         'ExecutionEnvironment', 'parallel'); % JDev's parallel pool is broken
    
    
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
    %     figs(1) = figure(1);
    %     figs(2) = figure(2);
    %     figs(3) = figure(3);
    %
    %     %%
    %     switch predMethod
    %         case 'plsr'
    %             predZ     = predZ_plsr;
    %             cnvMethod = @(x) x;
    %
    %         case 'cnn'
    %             predZ     = predZ_cnn;
    %             catCrd    = @(x) x(:);
    %
    %             % Only extracts x-/y-fields [DEPRECATED]
    % %             cnvMethod = @(x) [catCrd(x(:, 1:(end/2))') , ...
    % %                 catCrd(x(:, (end/2 + 1) : end)')];
    %
    %             % Extracts indices for all 6 fields
    %             idx1      = @(x) 1 + (ttlSegs * (x - 1));
    %             idx2      = @(x) (x * ttlSegs);
    %             zOrder = [1 4 , 2 5 , 3 6];
    %             cnvIdx = arrayfun(@(x) idx1(x) : idx2(x), zOrder, 'UniformOutput', 0);
    %
    %             % Linearizes each field into separate columns
    %             cnvZ      = @(y) cellfun(@(x) catCrd(y(:, x)'), cnvIdx, 'UniformOutput', 0);
    %             cnvMethod = @(x) cell2mat(cnvZ(x));
    %
    %         otherwise
    %             predZ     = predZ_cnn;
    %             catCrd    = @(x) x(:);
    %
    %             % Extracts indices for all 6 fields
    %             idx1   = @(x) 1 + (ttlSegs * (x - 1));
    %             idx2   = @(x) (x * ttlSegs);
    %             zOrder = [1 4 , 2 5 , 3 6];
    %             cnvIdx = arrayfun(@(x) idx1(x) : idx2(x), zOrder, 'UniformOutput', 0);
    %
    %             % Linearizes each field into separate columns
    %             cnvZ      = @(y) cellfun(@(x) catCrd(y(:, x)'), cnvIdx, 'UniformOutput', 0);
    %             cnvMethod = @(x) cell2mat(cnvZ(x));
    %     end
    %
    %     %% Plot Frankencotyls to show backbone predictions [single]
    %     idx = 20;
    %
    %     % DEBUG: Check simulated ground truths
    %     %     tmpX = pz.SimData(:, 1:(end/2))';
    %     %     tmpY = pz.SimData(:, (end/2 + 1) : end)';
    %     %     preMids = [tmpX(:) , tmpY(:)];
    %
    %     %     tmpX    = preMids(:, 1:(end/2))';
    %     %     tmpY    = preMids(:, (end/2 + 1) : end)';
    %     %     tmpMids = [tmpX(:) , tmpY(:)];
    %
    %     tmpZ = cnvMethod(predZ);
    %
    %     [segInp_truth, ~] = ...
    %         plotPredictions(idx, px, py, pz, tmpZ, D, 'truth', sav, 1);
    %     [~, segSim_pred] = ...
    %         plotPredictions(idx, px, py, pz, tmpZ, D, 'predicted', sav, 2);
    %
    %     %% Plot predictions and truths
    %     chkX = segInp_truth{1};
    %     chkY = segSim_pred{1};
    %     I    = C(idx).getImage('gray');
    %     P    = [pcr, pcz, pcx, pcy];
    %     plotGroundTruthAndPrediction(chkX, chkY, I, idx, P, sav, 3);
    %
    %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %     %% Show n Frankencotyls to show backbone predictions [looping, training]
    %     currDir = pwd;
    %     if sav
    %         trnDir = sprintf('%s', [pwd '/' 'trained_examples']);
    %         eval(sprintf('mkdir %s', trnDir));
    %         eval(sprintf('cd %s', trnDir));
    %     end
    %
    %     for n = trnIdx
    %
    %         tmpX    = predZ(:, 1:(end/2))';
    %         tmpY    = predZ(:, (end/2 + 1) : end)';
    %         tmpZ = [tmpX(:) , tmpY(:)];
    %
    %         [segInp_truth, ~] = ...
    %             plotFrankencotyls(n, n, px, py, pz, tmpZ, D, ...
    %             'truth',     flp, sav, 1);
    %
    %         [~, segSim_pred] = ...
    %             plotFrankencotyls(n, n, px, py, pz, tmpZ, D, ...
    %             'predicted', flp, sav, 2);
    %
    %         % Plot predictions and truths
    %         chkX = segInp_truth{1};
    %         chkY = segSim_pred{1};
    %         I    = C(n).getImage('gray');
    %         P    = [pcr, pcz, pcx, pcy];
    %         plotGroundTruthAndPrediction(chkX, chkY, I, n, P, sav, 3);
    %
    %         pause(1);
    %     end
    %
    %     eval(sprintf('cd %s', currDir));
    %
    %     %% Show n Frankencotyls to show backbone predictions [looping, validation]
    %     if sav
    %         valDir = sprintf('%s', [pwd '/' 'validation_examples']);
    %         eval(sprintf('mkdir %s', valDir));
    %         eval(sprintf('cd %s', valDir));
    %     end
    %
    %     for n = valIdx
    %
    %         tmpX    = predZ(:, 1:(end/2))';
    %         tmpY    = predZ(:, (end/2 + 1) : end)';
    %         tmpZ = [tmpX(:) , tmpY(:)];
    %
    %         [segInp_truth, ~] = ...
    %             plotFrankencotyls(n, n, px, py, pz, tmpZ, D, ...
    %             'truth',     flp, sav, 1);
    %
    %         [~, segSim_pred] = ...
    %             plotFrankencotyls(n, n, px, py, pz, tmpZ, D, ...
    %             'predicted', flp, sav, 2);
    %
    %         % Plot predictions and truths
    %         chkX = segInp_truth{1};
    %         chkY = segSim_pred{1};
    %         I    = C(n).getImage('gray');
    %         P    = [pcr, pcz, pcx, pcy];
    %         plotGroundTruthAndPrediction(chkX, chkY, I, n, P, sav, 3);
    %
    %         pause(1);
    %     end
    %
    %     eval(sprintf('cd %s', currDir));
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save Output Structure
% Input (raw and PCA data)
Din  = struct('Xcrd', px.InputData, 'Ycrd', py.InputData, 'Zvec', pz.InputData);

% Output (predictions)
Trng = struct('trnIdx', trnIdx, 'valIdx', valIdx, 'IMGS', IMGS, 'MIDS', SCRS);
Dout = struct('plsrPredictions', predZ_plsr, 'cnnPredictions', predZ_cnn, ...
    'PLSR', pr, 'NET', net);

% Full structure
IN  = struct('DataIn', Din);
OUT = struct('TrainingProcessed', Trng, 'DataOut', Dout);

% Save results in structure
if sav
    pnm = sprintf('%s_PredictionsCNN_%dContours_m%dPCs_x%dPCs_y%dPCs', ...
        tdate('s'), numCrvs, pcz, pcx, pcy);
    save(pnm, '-v7.3', 'IN', 'OUT');
    
end

end

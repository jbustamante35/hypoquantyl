function [IN, OUT] = znnTrainer(IMGS, ZSCRS, splts, sav, par, vrb)
%% znnTrainer: CNN to predict Z-Vector slices given grayscale images
%
%
% Usage:
%   [IN, OUT] = znnTrainer(IMGS, SCRS, splts, sav, par, vrb)
%
% Input:
%   SCRS: PCA scores of Z-Vector data set [N pcz]
%   IMGS: reshaped and rescaled hypocotyl images [x x 1 N]
%   splts: dataset splits of training, validation, testing indices
%   sav: boolean to save output in a .mat file
%   par: boolean to use parallel computing if available
%   vrb: boolean to determine verbosity level
%
% Output:
%   IN: structure containing the inputs used for the neural net run
%   OUT: structure containing predictions, network objects, and data splits
%

%% Setup and Extract some info about the datase
switch nargin
    case 2
        sav = 0;
        par = 0;
        vrb = 0;
    case 3
        par = 0;
        vrb = 0;
    case 4
        vrb = 0;
    case 5
        vrb = 0;
    case 6
    otherwise
        fprintf(2, 'Incorrect inputs (%d)\n', nargin);
        [IN , OUT] = deal([]);
        return;
end

% Image input scale
% SCALE = 1;
NCRVS   = size(ZSCRS,1);
PCZ     = size(ZSCRS,2);

tAll              = tic;
[~ , sepA , sepB] = jprintf('', 0, 0);
fprintf('%s\nTraining Z-Vectors from %d Images to %d PC Scores [Save %d | Par %d | Verbose %d]\n%s\n', ...
    sepA, NCRVS, PCZ, sav, par, vrb, sepB);

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
    
    X = IMGS(:, :, :, splts.trnIdx); % For CNN
    Y = ZSCRS(splts.trnIdx, :);
else
    % Input is already the training set
    n = fprintf('Data already split into training sets');
    X = IMGS;
    Y = ZSCRS;
end

jprintf(' ', toc(t), 1, 80 - n);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Start training Convolution Neural Net [midpoint CNN method]
t = tic;
n = fprintf('Training CNN |');

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
for pc = 1 : PCZ
    % for e = 1 : 1 % Debug by running only 1 PC
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
        'Verbose',              vrb, ...
        'ExecutionEnvironment', exenv);
    
    % Removed [02-18-19]
    %     'LearnRateSchedule',     'piecewise', ...
    %     'LearnRateDropFactor',   0.1, ...
    %     'LearnRateDropPeriod',   20, ...
    %     'Plots',                'training-progress', ...
    
    % Run CNN
    znet{pc} = trainNetwork(X, cnnY, layers, options);
    
    n(pc+1) = fprintf(' %d |', pc);
end

% Store Networks in a structure
netStr = arrayfun(@(x) sprintf('N%d', x), 1 : PCZ, 'UniformOutput', 0);
znet   = cell2struct(znet, netStr, 2);

jprintf(' ', toc(t), 1, 80 -sum(n));

%% Predictions per PC
t = tic;
n = fprintf('Making predictions from %d-layer model', PCZ);

ypre = zeros(size(ZSCRS));
for pc = 1 : PCZ
    ypre(:,pc) = znet.(netStr{pc}).predict(IMGS);
end

% accuracy = sum((Y - ypre) ./ Y) / size(Y,1);

jprintf(' ', toc(t), 1, 80 - n);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save Output Structures
t = tic;
n = fprintf('Saving outputs');

IN  = struct('IMGS', IMGS, 'ZSCRS', ZSCRS);
OUT = struct('SplitSets', splts, 'Predictions', ypre, 'Net', znet);

% Save results in structure
if sav
    pnm = sprintf('%s_ZScoreCNN_%dContours_z%dPCs', ...
        tdate('s'), NCRVS, PCZ);
    save(pnm, '-v7.3', 'IN', 'OUT');
end

jprintf(' ', toc(t), 1, 80 - n);

fprintf('%s\nFinished training Z-Vector CNN [%.03f sec]\n%s', ...
    sepA, toc(tAll), sepB);

end

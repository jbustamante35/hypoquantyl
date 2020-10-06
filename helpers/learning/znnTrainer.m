function [IN, OUT] = znnTrainer(IMGS, ZSCRS, splts, varargin)
%% znnTrainer: CNN to predict Z-Vector slices given grayscale images
%
% Usage:
%   [IN, OUT] = znnTrainer(IMGS, ZSCRS, spltsb)
%
% Input:
%   SCRS: PCA scores of Z-Vector data set [N pcz]
%   IMGS: reshaped and rescaled hypocotyl images [x x 1 N]
%   splts: dataset splits of training, validation, testing indices
%   MBSize: mini batch size parameter
%   MaxEpochs: maximum number of epochs
%   ILRate: initial learning rate
%   Save: boolean to save output in a .mat file
%   Parallel: boolean to use parallel computing if available
%   Verbose: boolean to determine verbosity level
%
% Output:
%   IN: structure containing the inputs used for the neural net run
%   OUT: structure containing predictions, network objects, and data splits
%

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

%% Setup and Extract some info about the datase
% Image input scale
% SCALE = 1;
NCRVS   = size(ZSCRS,1);
PCZ     = size(ZSCRS,2);

tAll              = tic;
[~ , sepA , sepB] = jprintf('', 0, 0);
fprintf('%s\nTraining Z-Vectors from %d Images to %d PC Scores [Save %d | Par %d | Verbose %d]\n%s\n', ...
    sepA, NCRVS, PCZ, Save, Parallel, Verbose, sepB);

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
switch Parallel
    case 0
        % Run with basic for loop [slower]
        exenv = 'cpu';
    case 1
        % Run with parallel processing [less stable]
        exenv = 'parallel';
    case 2
        % Run with multiple GPU cores [only tested on Nathan's]
        exenv = 'multi-gpu';
    otherwise
        fprintf(2, 'Incorrect Option %d [0|1|2]\n', par);
        [IN , OUT] = deal([]);
        return;
end

% Plot Type
switch Visualize
    case 0
        vis = 'none';
    case 1
        vis = 'none';
    case 2
        vis = 'training-progress';
    otherwise
        fprintf(2, 'Incorrect Option %d [0|1|2]\n', par);
        [IN , OUT] = deal([]);
        return;
end

% Generate multiple layers from range of filters
LAYERS = generateLayers(FltRng, NumFltRng, FltLayers);

% Run CNN to predict all 6 parts of the Z-vector
for pc = 1 : PCZ
    % for e = 1 : 1 % Debug by running only 1 PC
    cnnY = Y(:,pc);
    csz  = size(cnnY,2);

    % Create CNN Layers
    imgnm  = sprintf('imgin_%d_imgs%d', pc, size(IMGS,4));
    drpnm  = sprintf('drp_%d', pc);
    connnm = sprintf('conn_%d_sz%d', pc, csz);
    regnm  = sprintf('reg_%d', pc);

    layers = [
        imageInputLayer([size(IMGS,1) , size(IMGS,2) , 1], ...
        'Name', imgnm, 'Normalization', 'none');

        LAYERS ;

        dropoutLayer(Dropout, 'Name', drpnm);
        fullyConnectedLayer(csz, 'Name', connnm);
        regressionLayer('Name', regnm);
        ];

    % Configure CNN options
    options = trainingOptions( ...
        'sgdm', ...
        'MiniBatchSize',        MBSize, ...
        'MaxEpochs',            MaxEps, ...
        'InitialLearnRate',     ILRate, ...
        'Shuffle',              'every-epoch', ...
        'Plots',                vis, ...
        'Verbose',              Verbose, ...
        'ExecutionEnvironment', exenv);

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
if Save
    pnm = sprintf('%s_ZScoreCNN_%dContours_z%dPCs', ...
        tdate('s'), NCRVS, PCZ);
    save(pnm, '-v7.3', 'IN', 'OUT');
end

jprintf(' ', toc(t), 1, 80 - n);

fprintf('%s\nFinished training Z-Vector CNN [%.03f sec]\n%s', ...
    sepA, toc(tAll), sepB);

end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
% Need descriptions for all these parameters
% pcaX, pcaY, dim2chg, mns, eigs, scrs, pc2chg, upFn, dwnFn, stp, f

p = inputParser;
p.addOptional('FltRng', 8 : -1 : 6);
p.addOptional('NumFltRng', [10 , 5 , 3]);
p.addOptional('FltLayers', 1);
p.addOptional('Dropout', 0.2);
p.addOptional('MBSize', 128);
p.addOptional('MaxEps', 300);
p.addOptional('ILRate', 1e-4);
p.addOptional('Save', 0);
p.addOptional('Parallel', 0);
p.addOptional('Verbose', 0);
p.addOptional('Visualize', 0);

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end

% Old 3-layer method
%         % Layer 1
%         convolution2dLayer(7, 10, 'Padding', 'same');
%         batchNormalizationLayer;
%         reluLayer;
%         maxPooling2dLayer(2,'Stride',2);
%
%         % Layer 2
%         convolution2dLayer(7, 5,'Padding','same');
%         batchNormalizationLayer;
%         reluLayer;
%         maxPooling2dLayer(2,'Stride',2);
%
%         % Layer 3
%         convolution2dLayer(7, 3,'Padding','same');
%         batchNormalizationLayer;
%         reluLayer;
%         maxPooling2dLayer(2,'Stride',2);

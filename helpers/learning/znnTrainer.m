function [IN, OUT] = znnTrainer(IMGS, ZSCRS, splts, pc, varargin)
%% znnTrainer: CNN to predict Z-Vector slices given grayscale images
% This function runs a convolution neural net on image stacks to train these
% images to learn a single PC score. This function was meant to be used in a
% loop, where each PC score is run through a separate function with differing
% configurations for layers of the neural net.
%
% Output is in the form of two structures: IN contains the reshaped stack of
% images along with their corresponding PC score, and OUT contains the indices
% for splitting the dataset, the neural net model, and  the predicted values
% from that model on the training, validation, and testing datasets.
%
% Usage:
%   [IN, OUT] = znnTrainer(IMGS, ZSCRS, splts, pc, varargin)
%
% Input:
%   SCRS: PCA scores of Z-Vector data set [N pcz]
%   IMGS: reshaped and rescaled hypocotyl images [x x 1 N]
%   splts: dataset splits of training, validation, testing indices
%   pc: PC to train
%   varargin: various inputs for neural net [see below]
%
%   Miscellaneous Inputs
%       MBSize: mini batch size parameter
%       MaxEpochs: maximum number of epochs
%       ILRate: initial learning rate
%       Save: boolean to save output in a .mat file
%       Parallel: boolean to use parallel computing if available
%       Visualize: show current progress of training
%       Verbose: boolean to determine verbosity level
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
NCRVS = size(ZSCRS,1);
PCZ   = size(ZSCRS,2);

tAll              = tic;
[~ , sepA , sepB] = jprintf('', 0, 0);
fprintf('%s\nTraining Z-Vectors from %d Images to PC Score %d of %d [Save %d | Par %d | Verbose %d]\n%s\n', ...
    sepA, NCRVS, pc, PCZ, Save, Parallel, Verbose, sepB);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Split into training, validation, and testing sets
t = tic;

if isempty(splts)
    % Do the split
    n      = fprintf('Splitting data into training/validation/testing sets');
    trnPct = 0.8;
    valPct = 0.1;
    tstPct = 0.1;
    splts  = splitDataset(1 : NCRVS, trnPct, valPct, tstPct);
    
    X = IMGS(:,:,:,splts.trnIdx); % For CNN
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
t  = tic;
n1 = fprintf('Training CNN |');

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

% Run CNN to predict all Z-vector PCs
% Generate multiple layers from range of filters
LAYERS = generateLayers(FltRng, NumFltRng, FltLayers);
cnnY   = Y(:,pc);
csz    = size(cnnY,2);

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

if ~isempty(Vimgs)
    options.ValidationData      = {Vimgs , Vscrs};
    options.ValidationFrequency = floor(NCRVS / MBSize);
end

% Run CNN
znet = trainNetwork(X, cnnY, layers, options);

n2 = fprintf(' %d |', pc);
jprintf(' ', toc(t), 1, 80 - sum(n1,n2));

%% Save it before making predictions, then save it again
% Avoid errors after the hours it takes to run the training
t = tic;
n = fprintf('Saving initial training');

IN  = struct('ZSCRS', ZSCRS, 'zinn', cnnY);
OUT = struct('SplitSets', splts, 'Net', znet);

% Save results in structure
if Save
    pdir = sprintf('zvector_training/pcs');
    
    if ~isfolder(pdir)
        mkdir(pdir);
        pause(0.5);
    end
    
    pnm  = sprintf('%s/%s_ZScoreCNN_%dContours_pc%02dof%02d', ...
        pdir, tdate, NCRVS, pc, PCZ);
    save(pnm, '-v7.3', 'IN', 'OUT');
end

jprintf(' ', toc(t), 1, 80 - n);

%% Predictions per PC
t = tic;
n = fprintf('Making predictions from %d-layer model [Validation %d]', ...
    PCZ, ~isempty(Vimgs));

% Predictions from model
ypre = double(znet.predict(IMGS));
yerr = mean((cnnY - ypre).^2, 1) .^ 0.5;

% Compute error of validation set (if given)
if ~isempty(Vimgs)
    valPre = znet.predict(Vimgs);
    valErr = mean((Vscrs - valPre).^2, 1) .^ 0.5;
else
    valErr = [];
end

jprintf(' ', toc(t), 1, 80 - n);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save Output Structures
% Overwrites initial file
t = tic;
n = fprintf('Saving final outputs');

IN  = struct('ZSCRS', ZSCRS, 'zinn', cnnY);
OUT = struct('SplitSets', splts, 'Predictions', ypre, 'Error', yerr, ...
    'Net', znet, 'ValErr', valErr);

% Save results in structure
if Save
    pdir = sprintf('zvector_training');
    pnm  = sprintf('%s/%s_ZScoreCNN_%dContours_pc%02dof%02d', ...
        pdir, tdate, NCRVS, pc, PCZ);
    save(pnm, '-v7.3', 'IN', 'OUT');
end

jprintf(' ', toc(t), 1, 80 - n);
fprintf('%s\nFinished training Z-Vector CNN [%.03f sec]\n%s\n', ...
    sepA, toc(tAll), sepB);

end

function args = parseInputs(varargin)
%% Parse input parameters
% Need descriptions for all these parameters
% pcaX, pcaY, dim2chg, mns, eigs, scrs, pc2chg, upFn, dwnFn, stp, f

p = inputParser;
p.addOptional('FltRng', 7);
p.addOptional('NumFltRng', [10 , 5 , 3]);
p.addOptional('FltLayers', 1);
p.addOptional('Dropout', 0.2);
p.addOptional('MBSize', 128);
p.addOptional('MaxEps', 300);
p.addOptional('ILRate', 1e-4);
p.addOptional('Vimgs', []);
p.addOptional('Vscrs', []);
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

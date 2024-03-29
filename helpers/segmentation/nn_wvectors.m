function [wpre , wnet , zpevecs , zpmns] = nn_wvectors(inputs, targets, par, nzp, nlayers, trnfn, wsz)
%% nn_wvectors: CNN to predict contour segments given a Z-Vector slice
%
% Parallel/GPU Codes ['par' parameter]:
%   | Input |  CPU  |  GPU   |              Note             |
%   |  ---  |  ---  |  ---   |              ---              |
%   |   0   | 'no'  | 'no'   | Single-Thread                 |
%   |   1   | 'yes' | 'no'   | Parellel CPU workers          |
%   |   2   | 'yes' | 'yes'  | GPU with extra workers on CPU |
%   |   3   | 'yes' | 'only' | GPU only, no CPU              |
%   |   4   | 'no'  | 'yes'  | Not sure this will even work? |
%
% Usage:
%   [wpre , wnet , zpevecs , zpmns] = ...
%       nn_wvectors(inputs, targets, par, nzp, nlayers, trnfn, wsz)
%
% Input:
%   inputs: vectorized image patches from multiple scales and domains
%   targets: displacement vectors to place from tangent bundle
%   par: run on single-thread (0), parallelization (1), or with GPU (2)
%   nzp: number of PCs to reduce inputs (sampled patches)
%   nlayers: number of hidden layers for neural net
%   trnfn: training algorithm to use (default 'trainlm')
%   wsz: size to reshape predictions after using the neural net model
%
% Output:
%   wpre: predicted target values
%   wnet: neural net object after training
%   wevecs: eigenvectors after folding input to PC scores
%   wmns: column means of the input matrix
%

%% Setup the net
if nargin < 3; nzp     = 6;         end
if nargin < 4; nlayers = 5;         end
if nargin < 5; trnfn   = 'trainlm'; end
if nargin < 6; wsz     = 0;         end

% Use with parallelization or GPU
% [NOTE 10.24.2019]
% Parallelization only works sometimes, all of the time, but not always
% (aka use at your own risk, or wait until I get Nathan's GPU)
ppll = 'UseParallel';
gpll = 'UseGPU';
switch par
    case 0
        % No parallel, No GPU
        pll = 'no';
        gll = 'no';
    case 1
        % With parallel, No GPU [for my machine]
        pll = 'yes';
        gll = 'no';
    case 2
        % With parallel, With GPU
        % To run in parallel, with workers each assigned to a different unique
        % GPU, with extra workers running on CPU:
        pll = 'yes';
        gll = 'yes';
    case 3
        %
        % Using only workers with unique GPUs might result in higher speed, as
        % CPU workers might not keep up.
        pll = 'yes';
        gll = 'only';
    case 4
        % No parallel, With GPU [don't see why you'd ever use this]
        pll = 'no';
        gll = 'yes';
end

%% Compress Z-Patches via PCA
nsplt   = round(size(targets,2) / 2);
zpnm    = sprintf('zpatches_%dwindowPCs', nsplt);
pzp     = pcaAnalysis(inputs, nzp, 0, zpnm);
zpscrs  = pzp.PCAScores;
zpevecs = pzp.EigVecs;
zpmns   = pzp.MeanVals;

%% Run fitnet to predict displacement vectors from image patches
wnet = fitnet(nlayers, trnfn);
wnet = train(wnet, zpscrs', targets', ppll, pll, gpll, gll);

%% Predict on training data
if isstruct(wnet)
    wpre = struct2array(structfun(@(net) ...
        net(zpscrs')', wnet, 'UniformOutput', 0));
else
    wpre = wnet(zpscrs')';
end

% If not performing PCA folding after this step [reshape into multidim]
if wsz
    wpre = reshape(wpre, wsz);
    wpre = permute(wpre, [3 , 4 , 1 , 2]);
end
end

function [dpre , dnet , evecs , mns] = nn_dvectors(inputs, targets, dsz, par, npd, nlayers, trnfn)
%% nn_dvector: CNN to predict contour segments given a Z-Vector slice
%
%
% Usage:
%   [dpre , dnet , evecs , mns] = nn_dvectors( ...
%       inputs, targets, dsz, par, npd, nlayers, trnfn)
%
% Input:
%   inputs: vectorized image patches from multiple scales and domains
%   targets: displacement vectors to place from tangent bundle
%   dsz: size to reshape predictions after using the neural net model
%   par: run on single-thread (0) or with parallelization (1)
%   npd: number of Principal Components to reduce inputs (sampled core patches)
%   nlayers: number of hidden layers for neural net
%   trnfn: training algorithm to use (default 'trainlm')
%
% Output:
%   dpre: predicted target values
%   dnet: neural net object after training
%   evecs: eigenvectors after folding input to PC scores
%   mns: column means of the input matrix
%

%% Setup the net
if nargin < 5
    npd     = 10;
    nlayers = 5;
    trnfn   = 'trainlm';
    %     par     = false;
end

% Use with parallelization
% [NOTE 10.24.2019]
% Parallelization only works sometimes, all of the time, but not always
% (aka use at your own risk, or wait until I get Nathan's GPU)
if par
    pll = 'yes';
else
    pll = 'no';
end

%% Fold Patches to PC scores
pp    = myPCA(inputs, npd);
scrs  = pp.PCAScores;
evecs = pp.EigVecs;
mns   = pp.MeanVals;

% Use optimal number of PCs for 0.95 variance explaned
% NOTE: This will use hundreds of PCs


%% Run a fitnet to predict displacement vectors from image patches
dnet = fitnet(nlayers, trnfn);
dnet = train(dnet, scrs', targets', 'UseParallel', pll);

% Predict training set data
dpre = dnet(scrs')';
dpre = reshape(dpre, dsz);
dpre = ipermute(dpre, [1 , 3 , 2]);

end


function [Ypre , net, evecs, mns] = nn_dvectors(inputs, targets, szY, ppc, nlayers, trnfn)
%% nn_dvector: CNN to predict contour segments given a Z-Vector slice
%
%
% Usage:
%   [Ypre , net] = nn_dvectors(inputs, targets, PPC, nlayers, trnfn)
%
% Input:
%   inputs: PCA scores of
%   targets: displacement vectors to place from tangent bundle
%   szY: size to reshape predictions after running the net
%   nlayers: number of hidden layers
%   trnfn: training algorithm to use
%
% Output:
%   Ypre: predicted target values
%   net:
%

%% Setup the net
if nargin < 4
    ppc     = 10;
    nlayers = 5;
    trnfn   = 'trainlm';
end

%% Fold Patches to PC scores
pp    = myPCA(inputs, ppc);
scrs  = pp.PCAscores;
evecs = pp.EigVectors;
mns   = pp.MeanVals;

%% Run a fitnet to predict displacement vectors from scaled patches
net = fitnet(nlayers, trnfn);
net = train(net, scrs', targets');

% Predict
Ypre = net(scrs')';
Ypre = reshape(Ypre, szY);
Ypre = ipermute(Ypre, [1 , 3 , 2]);

end


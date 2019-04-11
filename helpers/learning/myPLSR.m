function plsr = myPLSR(X, Y, numR)
%% myPCA: my custom PCA function 
% This function takes rasterized data and performs PCA with the number of 
% Principal Components (PC) given by the numC parameter. Output is in a 
% structure containing various data from the analysis.
%
% Usage:
%   pca_custom = myPCA(rawD, numC)
%
% Input:
%   rawD: rasterized raw data to perform analysis
%   numC: number of PCs to extract from dataset
%
% Output:
%   pca_custom structure containing data from the analysis
%

%% Run analysis [I should figure out my own method]
[Xloadings, Yloadings, Xscores, Yscores, beta, pctVar, mse, stats, weights] = ... % laptop version of plsr has no Weights output
        plsregress(X, Y, numR);

% Simulate the input data
simX = [ones(size(X,1) , 1) X] * beta;

%% Create output structure
plsr = struct(              ...
    'InputData', X,         ...
    'Xloadings', Xloadings, ...
    'Yloadings', Yloadings, ...
    'Xscores',   Xscores,   ...
    'Yscores',   Yscores,   ...
    'Beta',      beta,      ...
    'PctVar',    pctVar,    ...
    'MSE',       mse,       ...
    'Stats',     stats,     ...
    'Weights',   weights,   ...
    'SimData',   simX);

end
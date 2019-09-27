function PLSR = myPLSR(X, Y, numR)
%% myPCA: my custom Partial Least Squares Regression function
% This is a wrapper for MATLAB's plsregress function that takes predictor
% variables (X) and response matrix (Y) and performs PLS regression with the
% number of predictor loading components (numR). Output is in a structure
% containing various data from the analysis.
%
% Usage:
%   PLSR = myPLSR(X, Y, numR)
%
% Input:
%   X: [N x P] predictor variables of N observations and P variables
%   Y: [N x M] response variables of M loading from the N observations
%   numR: number of components to reduce the dataset down to
%
% Output:
%   PLSR: custom structure containing data from the analysis
%

%% Run analysis [I should figure out my own method]
try
    [Xloadings, Yloadings, Xscores, Yscores, beta, pctVar, mse, stats, weights] = ...
        plsregress(X, Y, numR);
catch
    % MATLAB versions > R2018b plsregress has no Weights output
    weights = [];
    fprintf('Running update plsregress without WEIGHTS output\n');

    [Xloadings, Yloadings, Xscores, Yscores, beta, pctVar, mse, stats] = ...
        plsregress(X, Y, numR);

end
% Simulate the input data
simX = [ones(size(X,1) , 1) X] * beta;

%% Create output structure
PLSR = struct(              ...
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

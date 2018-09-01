function pca_builtin = builtinPCA(rawD, numC)
% This function takes rasterized data and performs PCA with the number of Principal Components (PC)
% given by the numC parameter. Output is in a structure containing various data from the analysis.
% This uses MATLAB's builtin pca function, contrary to myPCA, which uses my own methods.
%
% Usage:
%   pca_builtin = builtinPCA(rawD, numC)
%
% Input:
%   rawD: rasterized raw data to perform analysis
%   numC: number of PCs to extract from dataset
%
% Output:
%   pca_builtin: structure containing data from the analysis
%

%% Run analysis
warning('off','stats:pca:ColRankDefX'); % Turn off T-squared warning message for using > 3 PCs
[C, S, L, T, E, M] = pca(rawD, 'NumComponents', numC, 'Algorithm', 'svd');

%% Create output structure
pca_builtin        = struct('COEFF', C, ...
    'SCORE',     S, ...
    'LATENT',    L, ...
    'TSQUARED',  T, ...
    'EXPLAINED', E, ...
    'MU',        M);

end
function pca_custom = myPCA(rawD, numC, mth)
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

%% Default to method using PcaJB object
if nargin < 3
    mth = 'new';
end

switch mth
    case 'old'
        pca_custom = runOldMethod(rawD, numC);
        
    case 'new'
        pca_custom = runNewMethod(rawD, numC);
        
    otherwise
        fprintf(2, 'Method %s must be [old|new]\n', mth);
        pca_custom = [];
end


end

function pca_custom = runOldMethod(rawD, numC)
%% Run analysis
% Find and subtract off means
avgD = mean(rawD, 1);
subD = bsxfun(@minus, rawD, avgD);

% Get Variance-Covariance Matrix
covD = (subD' * subD) / size(subD,1);

% Get Eigenvector and Eigenvalues
[eigV, eigX] = eigs(covD, numC);

% Compute Variance Explained pre PC
varX = variance_explained(eigX);

% Simulate data points by projecting eigenvectors onto original data
pcaS = subD * eigV;
simD = ((pcaS * eigV') + avgD);

%% Create output structure
pca_custom = struct( ...
    'InputData',    rawD, ...
    'MeanVals',     avgD, ...
    'EigVecs',      eigV, ...
    'EigVals',      eigX, ...
    'PCAScores',    pcaS, ...
    'VarExplained', varX, ...
    'SimData',      simD);

% pca_custom = struct(...
%     'InputData',    rawD, ...
%     'MeanVals',     avgD, ...
%     'MeanCentered', subD, ...
%     'VarCovar',     covD, ...
%     'EigVectors',   eigV, ...
%     'EigValues',    eigX, ...
%     'PCAscores',    pcaS, ...
%     'VarExplained', varX, ...
%     'SimData',      simD);
end

function pca_custom = runNewMethod(rawD, numC)
pca_custom = PcaJB(rawD, numC);
end


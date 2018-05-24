function [customPCA, builtinPCA] = multiPCArun(D, numC, sv, dName, vis)
%% multiPCArun: run PCA on multiple segments
% This function takes an [m x n x r] array and runs PCA individually on all r segments.
%
% Usage:
%   [customPCA, builtinPCA] = multiPCArun(D)
%
% Input:
%   D: [m x n x r] input matrix to run PCA on r segments
%   numC: number of PCs to run analysis
%   dName: name for dataset
%   sv: save PCA output data
%   vis: generate figures from PCA output
%
% Output:
%   customPCA: {r x 1} cell array containing output from custom PCA
%   builtinPCA: {r x 1} cell array containing output from MATLAB's built-in PCA
%

%% Set up function handle for running PCA
myPCA      = @(x,y,z) pcaAnalysis(x, y, size(x(1,:)), sv, z, vis);
r          = size(D, 3);
customPCA  = cell(r, 1);
builtinPCA = cell(r, 1);

%% Run PCA on all r segments
if length(numC) == 1
    numC(1:r) = numC;
end

for i = 1 : r
    nm = sprintf('multiPCA_%s_Route%d', dName, i);
    [customPCA{i}, builtinPCA{i}] = myPCA(D(:,:,i), numC(i), nm);
end
end
function [pcaX, pcaY] = multiPCAfull(C, numC, sv, vis)
%% multiPCAfull: prep and run PCA on multiple segments of CircuitJB object array
% This function takes an array of CircuitJB objects, prepares each child Route object array for PCA
% analysis, and runs custom and builtin PCA algorithms on each of those segments for both
% x-coordinates and y-coordinates.
%
% Usage:
%   [pcaX, pcaY] = multiPCAfull(C, numC, sv, vis)
%
% Input:
%   C: object array of CircuitJB objects)
%   numC: number of PCs to run analysis
%   sv: save results from this analysis
%
% Output:
%   pcaX: cell array of data for all segments of x-coorinates
%   pcaY: cell array of data for all segments of y-coorinates
%

%% Prep data for multiPCArun
[D, ~, ~] = multiPCAprep(C);

%% Run multiPCArun on both x-/y-coordinates
customPCA  = cell(numel(D), 1);
builtinPCA = cell(numel(D), 1);
dNames     = {'xCoords', 'yCoords'};
for i = 1 : numel(D)
    [customPCA{i}, builtinPCA{i}] = multiPCArun(D{i}, numC, sv, dNames{i}, vis);
end

pcaX = struct('customPCA', customPCA{1}, ...
    'builtinPCA', builtinPCA{1});
pcaY = struct('customPCA', customPCA{2}, ...
    'builtinPCA', builtinPCA{2});

if sv
    N = numel(C);
    nm = sprintf('%s_multiPCA_xyCoords_%dPCs_%dCircuitJB', datestr(now, 'yymmdd'), numC, N);
    save(nm, '-v7.3', 'pcaX', 'pcaY');
end
end
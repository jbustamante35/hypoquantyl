function [pcaX, pcaY] = multiPCAoptimal(varargin)
%% multiPCAoptimal: run multiPCA with optimal number of PCs based on variance explained
% This function runs through the multiPCA pipeline with varying number of Principal Components
% (defined by values from variance explained).
%
% Usage:
%   [customPCA, builtinPCA] = multiPCAoptimal(varargin)
%   [customPCA, builtinPCA] = multiPCAoptimal(C, NumRuns, VarEx, sv, vis)
%
% Parameters:
%   Circuits: CircuitJB object array to extract data
%   SaveData: boolean to save final results
%   ShowResults: boolean to show figures of output
%   NumPCs: number of PCs to use for PCA (optional)
%   Optimize: boolean to optimize number of PCs for each Route of CircuitJB (optional)
%   pcaX: x-coordinate pca output to extract variance explained data
%   pcaY: y-coordinate pca output to extract variance explained data
%   Cutoff: minimum percentage for variance explained to determine optimal PCs
%
% Output:
%   pcaX: full pca output for all Routes of x-coordinate data
%   pcaY: full pca output for all Routes of y-coordinate data 
%

%% Parse input and set parameters
args = parseInputs(varargin);
C    = args.Circuits;
pcs  = args.NumPCs;
opt  = args.Optimize;
sv   = args.SaveData;
vis  = args.ShowResults;
Vx   = arrayfun(@(x) x.customPCA, args.pcaX, 'UniformOutput', 0);
Vy   = arrayfun(@(x) x.customPCA, args.pcaY, 'UniformOutput', 0);
V    = [cat(1,Vx{:}), cat(1,Vy{:})];
P    = args.Cutoff;

%% Compute variance explained if defined
if opt
    % Set number of PCs for each Route
    pcs = arrayfun(@(x) multiPCAgetoptimal(x, P), V, 'UniformOutput', 0);
    pcs = cat(1, pcs{:});
    pcs = reshape(pcs, size(V));
end

%% Prep data for multiPCArun
[D, ~, ~] = multiPCAprep(C);

%% Run multiPCArun on both x-/y-coordinates
customPCA  = cell(numel(D), 1);
builtinPCA = cell(numel(D), 1);
dNames     = {'xCoords', 'yCoords'};
for i = 1 : numel(D)
    [customPCA{i}, builtinPCA{i}] = multiPCArun(D{i}, pcs(:,i), sv, dNames{i}, vis);
end

pcaX = struct('customPCA', customPCA{1}, ...
    'builtinPCA', builtinPCA{1});
pcaY = struct('customPCA', customPCA{2}, ...
    'builtinPCA', builtinPCA{2});

if sv
    N = numel(C);
    nm = sprintf('%s_multiPCA_xyCoords_%sPCs_%dCircuitJB', datestr(now, 'yymmdd'), 'optimal', N);
    save(nm, '-v7.3', 'pcaX', 'pcaY');
end

end

function args = parseInputs(varargin)
p = inputParser;
p.addRequired('Circuits');
p.addRequired('SaveData');
p.addRequired('ShowResults');
p.addParameter('NumPCs', []);
p.addOptional('Optimize', 0);
p.addOptional('pcaX', []);
p.addOptional('pcaY', []);
p.addOptional('Cutoff', 0.95);

p.parse(varargin{1}{:});
args = p.Results;
end
function [T, Z] = collectTrainingSet(crvs, sv)
%% collectTrainingSet: compile data structures for training set
% This function takes in an array of CircuitJB objects with their child Curve
% objects and combines them to generate the dataset to use for training. This is
% the final step after generating and processing the full dataset.
%
% The training set consists of the following data:
% - rCrds: segment coordinates along curve in image coordinate frame
% - rMids: midpoint coordinate along curve in image coordinate frame
% - rTngt: tangent vector from midpoint (rMids) along curve (rCoords)
% - rNorm: normal vector from midpoint (rMids) along curve (rCoords)
% - iVals: grayscale intensity values of segment
% - iMids: image patch centered around midpoint coordinate (rMid)
%
% Usage:
%   T = collectTrainingSet(crvs)
%
% Input:
%   crvs: array of Curve objects made from manually-drawn contours
%   sv: boolean to save data in a .mat file
%
% Ouput:
%   T: structure containing all training data (see above for details)
%   Z: structure containing reshaped and vectorized training data
%

%% Create output structure and collect data
getProp = @(y) arrayfun(@(x) x.(y), crvs, 'UniformOutput', 0);
T       = struct('rCrds', [], 'rMids', [], 'rTngt', [], 'rNorm', [], ...
    'iVals', [], 'iMids', []);

rCrds = getProp('NormalSegments');
rMids = getProp('MidPoints');
rTngt = getProp('Tangents');
rNorm = getProp('Normals');
iVals = getProp('ImagePatches');
iMids = getProp('MidpointPatches');

%% Reshape and post-process data to desired shapes
% Midpoint-normalized Segment Coordinates
T.rCrds = rCrds;

% Midpoint Coordinates
T.rMids = cellfun(@(x) reshape(x, [size(x,2) size(x,3)])', ...
    rMids, 'UniformOutput', 0);

% Tangent Vectors
T.rTngt = cellfun(@(x) reshape(x, [size(x,2) size(x,3)])', ...
    rTngt, 'UniformOutput', 0);

% Normal Vectors
T.rNorm = cellfun(@(x) reshape(x, [size(x,2) size(x,3)])', ...
    rNorm, 'UniformOutput', 0);

% Segment Grayscale Intensities
T.iVals = cellfun(@(x) midInts(x), iVals, 'UniformOutput', 0);

% Midpoint Patches
T.iMids = iMids;

%% Set up function handles for reshaping dataset
rastFnc  = @(d,c) cellfun(@(x) reshape(x(:,d,:), [size(x,1) size(x,3)])', ...
    T.(c), 'UniformOutput', 0);
rastDims = @(d,c) arrayfun(@(x) rastFnc(x, c), d, 'UniformOutput', 0);
rastXY   = @(f)   cellfun(@(x) cat(1, x{:}), f, 'UniformOutput', 0);
rastData = @(c)   rastXY(rastDims(1:size(T.(c){1},2), c));

%% Reshape coordinates for rasterized dataset
% Midpoint-Normalized Coordinates
rastCrds = rastData('rCrds');

% Midpoint-Tangent-Normal Coordinates [ Z Vectors ]
rastMids = cat(1, T.rMids{:});
rastTngt = cat(1, T.rTngt{:}) + rastMids;
rastNorm = cat(1, T.rNorm{:}) + rastMids;
rastZvec = [rastMids , rastTngt , rastNorm];

% Store reshaped data into Z structure
Z = struct('xCrds', rastCrds{1}, 'yCrds', rastCrds{2}, 'zVect', rastZvec);

%% Save data into .mat file
if sv
    fnm = sprintf('%s_TrainingData_%dContours', tdate('s'), numel(T.rCrds));
    save(fnm, 'T', 'Z');
end

end

function ints = midInts(P)
%% Get midpoint intensities from image patch
% Get middle column of intensities
midIdx  = @(p) ceil(size(p,2) / 2);
ints    = cellfun(@(x) x(:, midIdx(x)), P, 'UniformOutput', 0);
ints    = cat(2, ints{:});

end

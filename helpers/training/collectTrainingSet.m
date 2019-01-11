function T = collectTrainingSet(crvs)
%% collectTrainingSet: compile data structures for training set
% This function takes in an array of CircuitJB objects with their child Curve
% objects and combines them to generate the dataset to use for training. This is
% the final step after generating and processing the full dataset.
%
% The training set consists of the following data:
% - rCrds: segment coordinates along curve in image coordinate frame
% - iVals: grayscale intensity values of segment
% - rMids: midpoint coordinate along curve in image coordinate frame
% - iMids: image patch centered around midpoint coordinate (rMid)
% - rTngt: tangent vector from midpoint (rMids) along curve (rCoords)
% - rNorm: normal vector from midpoint (rMids) along curve (rCoords)
%
% Usage:
%   T = collectTrainingSet(crvs)
%
% Input:
%   crvs: array of Curve objects made from manually-drawn contours
%
% Ouput:
%   T: structure containing all training data (see above for details)
%

%% Create output structure and collect data
T = struct('rCrds', [], 'iVals', [], 'rMids', [], ...
    'iMids', [], 'rTngt', [], 'rNorm', []);
getProp = @(y) arrayfun(@(x) x.(y), crvs, 'UniformOutput', 0);

rCrds = getProp('NormalSegments');
rMids = getProp('MidPoints');
rTngt = getProp('Tangents');
rNorm = getProp('Normals');
iMids = getProp('MidpointPatches'); % TODO
iVals = getProp('ImagePatches');

%% Reshape and post-process data to desired shapes
% Segment Coordinates 
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

end

function ints = midInts(P)
%% Get midpoint intensities from image patch
% Get middle column of intensities
midIdx  = @(p) ceil(size(p,2) / 2);
ints = cellfun(@(x) x(:, midIdx(x)), P, 'UniformOutput', 0);
ints = cat(2, ints{:});

end

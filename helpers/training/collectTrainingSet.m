function [T, P] = collectTrainingSet(crvs, sv)
%% collectTrainingSet: compile data structures for training set
% This function takes in an array of CircuitJB objects with their child Curve
% objects and combines them to generate the dataset to use for training. This is
% the final step after generating and processing the full dataset.
%
% The training set consists of the following data:
% - imgs: cropped and rescaled hypocotyl images
% - sVect: S-Vectors, segment coordinates in midpoint-normalized frame
% - zVect: Z-Vectors, midpoint-tangent-normals along curve skeletons
% - sPtch: S-Patches, non-linear patches along segments in image frame
% - zPtch: Z-Patches, linear patches around midpoints rotated along tangents
%
% Usage:
%   [T, P] = collectTrainingSet(crvs, sv)
%
% Input:
%   crvs: array of Curve objects made from manually-drawn contours
%   sv: boolean to save data in a .mat file
%
% Ouput:
%   T: structure containing all training data (see above for details)
%   P: structure containing S-Vector and Z-Vector data prepped for PCA
%

%% Create output structure and collect data
getProp = @(y) arrayfun(@(x) x.(y), crvs, 'UniformOutput', 0);
T       = struct('imgs', [], 'sVect', [], 'zVect', [], ...
    'sPtch', [], 'zPtch', []);

sVect = getProp('SVectors');
zVect = getProp('ZVector');
sPtch = getProp('SPatches');
zPtch = getProp('ZPatches');

%% Reshape and post-process data to desired shapes
% S-Vectors, Z-Vectors, S-Patches, Z-Patches
T.imgs  = arrayfun(@(x) x.Parent.getImage('gray'), crvs, 'UniformOutput', 0);
T.sVect = sVect;
T.zVect = zVect;
T.sPtch = sPtch;
T.zPtch = zPtch;

%% Set up function handles for reshaping x-/y-coordinates
rastFnc  = @(d,c) cellfun(@(x) reshape(x(:,d,:), [size(x,1) size(x,3)])', ...
    T.(c), 'UniformOutput', 0);
rastDims = @(d,c) arrayfun(@(x) rastFnc(x, c), d, 'UniformOutput', 0);
rastXY   = @(f)   cellfun(@(x) cat(1, x{:}), f, 'UniformOutput', 0);
rastData = @(c)   rastXY(rastDims(1:size(T.(c){1},2), c));

%% Reshape coordinates for rasterized dataset for PCA
% Rasterize S-Vectors
rastCrds = rastData('sVect');

% Concatenate Z-Vectors and convert to prepped shape
rastZvec = cat(1, T.zVect{:});
ttlSegs  = size(zVect{1},1);
numCrvs  = numel(crvs);
prepZvec = zVectorConversion(rastZvec, ttlSegs, numCrvs, 'prep');

% Store data into structure prepped for PCA
P = struct('xCrds', rastCrds{1}, 'yCrds', rastCrds{2}, ...
    'zRaw', rastZvec, 'zPrep', prepZvec);

%% Save data into .mat file
if sv
    fnm = sprintf('%s_TrainingData_%dContours', tdate('s'), numel(crvs));
    save(fnm, 'T', 'P');
end

end


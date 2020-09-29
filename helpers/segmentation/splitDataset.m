function [trnIdx, valIdx, tstIdx] = splitDataset(rngIdx, trnPct, valPct, tstPct, D)
%% splitDataset: split range of indices into training/validation/testing sets
%
%
% Usage:
%   [trnIdx, valIdx, tstIdx] = splitDataset(rngIdx, trnPct, valPct, tstPct, D)
%
% Input:
%   rngIdx: range of indices to split into datasets
%   trnPct: percentage to split into training set
%   valPct: percentage to split into validation set
%   tstPct: percentage to split into testing set
%   D: cell array dataset to do the split (optional)
%
% Output:
%   trnIdx: indices of the training set
%   valIdx: indices of the validation set
%   tstIdx: indices of the testing set
%

%% Split into training, validation, and testing sets
[trnIdx, valIdx, tstIdx] = ...
    divideblock(Shuffle(rngIdx), trnPct, valPct, tstPct);

% Sort numerically
trnIdx = sort(trnIdx);
valIdx = sort(valIdx);
tstIdx = sort(tstIdx);

% Store splits into data if entered
if nargin > 4
    trnIdx = arrayfun(@(x) D{x}, trnIdx, 'UniformOutput', 0);
    valIdx = arrayfun(@(x) D{x}, valIdx, 'UniformOutput', 0);
    tstIdx = arrayfun(@(x) D{x}, tstIdx, 'UniformOutput', 0);
end

% Output as structure or individual vectors
switch nargout
    case 1
        trnIdx = struct('trnIdx', trnIdx, 'valIdx', valIdx, 'tstIdx', tstIdx);
end
end

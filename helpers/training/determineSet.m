function tset = determineSet(idx, trnidx, validx, tstidx)
%% determineSet: determine which set is being indexed
%
% Usage:
%   tset = determineSet(idx, trnidx, validx, tstidx)
%
% Input:
%   idx: index to determine which set it belongs to
%   trnidx: indices in training set
%   validx: indices in valisrion set
%   tstidx: indices in testing set
%
% Output:
%   tset: string defining which set idx belongs to

%% Default to NaN if set not included
if nargin < 2; trnidx = NaN; end
if nargin < 3; validx = NaN; end
if nargin < 4; tstidx = NaN; end

% Input is split structure [from HypocotylTrainer object]
if isstruct(trnidx)
    validx = trnidx.valIdx;
    tstidx = trnidx.tstIdx;
    trnidx = trnidx.trnIdx;
end

%% Evaluate which set idx belongs
if ismember(idx, trnidx)
    tset = 'training';
elseif ismember(idx, validx)
    tset = 'validation';
elseif ismember(idx, tstidx)
    tset = 'testing';
elseif ismatrix(idx)
    tset = arrayfun(@(x) determineSet(x, trnidx, validx, tstidx), ...
        idx, 'UniformOutput', 0)';
else
    tset = 'na';
end
end

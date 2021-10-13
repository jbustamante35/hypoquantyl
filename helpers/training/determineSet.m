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
%

%% Default to NaN if set not included
switch nargin
    case 1
        trnidx = NaN;
        validx = NaN;
        tstidx = NaN;
    case 2
        validx = NaN;
        tstidx = NaN;
    case 3
        tstidx = NaN;
    case 4
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

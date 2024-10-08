function Y = combineTracking(T, sidxs)
%% combineTracking: concatenate tracking results across time lapses
%
% Usage:
%   Y = combineTracking(T, sidxs)
%
% Input:
%   T: cell array of tracking results
%   sidxs: indices to exclude (default [])

if nargin < 2; sidxs = []; end

if ~isempty(sidxs); T = T(setdiff(1 : numel(T), sidxs)); end

if ~iscell(T); T = arrayfun(@(x) x, T, 'UniformOutput', 0); end
[flds1 , flds2 , flds3] = extractFields(T{1});
% flds = extractFields(T{1}, '');

%% Concatenate cell array into single structure
go1 = cellfun(@(x) ~isempty(x), flds2);
for f1 = 1 : numel(flds1)
    if go1(f1)
        go2 = cellfun(@(x) ~isempty(x), flds3{f1});
        for f2 = 1 : numel(flds2{f1})
            if go2(f2)
                % Set 3rd-level field
                for f3 = 1 : numel(flds3{f1}{f2})
                    Y.(flds1{f1}).(flds2{f1}{f2}).(flds3{f1}{f2}{f3}) = ...
                        cellfun(@(x) x.(flds1{f1}).(flds2{f1}{f2}). ...
                        (flds3{f1}{f2}{f3}), T, 'UniformOutput', 0);
                end
            else
                % Set 2nd-level field
                Y.(flds1{f1}).(flds2{f1}{f2}) = cellfun(@(x) x.(flds1{f1}). ...
                    (flds2{f1}{f2}), T, 'UniformOutput', 0);
            end
        end
    else
        % Set 1st-level field
        Y.(flds1{f1}) = cellfun(@(x) x.(flds1{f1}), T, 'UniformOutput', 0);
    end
end
end

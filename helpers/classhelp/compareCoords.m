function minDistIdx = compareCoords(ccurr, cnxt)
%% Euclidean distance comparison of input coordinates with group of coordinates
% If coordinates are within set error percent, it is added to the next frame of
% the Seedling. Otherwise the frame is skipped.
%
% Input:
%   crdsIn: [n x m] vector of unmatched coordinates
%   crdsNxt: [n x m] vector of coordinates to compare to crdsIn
%
% Output:
%   minDistIdx: index where each crdsIn coordinate is closest in crdsNxt

% [minDist , minDistIdx]     = min(pdist2(ccurr, cnxt), [], 'omitnan');
[minDist , minDistIdx]     = min(pdist2(ccurr, cnxt));
minDistIdx(isnan(minDist)) = 0;
end
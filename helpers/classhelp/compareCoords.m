function minDistIdx = compareCoords(crdsIn,  crdsNxt, dim)
%% Euclidean distance comparison of inputted coordinates with group of coordinates
% If coordinates are within set error percent, it is added to the
% next frame of the Seedling. Otherwise the frame is skipped.
%
% Input:
%   crdsIn: [n x m] vector of unmatched coordinates 
%   crdsNxt: [n x m] vector of coordinates to compare to crdsIn
%   d : Euclidean distances between crdsIn and crdsNxt
%
% Output:
%   minDistIdx: index where each crdsIn coordinate is closest in crdsNxt

minDistIdx = nan(length(crdsIn), 1);
for i = 1 : numel(minDistIdx)
    [~, y]        = min(abs(bsxfun(@minus, crdsNxt, crdsIn(i,:))));
    minDistIdx(i) = y(dim);
end

end
function minDistIdx = compareCoords(crdsIn,  crdsNxt, dim)
%% Compare inputted coordinates with group of coordinates
% If coordinates are within set error percent, it is added to the
% next frame of the Seedling. Otherwise the frame is skipped.
%
% Input:
%   crdsIn: coordinates of previous frame for current Seedling
%   crdsNxt: cell array of Seedlings at specific frame to compare to pf
%   d : Euclidean distances between pf and cf
%
% Output:
%   minDistIdx: index where each crdsIn coordinate is closest in crdsNxt

minDistIdx = nan(length(crdsIn), 1);
for i = 1 : length(crdsIn)
    [~, y] = min(abs(bsxfun(@minus, crdsNxt, crdsIn(i,:))));
    minDistIdx(i) = y(dim);
end

end
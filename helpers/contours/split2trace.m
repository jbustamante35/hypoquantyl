function trc = split2trace(oLine, aPts, num_anchors)
%% split2trace: split contour into separate traces defined by anchor points
% This function takes coordinates defining an outline and coordinates defining 
% anchor points along that outline, and returns an array of sub-outlines, where
% the start and end point of each of those sub-outlines are 2 anchorpoints.
%
% Usage:
%   trc = split2trace(oLine, aPts, num_anchors)
%
% Input:
%   oLine: [n x 2] array of coordinates definining an outline
%   aPts: [m x 2] array of coordinates defining anchor points along the inputted
%   num_anchors: total number of anchor points
%
% Output:
%   trc: [p x 2 x m] array of coordinates defining traces between anchor points
%

%% Set size of output matrix
sz1 = max(diff(aPts));
sz2 = max(abs(diff(flip(aPts))));
sz  = max([sz1 sz2]) + 1;
trc = zeros(sz, 2, num_anchors);

%% Split outline into traces
for i = 1 : num_anchors
    if i < num_anchors
    % Padarray with zeros to size of longest trace 
        crds       = oLine(aPts(i) : aPts(i+1), :);
        trc(:,:,i) = padarray(crds, (sz - length(crds)), 'post');
    else
    % Set coordinate at last index to top of array to get to first index 
        shft       = circshift(oLine, -aPts(end)+1);
        newPos     = aPts(1) + (length(oLine) - aPts(end)) + 1;
        crds       = shft(1 : newPos, :);
        trc(:,:,i) = padarray(crds, (sz - length(crds)), 'post');
    end
end

% Remove duplicate points
trc = arrayfun(@(x) unique(trc(:,:,x), 'rows'), ...
    1 : num_anchors, 'UniformOutput', 0);

end

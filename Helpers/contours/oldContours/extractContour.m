function cntr = extractContour(bw, max_size)
%% extractContour: find contour of single image
% This function blah
%
% Usage:
%   cntr = extractContour(bw, max_size)
%
% Input:
%   bw: bw image
%   max_size: number of coordinates to normalize boundaries
%
% Output:
%   cntr: various data from contour at given frame
%

%% Get boundaries of inputted bw image
bndAll   = bwboundaries(bw, 'noholes');
[~, lrg] = max(cellfun(@numel, bndAll));
bnds     = bndAll{lrg};
%     bnds = bndAll{1};

%% Interpolate distances to an equalized number of coordinates
bnds   = [getDim(bnds, 2) , getDim(bnds, 1)]; % Switch y-/x-coordinates to x-/y-coordinates
intrps = interpolateOutline(bnds, max_size);

%% Output final structure
cntr = ContourJB('Outline', bnds, 'InterpOutline', intrps);
cntr.ReindexCoordinates;
end

function pts = calcAnchorPoints(pIdx, lng)
%% calcAnchorPoints: find anchorpoints for cropping out Hypocotyl
% This function takes the 2x1 pixel index matrix to identify the 4
% anchor points for creating a crop box that represents the
% Hypocotyl of a Seedling. The 4 anchor points refer to the
% top-most pixel (a), the bottom pixel at the point (a) - lng (b),
% left-most pixel (c), and the right-most pixel (d).
%
% The pixel coordinates list represents the individual Seedling's
% coordinates, rather than the entire raw image's pixel list.
%
% Input:
%   pIdx: pixel index of given image and frame
%   lng : bottom of crop box; length defined by user
%
% Output:
%   pts: (4 x 2) array indicating 4 anchorpoints on Seedling object

%% Filter pixel coordinate range to limit search to upper region only
pts    = zeros(4, 2);
rowRng = pIdx(pIdx(:,2) <= lng, :);

%% Make separate Helper function for all 4 anchor points
% Point A: highest pixel (minimum row coordinate)
minrow   = rowRng(rowRng(:,2) == min(rowRng(:,2)), :);
pts(1,:) = ceil([median(minrow(:,1)) min(minrow(:,2))]);

% Point B: Point A - desired length to crop
maxrow   = rowRng(rowRng(:,2) == max(rowRng(:,2)), :);
pts(2,:) = ceil([median(maxrow(:,1)) max(maxrow(:,2))]);

% Point C: left-most pixel
mincol   = rowRng(rowRng(:,1) == min(rowRng(:,1)), :);
pts(3,:) = ceil([min(mincol(:,1)) median(mincol(:,2))]);

% Point D: right-most pixel
maxcol   = rowRng(rowRng(:,1) == max(rowRng(:,1)), :);
pts(4,:) = ceil([max(maxcol(:,1)) median(maxcol(:,2))]);

end
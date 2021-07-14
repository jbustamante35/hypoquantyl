function [timg, tbox , limg , lbox] = cropFromAnchorPoints(img, anchor_points, scale_size)
%% cropFromAnchorPoints: crop out and rescale an image at specfic anchorpoints
% This function is used by the Seedling.FindHypocotyl() method to use
% anchorpoints to determine where to crop out the sub-image. The image is
% cropped and then rescaled to the size defined by scale_size.
%
% [Update 05.20.2021]
% The lower region is now cropped out and rescaled as well.
%
%  Usage:
%      [timg, tbox , limg , lbox] = cropFromAnchorPoints( ...
%       img, anchor_points, scale_size)
%
%  Input:
%      img: image to crop and resize
%      anchor_points: [4 x 2] array of image cropping points
%      scale_size: [1 x 2] array defining the rescale size (default [101 , 101])
%
%  Output:
%      timg: upper region cropped and rescaled from image
%      tbox: upper region crop box
%      limg: lower region cropped and rescaled from image
%      lbox: lower region crop box
%

%% Defaults
switch nargin
    case 1
        anchor_points = [0 , 0 , round(size(img,1) / 2), size(img,2)];
        scale_size    = [101 , 101];
    case 2
        scale_size = [101 , 101];
end

%% Create crop box --> Crop image --> Rescale cropped image
try
    % Upper region
    tbox = [0 , 0 , anchor_points(4,1) + 1 , anchor_points(2,2)];
    tcrp = imcrop(img, tbox);
    timg = imresize(tcrp, scale_size);
catch
    fprintf(2, 'Error cropping upper region');
    tbox = [0 , 0 , 0 , 0];
    timg = [];
end

%% NOTE: need to handle edge case that upper box takes up entire image
try
    % Lower region
    lbox = abs([0 , anchor_points(2,2) + 1, anchor_points(4,1) + 1, ...
        (size(img, 1) - anchor_points(2,2)) - 1]);
    lcrp = imcrop(img, lbox);
    limg = imresize(lcrp, scale_size);
catch
    fprintf(2, 'Error cropping lower region');
    lbox = [0 , 0 , 0 , 0];
    limg = [];
end

end

function [img_out, bbox] = cropFromAnchorPoints(img_input, anchor_points, scale_size)
%% cropFromAnchorPoints: crop out and rescale an image using specfic anchorpoints
% This function is used by Seedling.FindHypocotyl to use defined anchorpoints to determine where to
% crop out the sub-image. The image is cropped and then rescaled to size defined by scale_size.
%
%  Usage:
%      [img_out, bbox] = cropFromAnchorPoints(img_input, anchor_points, scale_size)
%
%  Input:
%      img_input: original image to crop and resize
%      anchor_points: [4 x 2] array defining the cropping anchorpoints of img_input
%      scale_size: [1 x 2] array defining the rescale size
%
%  Output:
%      img_out: cropped and rescaled image
%

%% Create crop box --> Crop image --> Rescale cropped image
bbox    = [0 0 anchor_points(4,1) anchor_points(2,2)]; % Crop region containing PreHypocotyl
cim1    = imcrop(img_input, bbox);                     % Crop image of PreHypocotyl
img_out = imresize(cim1, scale_size);                  % Final rescaled image

end
function img_out = cropFromAnchorPoints(img_input, anchor_points, scale_size)
%% cropFromAnchorPoints: crop out and rescale an image using specfic anchorpoints
% This function is used by Seedling.FindHypocotyl to use defined anchorpoints to determine where to
% crop out the sub-image. The image is cropped and then rescaled to size defined by scale_size.
%
%  Usage:
%      [output1, output2] = functionName(input1, input2)
%
%  Input:
%      img_input: original image to crop and resize
%      anchor_points: [4 x 2] array defining the cropping anchorpoints of img_input
%      scale_size: [1 x 2] array defining the rescale size
%
%  Output:
%      img_out: cropped and rescaled image
%


%% Wow this is so complicated
crp1    = [0 0 anchor_points(4,1) anchor_points(2,2)]; % Crop region containing PreHypocotyl
cim1    = imcrop(img_input, crp1);                     % Crop image of PreHypocotyl
img_out = imresize(cim1, scale_size);                  % Final rescaled image

end
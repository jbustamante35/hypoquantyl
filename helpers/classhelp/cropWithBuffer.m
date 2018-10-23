function [crpb, crpi] = cropWithBuffer(img, bounding_box, buff_pct, buff_val)
%% cropWithBuffer: cropping function that allows buffer space around cropped object
% This function is a modification of MATLAB's built-in imcrop function that simply extends the
% bounding box by a set value to buffer the final cropped image.
%
% Usage:
%   crp = cropWithBuffer(img, bounding_box, buff_pct, buff_val)
%
% Input:
%   img: full-sized inputted image to crop
%   bounding_box: [1 x 4] vector defining the x-/y-coordinate and row/column distance of an object
%   buff_pct: percentage to extend the range of the bounding_box parameter
%   buff_val: pixel intensity value to fill buffered region
%
% Output:
%   crpi: raw cropped image using built-in imcrop function
%   crpb: cropped image with buffered area
%

%% Get value for buffered portion of cropped image
crpi = imcrop(img, bounding_box);

%% Create rows and columns with median values of cropped image
buff_total = round((buff_pct / 100) * size(crpi, 2));

% Buffer rows
buff_rows(1:size(crpi, 1), 1:buff_total) = buff_val;
crop_rows                                = [buff_rows crpi buff_rows];

% Buffer columns
buff_cols(1:buff_total, 1:size(crop_rows, 2)) = buff_val;
crop_cols                                     = [buff_cols ; crop_rows ; buff_cols];

%% Return final cropped image with buffered regions
crpb = crop_cols;

end


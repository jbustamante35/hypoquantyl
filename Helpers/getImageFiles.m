function [im_out, exptDir] = getImageFiles(varargin)
%% getImageFiles: function to load images from directory
% This function takes a directory and image extension type as input, and loads the images into a 
% cell array based on date created. [make this modifiable if needed]
% 
% Usage:
%   im_out = getImageFiles(dir_in, im_ext, visualize)
% 
% Input: 
%   im_ext: 
%   sort_by: 
%   visualize: 
% 
% Output:
%   im_out: 
% 
% 

if nargin == 0
    im_ext    = input(sprintf('Enter image extension: '), 's');
    sort_by   = input(sprintf('Sort by what property? '), 's');
    visualize = false;
elseif nargin == 3
    im_ext    = varargin{1};
    sort_by   = varargin{2};
    visualize = varargin{3};
else
    fprintf(2, 'Error with input parameters. Please check again.\n');
    return;
end

%% Go to image directory and store in sorted table 
currDir = pwd;
cd(uigetdir(currDir, 'Select directory containing images'));
exptDir = pwd;
imPath = dir(['*.' im_ext]);
imTble = struct2table(imPath);
imSort = sortrows(imTble, sort_by);

%% Read images
im_out = cell(1, size(imSort, 1));
for i  = 1:length(im_out)
    im_out{i} = imread(imSort.name{i});
end

cd(currDir);
%% Iterate through images to verify correct order
if (visualize)
    figure;
    for i = 1:length(im_out)
        imagesc(im_out{i}), colormap gray, axis image, axis off;
        pause(0.001);
    end
end

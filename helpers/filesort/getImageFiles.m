function [im_out, exptDir] = getImageFiles(varargin)
%% getImageFiles: function to load images from directory
% Take a directory and image extension type as input, and load the images into 
% a cell array based on date created. [make this modifiable]
%
% Usage:
%   [im_out, exptDir] = getImageFiles(dir_in, im_ext, visualize)
%
% Input:
%   im_ext: file extension of images
%   sort_by: file property to sort images by
%   visualize: show images loading from this function
%
% Output:
%   im_out: cell array of all images loaded
%   exptDir: path to images loaded from this function
%

%%
if nargin == 0
    im_ext    = input(sprintf('Enter image extension: '), 's');
    sort_by   = input(sprintf('Sort by what property? '), 's');
    visualize = false;
    currDir = pwd;
    cd(uigetdir(currDir, 'Select directory containing images'));
    exptDir = pwd;

elseif iscell(varargin)
    expPrp    = varargin{1};
    im_ext    = varargin{2};
    sort_by   = varargin{3};
    visualize = varargin{4};
    currDir   = pwd;

    if isunix
        delim = '/';
    else
        delim = '\';
    end

    exptDir = [expPrp.folder , delim expPrp.name];
    cd(exptDir);

else
    fprintf(2, 'Error with input parameters. Please check again.\n');
    return;
end

%% Go to image directory and store in sorted table
imPath = dir(['*.' , im_ext]);
imTble = struct2table(imPath);
imSort = sortrows(imTble, sort_by);
imName = table2struct(imSort);
imFile = arrayfun(@(x) [x.folder , delim , x.name], imName, 'UniformOutput', 0);

%% Read image files and remove empty cells
im_out = cellfun(@(x) readOrReturn(x), imFile, 'UniformOutput', 0);
im_out = im_out(~cellfun('isempty', im_out));
cd(currDir);

%% Iterate through images to verify correct order
if visualize
    figure;
    for i = 1:length(im_out)
        imagesc(im_out{i}), colormap gray, axis image, axis off;
        drawnow;
    end
end
end

function im = readOrReturn(fin)
%% readOrDie: function to read image file or return empty cell
try im = imread(fin); catch; im = {}; end
end
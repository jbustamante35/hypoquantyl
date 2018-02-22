function [im_out, exptDir] = getImageFiles(varargin)
%% getImageFiles: function to load images from directory
% This function takes a directory and image extension type as input, and loads the images into a 
% cell array based on date created. [make this modifiable if needed]
% 
% Usage:
%   [im_out, exptDir] = getImageFiles(dir_in, im_ext, visualize)
% 
% Input: 
%   im_ext: 
%   sort_by: 
%   visualize: 
% 
% Output:
%   im_out: 
%   exptDir: 
% 

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
            exptDir = [expPrp.folder '/' expPrp.name];
        else
            exptDir = [expPrp.folder '\' expPrp.name];
        end

        cd(exptDir);

    else
        fprintf(2, 'Error with input parameters. Please check again.\n');
        return;
    end

    %% Go to image directory and store in sorted table 
    imPath = dir(['*.' im_ext]);
    imTble = struct2table(imPath);
    imSort = sortrows(imTble, sort_by);

    %% Read images
    im_out = cell(1, size(imSort, 1));
    for i  = 1:length(im_out)
        try
            im_out{i} = imread(imSort.name{i});
        catch 
    %         fprintf(2, '%s (%s) \n', e.message, imSort.name{i});
            continue;
        end
    end

    im_out = im_out(~cellfun('isempty',im_out));
    cd(currDir);

    %% Iterate through images to verify correct order
    if visualize
        figure;
        for i = 1:length(im_out)
            imagesc(im_out{i}), colormap gray, axis image, axis off;
            pause(0.001);
        end
    end

end

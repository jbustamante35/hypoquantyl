function [IMGS, CNTRS, IMG, CNTR] = loadImagesAndCurves(Ein, trnIdx)
%% loadImagesAndCurves: loads images and contours from an Experiment object
% Description
%
% Usage:
%   [IMGS, CNTRS, IMG, CNTR] = loadImagesAndCurves(Ein, trnIdx)
%
% Input:
%   Ein: Experiment object containing images and contours
%   trnIdx: indices of training set
%
% Output:
%   IMGS: cell array of all images
%   CNTRS: cell array of all contours
%   IMG: cell array of training set images
%   CNTR: cell array of training set contours
%
% Author Julian Bustamante <jbustamante@wisc.edu>
%
%% Extract images and contours from Experiment object
CRCS  = Ein.combineContours;
CNTRS = arrayfun(@(x) x.Curves, CRCS, 'UniformOutput', 0);
IMGS  = cellfun(@(x) double(x.getImage), CNTRS, 'UniformOutput', 0);

%% Split training set
if nargin < 2
    [IMG, CNTR] = deal([]);
else
    IMG = IMGS(trnIdx);
    CNTR = CNTRS(trnIdx);
end

end


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
if nargin < 2
    trnIdx = ':';
end

ex_class = class(Ein);
switch ex_class
    case 'Experiment'
        CRCS  = Ein.combineContours;
        CNTRS = arrayfun(@(x) x.Curves, CRCS, 'UniformOutput', 0);
        IMGS  = cellfun(@(x) double(x.getImage), CNTRS, 'UniformOutput', 0);
    case 'Curve'
        C     = Ein;
        CNTRS = arrayfun(@(c) c.getTrace, C, 'UniformOutput', 0);
        IMGS  = arrayfun(@(c) double(c.getImage), C, 'UniformOutput', 0);
    otherwise
        fprintf(2, 'Incorrect class %s [Experiment|Curve]\n', ex_class);
        return;
end

%% Split training set
if nargin < 2
    [IMG, CNTR] = deal([]);
else
    IMG  = IMGS(trnIdx);
    CNTR = CNTRS(trnIdx);
end

end


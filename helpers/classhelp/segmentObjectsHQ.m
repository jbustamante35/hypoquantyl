function [obs, msk] = segmentObjectsHQ(im, sz, sens)
%% segmentObjectsHQ: segment image to bw and filter out small objects
% This function takes a grayscale image, uses a simple Otsu method to segment
% into a bw image, then filters out smaller objects between the pixel range
% defined by sz parameter. Output is a structure obtained by MATLAB's
% bwconncomp function and the binary mask.
%
% Usage:
%  [obs, msk] = segmentObjectsHQ(im, sz, sens)
%
% Input:
%  im: grayscale image
%  sz: [2 x 1] array defining minimum and maximum range to search for objects
%  sens: sensitivity for alternative algorithm [recommended 0.6]
%
% Output:
%  obs: structure containing information about objects extracted from im
%  msk: binarized bw image
%
% This version is for HypoQuantyl

%% Use alternative function below [for automated training]
if nargin > 2
    [obs, msk] = altBinarization(im , sz, sens);
else
    % msk = imbinarize(im, 'adaptive', 'Sensitivity', 0.7, ...
    %   'ForegroundPolarity', 'bright');
    % flt = bwareafilt(imcomplement(msk), sz);
    sens = 0.4;
    sz   = [100 10000];
    
    msk = imbinarize(im, 'adaptive', 'Sensitivity', sens, ...
        'ForegroundPolarity', 'dark');
    flt = bwareafilt(imcomplement(msk), sz);
    obs = bwconncomp(flt);
    % msk = imcomplement(msk);
end

end

function [maxArea, bw] = altBinarization(im, sz, sens)
%% testBinarization: test out segmentation methods
% Find best parameters to segment hypocotyls with traditional methods
% Input:
%   im: grayscale image to segment
%   sz: dimensions to resize segmented image (currently[101 101])
%   sens: sensitivity [recommended 0.6]
%
% Output:
%   maxArea: area of object extracted from image
%   bw: resized and segmented image
%

% Some constants to play around with
% SZ = [100 , 1000000]; % [Min , Max] area of objects

%% Segmentation algorithm
% Binarize
adt = adaptthresh(im);
msk = imcomplement(imbinarize(adt, 'adaptive', 'Sensitivity', sens, ...
    'ForegroundPolarity', 'dark'));

% Extract largest object and resize to specified dimensions
prp                          = regionprops(msk, 'Area', 'PixelIdxList');
[maxArea , maxIdx]           = max(cell2mat(arrayfun(@(x) x.Area, ...
    prp, 'UniformOutput', 0)));
bw                           = zeros(sz);
bw(prp(maxIdx).PixelIdxList) = 1;

end

function [obs, msk] = segmentObjectsHQ(img, sz, sens, mth)
%% segmentObjectsHQ: segment image to bw and filter out small objects
% This function takes a grayscale image, uses a simple Otsu method to segment
% into a bw image, then filters out smaller objects between the pixel range
% defined by sz parameter. Output is a structure obtained by MATLAB's
% bwconncomp function and the binary mask.
%
% Usage:
%  [obs, msk] = segmentObjectsHQ(im, sz, sens, mth)
%
% Input:
%	img: grayscale image
%	sz: [2 x 1] array defining minimum and maximum range to search for objects
%	sens: sensitivity for alternative algorithm [recommended 0.6]
%	mth: method to use [default to method 1]
%
% Output:
%	obs: structure containing information about objects extracted from im
%	msk: binarized bw image
%
% This version is for HypoQuantyl

%% Use alternative function below [for automated training]
if nargin < 3
    sens = 0.4;
    mth  = 2;
end

switch mth
    case 1
        %
        % The sz parameter should be property data
        pdps        = sz;
        [obs , msk] = runMethod1(img, pdps);
        
    case 2
        %
        [obs , msk] = runMethod2(img, sz);
        
    case 3
        %
        [obs, msk] = runMethod3(img , sz, sens);
        
    otherwise
        fprintf(2, 'Incorrect method %s\nShould be [1|2|3]\n', string(mth));
        
end

end

function [prps , msk] = runMethod1(img, pdps)
%% runMethod1: dirt simple method for binary circle data
msk  = imbinarize(img);
flt  = bwareafilt(msk, 1);
obs  = bwconncomp(flt);
prps = regionprops(obs, img, pdps);

end

function [obs , msk] = runMethod2(img, fltsz, sensFix)
%% runMethod2: deprecated method to segment grayscale images
%
% Some constants to play around with
% SZ = [100 , 1000000]; % [Min , Max] area of objects
%

% Initialize sensivity calibrator at 0
if nargin < 3
    sensFix = 0;
end

% Figure out if dark or bright foreground
gt = graythresh(img);
if gt >= 0.5
    % Foreground is darker; lower sensitivity parameter
    sens = 0.5 - sensFix;
    fg   = 'dark';
else
    % Foreground is brighter; raise sensitivity parameter
    sens = 0.5 + sensFix;
%     fg   = 'bright';
    fg   = 'dark'; % I guess just always use dark foreground? 
end

%
msk  = imbinarize(img, 'adaptive', ...
    'Sensitivity', sens, 'ForegroundPolarity', fg);
flt  = bwareafilt(imcomplement(msk), fltsz);
obs  = bwconncomp(flt);

% Recursive fix to calibrate sensitivity
if obs.NumObjects == 0
    sensFix     = sensFix + 0.1;
    [obs , msk] = runMethod2(img, fltsz, sensFix);
end

end

function [maxArea, bw] = runMethod3(img, sz, sens)
%% runMethod3: alternative segmentation method for auto-training hypocotyls
% Find best parameters to segment hypocotyls with traditional methods
%
% Input:
%   img: grayscale image to segment
%   sz: dimensions to resize segmented image (currently[101 101])
%   sens: sensitivity [recommended 0.6]
%
% Output:
%   maxArea: area of object extracted from image
%   bw: resized and segmented image
%

%% Segmentation algorithm
% Binarize
adt = img;
msk = imcomplement(imbinarize(adt, 'adaptive', 'Sensitivity', sens, ...
    'ForegroundPolarity', 'dark'));

% Extract largest object and resize to specified dimensions
prp                          = regionprops(msk, 'Area', 'PixelIdxList');
[maxArea , maxIdx]           = max(cell2mat(arrayfun(@(x) x.Area, ...
    prp, 'UniformOutput', 0)));
bw                           = zeros(sz);
cla;clf;
myimagesc(bw);

%%
bw(prp(maxIdx).PixelIdxList) = 1;

end

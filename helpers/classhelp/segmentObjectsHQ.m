function [msk , obs] = segmentObjectsHQ(img, smth, sz, sens, mth)
%% segmentObjectsHQ: segment image to bw and filter out small objects
% This function takes a grayscale image, uses a simple Otsu method to segment
% into a bw image, then filters out smaller objects between the pixel range
% defined by sz parameter. Output is a structure obtained by MATLAB's
% bwconncomp function and the binary mask.
%
% Usage:
%  [msk , obs] = segmentObjectsHQ(img, smth, sz, sens, mth)
%
% Input:
%	img: grayscale image [recommended to use uint8]
%   smth: smoothing filter size [default 0]
%	sz: [min,max] range defining size to search for objects [default size(img)]
%	sens: sensitivity for alternative algorithm [recommended 0.6]
%	mth: method to use [default to method 3]
%
% Output:
%	msk: binarized bw image
%	obs: structure containing information about objects extracted from im
%
% This version is for HypoQuantyl

%% Use alternative function below [for automated training]
if nargin < 2; smth = 0;         end
if nargin < 3; sz   = size(img); end
if nargin < 4; sens = 0.6;       end
if nargin < 5; mth  = 3;         end

switch mth
    case 1
        %
        % The sz parameter should be property data
        pdps        = sz;
        [msk , obs] = runMethod1(img, pdps);
    case 2
        %
        [msk , obs] = runMethod2(img, sz, sens);
    case 3
        %
        [msk , obs] = runMethod3(img, sz, sens);
    otherwise
        fprintf(2, 'Incorrect method %s\nShould be [1|2|3]\n', string(mth));
        [msk , obs] = deal([]);
end

%% Run smoothing kernel
if smth
    ksz  = ceil(size(img,1) / smth);
    krnl = ones(ksz) / ksz^2;
    blr  = conv2(msk, krnl, 'same');
    msk  = blr > 0.5;
end

%% Convert to logical
msk = logical(msk);
end

function [msk , prps] = runMethod1(img, pdps)
%% runMethod1: dirt simple method for binary circle data
msk  = imbinarize(img);
flt  = bwareafilt(msk, 1);
obs  = bwconncomp(flt);
prps = regionprops(obs, img, pdps);
end

function [msk , obs] = runMethod2(img, fltsz, fg, sensFix)
%% runMethod2: deprecated method to segment grayscale images
%
% Some constants to play around with
% SZ = [100 , 1000000]; % [Min , Max] area of objects
%

%% Initialize sensivity calibrator at 0
if nargin < 4; sensFix = 0; end

% Figure out if dark or bright foreground
sens = 0.5;
if isempty(fg)
    gt = graythresh(img);
    if gt >= 0.5
        % Foreground is darker; lower sensitivity parameter
        sens = 0.5 - sensFix;
        %     fg   = 'dark';
        fg   = 'bright';
    else
        % Foreground is brighter; raise sensitivity parameter
        sens = 0.5 + sensFix;
        %     fg   = 'bright';
        fg   = 'dark'; % I guess just always use dark foreground?
    end
end

%
msk = imcomplement(imbinarize(img, 'adaptive', 'Sensitivity', ...
    sens, 'ForegroundPolarity', fg));
flt = bwareafilt(msk, fltsz);
obs = bwconncomp(flt);

% Recursive fix to calibrate sensitivity
if obs.NumObjects == 0
    switch fg
        case 'bright'
            sensFix = sensFix + 0.1;
        case 'dark'
            sensFix = sensFix - 0.1;
    end

    [msk , obs] = runMethod2(img, fltsz, fg, sensFix);
end
end

function [msk , maxArea] = runMethod3(img, sz, sens)
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
% sens at 0.60 works best [0.59 and 0.61 are bad...]
fg  = 'dark';
% fg  = 'bright';

% Binarize
% adt = img;
adt = int32(img);

msk = imcomplement(imbinarize(adt, 'adaptive', ...
    'Sensitivity', sens, 'ForegroundPolarity', fg));
% msk = imbinarize(adt, 'adaptive', ...
%     'Sensitivity', sens, 'ForegroundPolarity', fg);

%% Extract largest object and resize to specified dimensions
prp                          = regionprops(msk, 'Area', 'PixelIdxList');
[maxArea , maxIdx]           = max(cell2mat(arrayfun(@(x) x.Area, ...
    prp, 'UniformOutput', 0)));
msk                           = zeros(sz);
msk(prp(maxIdx).PixelIdxList) = 1;
end

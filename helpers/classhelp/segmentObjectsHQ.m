function [obs, msk] = segmentObjectsHQ(im, sz)
%% segmentObjectsHQ: segment image to bw and filter out small objects
% This function takes a grayscale image, uses simple Otsu method to segment
% into bw image, then filters out smaller objects between the pixel range
% defined by sz parameter. Output is a structure obtained by MATLAB's
% bwconncomp function.
%
% Usage:
%  [obs, msk] = segmentObjectsHQ(im, sz)
%
% Input:
%  im: grayscale image
%  sz: [2 x 1] array defining minimum and maximum range to search for objects
%
% Output:
%  obs: structure containing information about objects extracted from im
%  msk: binarized bw image
%
% This version is for HypoQuantyl

% msk = imbinarize(im, 'adaptive', 'Sensitivity', 0.7, ...
%   'ForegroundPolarity', 'bright');
% flt = bwareafilt(imcomplement(msk), sz);
msk = imbinarize(im, 'adaptive', 'Sensitivity', 0.4, ...
    'ForegroundPolarity', 'dark');
flt = bwareafilt(imcomplement(msk), sz);
obs = bwconncomp(flt);
% msk = imcomplement(msk);

end

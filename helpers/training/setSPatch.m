function [spatch, patchData] = setSPatch(seg, img, BNZ, SCL)
%% setSPatch: set S-Patch from S-Vector segment onto image
% This became a simple wrapper script for getStraightenedMask because I ended up
% using a slightly modified algorithm.
%
% Usage:
%   [spatch, patchData] = setSPatch(seg, img, bnz, dscl)
%
% Input:
%   seg: x-/y-coordinates of segment to map to image
%   img: image to interpolate pixels from coordinates
%   BNZ: boolean to binarize the final mask [for bw objects]
%   DSCL: scaler to extend normal to desired distance [in pixels]
%
% Output:
%   smsk: straightened image
%   sdata: extra data for visualization or debugging
%

%% Set default scale factor scl to 10% of image size if not set
if nargin < 3
    % Set binarization off and scale output by 10% of image size
    BNZ = false;
    SCL = ceil(size(img,1) * 0.1);
end

[spatch, patchData] = getStraightenedMask(seg, img, BNZ, SCL);

end



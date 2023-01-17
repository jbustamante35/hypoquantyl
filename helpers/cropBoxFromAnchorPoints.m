function [cbox , bcrp] = cropBoxFromAnchorPoints(msk, hln, hoff, scl, img)
%% cropBoxFromAnchorPoints
%
% Usage:
%   sbuf = cropBoxFromAnchorPoints(msk, hln, hoff, scl)
%
% Input:
%   msk:
%   hln:
%   hoff:
%   scl:
%
% Output:
%   cbox:
%   bcrp:
%
if nargin < 2; hln  = 250;             end
if nargin < 3; hoff = [0 , 0 , 0 , 0]; end
if nargin < 2; scl  = [101 , 101];     end
if nargin < 2; img  = [];              end

% Crop using mask if no grayscale image inputted
if isempty(img); img = msk; end

apts          = bwAnchorPoints(msk, hln, hoff);
[bcrp , cbox] = cropFromAnchorPoints(img, apts, scl);
end
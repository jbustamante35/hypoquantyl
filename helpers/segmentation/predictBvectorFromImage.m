function [bvec , zout] = predictBvectorFromImage(img, bnet, zin, alt_return, ymin, w, by)
%% displaceBvector
%
%
% Usage:
%   zout = predictBvectorFromImage(img, bnet, zin, alt_return, ymin, w, by)
%
% Input:
%   img:
%   bnet:
%   zin:
%   alt_return: return B-Vector (0) or displaced Z-Vector (1) [default 0]
%   w:
%   by:
%
% Output:
%   zout:
%

%%
isz = size(img,1);
if nargin < 3; zin        = zeros(209,6)            ; end
if nargin < 4; alt_return = 0                       ; end
if nargin < 5; ymin       = 10                      ; end
if nargin < 6; w          = isz - ymin : isz        ; end
if nargin < 7; by         = isz - ymin + (ymin / 2) ; end

%
wimg = img(w,:);
bx   = double(bnet.predict(wimg));
bvec = [bx , by];

zout = [];
if ~isempty(zin); zout = [zin(:,1:2) + bvec , zin(:,3:end)]; end

% Return B-Vector or Z-Vector as first output
if alt_return; balt = bvec; bvec = zout; zout = balt; end
end

function [p , pshp] = sampleDomain(img, dom, shp)
%% sampleDomain: sample image at domain and reshape
%
%
% Usage:
%   [p , pshp] = sampleDomain(img, dom, shp)
%
% Input:
%   img: image to sample
%   dom: vectorized domain
%   shp: size to reshape sampled domain
%
% Output:
%   p: vectorized sampled domain
%   pshp: reshaped sampled domain
%

%
if nargin < 3; shp = []; end

%
p = ba_interp2(img, dom(:,1), dom(:,2));

%
pshp = [];
if shp
    pshp = reshape(p, shp);
end
end
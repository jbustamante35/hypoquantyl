function [crds, bmsk] = bwmorphjb(cntr, sz, varargin)
%% bwmorphjb: bwmorph wrapper that makes it easier to obtain coordinates
% Description
%
% If no additional arguments are given (nargin == 2), then the default is to
% obtain the core branching skeleton from the distance transform. This can then
% be used to compute the midline from the skeletonized mask.
%
% Usage:
%    [crds, bmsk] = bwmorphjb(cntr, sz, varargin)
%
% Input:
%    cntr: x-/y-coordinates of the contour OR the core skeletonized mask
%    sz: size of the image to generate the mask
%
% Output:
%    crds: x-/y-coordinates of the points computed from the mask
%    bmsk: binary mask that the coordinates are mapped from
%
% Author Julian Bustamante <jbustamante@wisc.edu>
%

%%
if nargin < 3
    % Default to generating the core skeleton
    methd   = 'skel';
    param   = Inf;
    getMask = 1;
else
    % Run with customized parameters
    methd   = varargin{1};
    if numel(varargin) > 1
        param   = varargin{2};
        getMask = varargin{3};
    else
        param   = [];
        getMask = 0; % Variable cntr assumed to be mask
    end
end

%%
if getMask
    bws = poly2mask(cntr(:,1), cntr(:,2), sz(1), sz(2));
else
    bws = cntr; % Variable cntr assumed to be mask
end

%
if isempty(param)
    bmsk = bwmorph(bws, methd);
else
    bmsk = bwmorph(bws, methd, param);
end

%
[by, bx] = find(bmsk);
crds     = [bx , by];

end



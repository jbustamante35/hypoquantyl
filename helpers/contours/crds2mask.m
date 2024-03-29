function msk = crds2mask(img, crds, buff, keep_org_size)
%% crds2mask: create logical mask with input coordinates set to true
% This function sets up a probability distribution matrix by creating a logical
% mask where pixels containing a contour are set to true.
%
% Usage:
%   msk = crds2mask(img, crd, buff)
%
% Input:
%   img: inputted image
%   crd: set of x-/y-coordinates corresponding to inputted image
%   buff: range to extend mask image
%
% Output:
%   msk: logical mask the size of inputted image, with coordinates set to true
%

%%
if nargin < 3; buff          = 2; end
if nargin < 4; keep_org_size = 1; end

%% Convert coordinates to integers if needed
if ~startsWith(class(crds), 'int')
    crds           = floor(crds);
    crds(crds == 0) = 1;
end

%% Create mask and set coordinates to true
% Setup / initialization.
% [Original - DEPRECATED]
% WHAT IS ORG?! WHY DIVIDE BY 2.5?! eff my life [me in 11/28/2018]
% msk = createMask(size(img), buff);
% org = [round(size(msk,2)/2.5) size(msk,1)];
% crd = slideCoords(crd, org);

% Setup / initialization.
% [Update 06.19.2019]
orgSize = size(img);
msk     = createMask(orgSize, buff);

try
    idx = sub2ind(size(msk), crds(:,2), crds(:,1));
catch
    % Subtract y-coordinates by size of out-of-bounds coordinates
    % Should this subtract both x-/y-coordinates?
    crd_max = mode(crds(crds(:,2) == max(crds(:,2)), 2) - org(2));
    org(2)  = org(2) - crd_max;
    crds    = slideCoords(crds, org);
    idx     = sub2ind(size(msk), crds(:,2), crds(:,1));
end

msk(idx) = true;

% Reduce final mask to size of original image
if keep_org_size; msk = msk(1 : orgSize(1) , 1 : orgSize(2)); end
end

function m = createMask(sz, buff)
%% createMask: subfunction to create mask of different size than original image
% This tests what happens if you give the mask a buffer of specified pixels
% Input:
%   sz: size of original image
%   buff: number pixels to buffer by
if buff; b = floor(sz * buff); else; b = floor(sz); end
m = zeros(b);
end

function c = slideCoords(crd, org)
%% Slide x-coordinates to common starting point
d = org - crd(1,:);
c = crd + d;
end
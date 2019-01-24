function [P, buffVert] = patchFromCoord(seg, pm, mid, img, buff, sz)
%% patchFromCoord: generate an image patch centered around given coordinate
% This function takes the given coordinate and generates a square image patch of
% the size of the sz parameter. 
%
% Usage:
%   [P, buffVert] = patchFromCoord(seg, pm, mid, img, buff, sz)
%
% Input:
%   crd: coordinate in image to create a patch from
%   img: corresponding image containing inputted coordinate
%   buff: percentage to buffer crop box region
%   sz: distance from center coordinate to normalize size of patch
%
% Output:
%   P: image patch of size [sz sz] centered around crd parameter 
%   buffVert: vertices of buffered crop box
%

%% Rotate image along tangent vector
% Normalize to midpoint reference frame if not already converted
if median(sum(seg > 0) == size(seg,1))
    % If true, seg has no negative coordinates and should be converted
    cnv = getDim((pm * [seg ones(length(seg), 1)]')', 1:2);    
else    
    % If false, seg has negative coordinates and is already converted
    cnv = seg;
end

%% Get coordinates of crop box
% Get min and max coordinates of normalized segment
[~, minIdx] = min(cnv);
cnvMinRow   = cnv(minIdx(1), :);
cnvMinCol   = cnv(minIdx(2), :);

[~, maxIdx] = max(cnv);
cnvMaxRow   = cnv(maxIdx(1), :);
cnvMaxCol   = cnv(maxIdx(2), :);

% Generate cropbox from rectangle vertices
cbX     = [cnvMinRow(1) , cnvMaxRow(1) , cnvMaxRow(1) , cnvMinRow(1)];
cbY     = [cnvMinCol(2) , cnvMinCol(2) , cnvMaxCol(2) , cnvMaxCol(2)];
cbVert  = [cbX' cbY'];

% Buffer cropbox region by defined percentage area
buffVert = adjustVertices(cbVert, buff);

%% Get pixel intensities from crop box
% Split crop box into interpolated columns of coordinates
% NOTE: indices for top and bottom of crop box may change over time
cbTop = [buffVert(4,:) ; buffVert(3,:)];
cbBot = [buffVert(1,:) ; buffVert(2,:)];
intT  = interpolateOutline(cbTop, sz);
intB  = interpolateOutline(cbBot, sz);

%%

% Interpolate segments of columns
% Straight segments will make interpolation impossible, so use method to 
crds = arrayfun(@(x) interpolateOutline([intT(x,:) ; intB(x,:)], sz), ...
    1 : sz, 'UniformOutput', 0);

%% Map segmentated-interpolated coordinates to image
pxls = cellfun(@(x) mapCurve2Image(x, img, pm ,mid), crds, 'UniformOutput', 0);
P    = cat(2, pxls{:});

end

function V = adjustVertices(vert, buff)
%% adjustVertices: translate rectangle vertices to buffer area
% Move all 4 rectangle's vertices by a buff percentage
%
% Input:
%   vert: rectangle's vertices
%   buff: percentage to buffer rectangle
%
% Output:
%   V: new rectangle's vertices
%

% Set constant parameter to deal with edge cases where vertices overlap when
% segment is a straight line 
C = 0.001;

% Define initial vertices locations
% NOTE: These may change over time
oldTL = vert(1,:);
oldTR = vert(2,:);
oldBR = vert(3,:);
oldBL = vert(4,:);

% Compute distance to translate
rectArea = boxArea(oldTL, oldTR, oldBL);
trnsDist = ((rectArea * buff) + C) / 4;

% Get new vertices coordinates
newTL = [oldTL(1)-trnsDist , oldTL(2)-trnsDist];
newTR = [oldTR(1)+trnsDist , oldTR(2)-trnsDist];
newBR = [oldBR(1)+trnsDist , oldBR(2)+trnsDist];
newBL = [oldBL(1)-trnsDist , oldBL(2)+trnsDist];
V     = [newTL ; newTR ; newBR ; newBL];

end

function A = boxArea(tl, tr, bl)
%% boxArea: Calculate area of a rectangle based on vertices
% Literally L x W, but using defined sides
%
% Input:
%   tl: top-left vertex
%   tr: top-right vertex
%   bl: bottom-left vertex
%
% Output:
%   A: area of rectangle
%

L = pdist([tl ; tr]);
H = pdist([tl ; bl]);
A = L * H;

end
function apts = calcAnchorPoints(pList, ln, bgap)
%% calcAnchorPoints: find anchorpoints for cropping out Hypocotyl
% This function takes the 2x1 pixel index matrix to identify the 4
% anchor points for creating a crop box that represents the
% Hypocotyl of a Seedling. The 4 anchor points refer to the
% top-most pixel (a), the bottom pixel at the point (a) - lng (b),
% left-most pixel (c), and the right-most pixel (d).
%
% The pixel coordinates list represents the individual Seedling's
% coordinates, rather than the entire raw image's pixel list.
%
% Usage:
%   apts = calcAnchorPoints(pList, ln, bgap)
%
% Input:
%   pIdx: pixel index of given image and frame
%   lng : cutoff distance to bottom of crop box [default 250]
%   bgap: distance to set crop buffer [default 0]
%
% Output:
%   pts: (4 x 2) array indicating 4 anchorpoints on Seedling object

if nargin < 2; ln   = 250; end
if nargin < 3; bgap = 0;   end

%% Filter pixel coordinate range to limit search to upper region only
apts   = zeros(4, 2);
% rowRng = pList(pList(:,2) <= ln, :);

minIdx = min(pList);
ytop   = minIdx(2);
rowRng = pList(pList(:,2) <= ytop + ln, :);

%% Make separate Helper function for all 4 anchor points
% Point A: highest pixel (minimum row coordinate)
minrow    = rowRng(rowRng(:,2) == min(rowRng(:,2)), :);
apts(1,:) = ceil([median(minrow(:,1)) min(minrow(:,2))]);

% Point B: Point A - cut-off low coordinate to crop
maxrow    = rowRng(rowRng(:,2) == max(rowRng(:,2)), :);
apts(2,:) = ceil([median(maxrow(:,1)) max(maxrow(:,2))]);

% Point C: left-most pixel
mincol    = rowRng(rowRng(:,1) == min(rowRng(:,1)), :);
apts(3,:) = ceil([min(mincol(:,1)) median(mincol(:,2))]);

% Point D: right-most pixel
maxcol    = rowRng(rowRng(:,1) == max(rowRng(:,1)), :);
apts(4,:) = ceil([max(maxcol(:,1)) median(maxcol(:,2))]);

%% Set buffer distances
% Buffering can be set per direction or just same in each direction
if numel(bgap) > 1
    % Buffer in [top , bottom , left , right]
    bpts = [0 , -bgap(1) ; 0 , bgap(2) ; -bgap(3) , 0 ; bgap(4) , 0];
else
    % Flat buffering in each direction
    bpts = [0 , -bgap ; 0 , bgap ; -bgap , 0 ; bgap , 0];
end

apts = apts + bpts;
end
function [trc , skltn] = primeMidline(img, cntr, INTRP, TERMPCT, PADLENGTH)
%% primeMidline
% Description
%
% Usage:
%   trc = primeMidline(img, cntr, INTRP, TERMPCT)
%
% Input:
%   img: image associated with contour
%   cntr: contour around object
%   INTRP: number of coordinates to interpolate to (default 50)
%   TERMPCT: percentage to set termination point (default 0.70)
%   PADLENGTH: number of replicating rows to add to base of image (default 20)
%
% Output:
%   trc: primed midline computed from distance transform
%
% Author Julian Bustamante <jbustamante@wisc.edu>
%

%% Skeletonize, dijkstras, anchor, then interpolate
switch nargin
    case 2
        INTRP     = 50;
        TERMPCT   = 0.70;
        PADLENGTH = 20;
    case 3
        TERMPCT   = 0.70;
        PADLENGTH = 20;
    case 4
        PADLENGTH = 20;
    case 5
    otherwise
        fprintf(2, 'Incorrect number of inputs (%d of %d)\n', nargin, 5);
        [trc , skltn] = deal([]);
        return;
end

baki = img;
bakc = cntr;

% Pad base of image to extend mask, then extend contour
img          = padarray(img, [PADLENGTH , 0], 'post', 'replicate');
bidx         = find(labelContour(cntr));
cntr(bidx,:) = [cntr(bidx,1) , cntr(bidx,2) + PADLENGTH];
cntr         = interpolateOutline(cntr, size(cntr,1));

% Create a skeleton and graph, then compute longest path between branch points
skltn = Skeleton('Image', img, 'Contour', cntr);
skltn.RunPipeline([]);
trc   = skltn.getLongestRoute('branches');

% Remove padded region on contour and longest route
% NOTE: Use max row of contour since not all contours are fixed to bottom
cntr(cntr(:,2) > size(img,2),:) = [];

% Close curve if still open
if ~all(cntr(1,:) == cntr(end,:))
    cntr(end+1,:) = cntr(1,:);
end

cntr                             = interpolateOutline(cntr, size(bakc,1));
trc(trc(:,2) > max(cntr(:,2)),:) = [];
trc                              = interpolateOutline(trc, INTRP);

% Anchor first coordinate to base of contour
[~ , bidx] = resetContourBase(cntr);
trc(1,:)   = cntr(bidx,:);

% Remove top x percent [simulates termination point]
termidx = round(TERMPCT * size(trc,1));
trc     = trc(1:termidx,:);

% Interpolate to finalize curve
trc = interpolateOutline(trc, INTRP);

end

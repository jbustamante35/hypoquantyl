function trc = primeMidline(img, cntr, INTRP, TERMPCT)
%% primeMidline
% Description
%
% Usage:
%   trc = primeMidline(img, cntr, INTRP, TERMPCT)
%
% Input:
%   img: image associated with contour
%   cntr: contour around object
%   INTRP: number of coordinates to interpolate to (default 20)
%   TERMPCT: percentage to set termination point (default 0.70)
%
% Output:
%   trc: primed midline computed from distance transform
%
% Author Julian Bustamante <jbustamante@wisc.edu>
%

%% Skeletonize, dijkstras, anchor, then interpolate
switch nargin
    case 2
        INTRP   = 20;
        TERMPCT = 0.70;
    case 3
        TERMPCT = 0.70;
end

% Create a skeleton and graph, then compute longest path between branch points
skltn = Skeleton('Image', img, 'Contour', cntr);
skltn.RunPipeline([]);
trc   = skltn.getLongestRoute('branches');

% Anchor first coordinate to base of contour
[~ , bidx] = resetContourBase(cntr);
trc(1,:)   = cntr(bidx,:);

% Remove top x percent [simulates termination point]
termidx = round(TERMPCT * size(trc,1));
trc     = trc(1:termidx,:);

% Interpolate to finalize curve
trc = interpolateOutline(trc, INTRP);

end

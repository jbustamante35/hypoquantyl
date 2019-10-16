function h = drawPoints(im, clr, ttl)
%% drawPoints: use impoly to draw points on inputted image
% This function is used for drawing raw outlines and anchorpoints on CircuitJB
% objects. User can define the color of the outline with the clr parameter.
%
% Usage:
%   h = drawPoints(im, clr)
%
% Input:
%   im: image to show on figure
%   clr: color for the plotted points
%   ttl: string to prompt user of what object to draw
%
% Output:
%   h: object handle for plotted points
%

%% Set-up figure, Show image, Place Points
plt = subplot(1, 1, 1);
imagesc(im, 'Parent', plt);
colormap gray;
axis image;
title(sprintf('Draw %s', ttl));
h = drawpolygon(plt, 'Color', clr);
end


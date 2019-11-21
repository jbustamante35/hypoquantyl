function h = drawPoints(img, clr, msg)
%% drawPoints: use impoly to draw points on inputted image
% This function is used for drawing raw outlines and anchorpoints on CircuitJB
% objects. User can define the color of the outline with the clr parameter.
%
% Usage:
%   h = drawPoints(img, clr, ttl)
%
% Input:
%   img: image to show on figure
%   clr: color for the plotted points
%   msg: message string to place title
%
% Output:
%   h: object handle for plotted points
%

%% Set-up figure, Show image, Place Points
plt = subplot(1, 1, 1);
% myimagesc(img);
imagesc(img, 'Parent', plt);
colormap gray;
axis image;
axis off;
title(sprintf('Draw %s', msg), 'FontSize', 6);
h = drawpolygon(plt, 'Color', clr);
end


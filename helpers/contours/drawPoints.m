function h = drawPoints(img, clr, msg, miscpts)
%% drawPoints: use impoly to draw points on inputted image
% This function is used for drawing raw outlines and anchorpoints on CircuitJB
% objects. User can define the color of the outline with the clr parameter.
%
% Usage:
%   h = drawPoints(img, clr, msg, miscpts)
%
% Input:
%   img: image to show on figure
%   clr: color for the plotted points
%   msg: message string to place title
%   miscpts: miscellaneous points to plot (optional)
%
% Output:
%   h: object handle for plotted points
%

if nargin < 4
    miscpts = 0;
end

%% Set-up figure, Show image, Place Points
splot = subplot(1, 1, 1);
% myimagesc(img);
imagesc(img, 'Parent', splot);
colormap gray;
axis image;
axis off;
title(sprintf('Draw %s', msg), 'FontSize', 6);

if miscpts ~= 0
    hold on;
    plt(miscpts, 'g.', 5);
end

h = drawpolygon(splot, 'Color', clr);
end


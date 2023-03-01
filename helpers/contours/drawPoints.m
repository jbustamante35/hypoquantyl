function h = drawPoints(img, hinit, clr, msg, miscpts, fidx)
%% drawPoints: use impoly to draw points on inputted image
% This function is used for drawing raw outlines and anchorpoints on CircuitJB
% objects. User can define the color of the outline with the clr parameter.
%
% Usage:
%   h = drawPoints(img, hinit, clr, msg, miscpts, fidx)
%
% Input:
%   img: image to show on figure
%   hinit: initialize with a primed contour
%   clr: color for the plotted points
%   msg: message string to place title
%   miscpts: miscellaneous points to plot (optional)
%
% Output:
%   h: object handle for plotted points
%
if nargin < 2; hinit   = [];        end
if nargin < 3; clr     = 'y';       end
if nargin < 4; msg     = 'Outline'; end
if nargin < 5; miscpts = 0;         end
if nargin < 6; fidx    = 1;         end

% Set-up figure, Show image, Place Points
set(0, 'CurrentFigure', fidx);
splot = subplot(1, 1, 1);
imagesc(img, 'Parent', splot);
colormap gray; axis image; axis off;
title(sprintf('Draw %s', msg), 'FontSize', 6);

if miscpts ~= 0; hold on; plt(miscpts, 'g.', 5); end

if ~isempty(hinit)
    %% Prime with initial segmentation results
    trc = interpolateOutline(hinit.Trace, hinit.InterpSize);
    h   = drawpolygon(splot, 'Color', clr, 'Position', trc);
else
    %% Manually trace new contour
    h = drawpolygon(splot, 'Color', clr);
end
end

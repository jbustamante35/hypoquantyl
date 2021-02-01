function [trg , q] = contourMidlineIntersection(cntr, mline, mnrm, npts, mth)
%% contourMidlineIntersection: find intersection points of a contour's midline
% Description
%
% Usage:
%   [trg , q] = contourMidlineIntersection(cntr, mline, mnrm, npts, mth)
%
% Input:
%   cntr: contour coordinates
%   mline: midline coordinates
%   mnrm: normal vector field around the midline
%   npts: number of points to interpolate the contour (default 5000)
%   mth: method to find intersecting contour point [snap|fmin] (default snap)
%
% Output:
%   OUT:
%
% Author Julian Bustamante <jbustamante@wisc.edu>
%

%%
switch nargin
    case 3
        npts = 5000;
        mth  = 'snap';
    case 4
        mth = 'snap';
    case 5
    otherwise
        fprintf(2, 'Error with inputs (%d)\n', nargin);
        alpha = [];
        return;
end

%% % Find targets from midline and half-way points to targets
switch mth
    case 'snap'
        % Quick Delaunay triangulation to snap to nearest contour point
        trg   = snap2curve(mline, cntr, 'delaunay');
        hidx  = size(cntr,1) / 2;
        mtrg1 = snap2curve(mline, cntr(1 : hidx,:), 'delaunay');
        mtrg2 = snap2curve(mline, cntr(hidx+1 : end,:), 'delaunay');
        q     = mtrg1 - mline;
        q2    = mtrg2 - mline;

        %
        [cnrm , ctng] = getVectorField(cntr);
        trg           = snap2curve(cntr(1:hidx,:), mline, 'delaunay');
        trg2          = snap2curve(cntr(hidx+1:end,:), mline, 'delaunay');
        q             = trg - cntr(1:hidx,:);
        q2            = trg2 - cntr(hidx+1:end,:);


        % Place-holder return value because I don't know what I'm doing
        alpha = trg;

    case 'fmin'
        % Minimization function to find nearest point along normal field
        cntr = interpolateOutline(cntr, npts);
        func = @(x,v) @(alpha) computeCrdMin(cntr, x + (alpha * v));

        alpha = zeros(size(mline,1), 1);
        for e = 1 : size(mline,1)
            alpha(e) = fminsearch(func(mline(e,:), mnrm(e,:)), 5);
        end

        % Compute targets and half-way points to targets
        trg = bsxfun(@times, alpha, mnrm) + mline;
        q   = deal(trg - mline);

    otherwise
        fprintf(2, 'Error with method %s [snap|fmin]\n', mth);
        alpha = [];
        return;
end

% Plot targets and half-way points from targets
% plt(cntr, 'g-', 2);
% axis image; axis ij; hold on;
% plt(mline, 'r-', 2);
%
% quiver(mline(:,1), mline(:,2), q(:,1), q(:,2), 0, 'Color', 'k');
% quiver(mline(:,1), mline(:,2), q2(:,1), q2(:,2), 0, 'Color', 'k');
%
% quiver(cntr(1:hidx,1), cntr(1:hidx,2), q1(:,1), q1(:,2), 0, 'Color', 'k');
% quiver(cntr(hidx+1:end,1), cntr(hidx+1:end,2), q2(:,1), q2(:,2), 0, 'Color', 'k');
%
% ttl = sprintf('Method [%s]', mth);
% title(ttl, 'FontSize', 10);

end

function d = computeCrdMin(cntr, crd)
%% computeCrdMin: get minimum of
d = cntr - crd;
d = sum(d .^2, 2) .^ 0.5;
d = min(d);
end

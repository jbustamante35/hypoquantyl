function fnm = showCurve_simple(img, cntr, fidx, n, N)
%% showCurve_simple: plot a curve on an image
%
%
% Usage:
%   fnm = showCurve_simple(img, cntr, fidx, n, N)
%
% Input:
%   img: image used for predictor
%   cntr: a curve, any curve
%   fidx: figure handle index [default 0]
%   n: index of curve from dataset [default 0]
%   N: total number of curves from dataset [default 0]
%
% Output:
%   fnm: figure name
%

if nargin < 3; fidx = 0; end
if nargin < 4; n    = 0; end
if nargin < 5; N    = 0; end

if fidx; figclr(fidx); end

myimagesc(img);
hold on;
plt(cntr, 'g-', 2);

if n
    if N
        ttl = sprintf('Curve %d of %d', n, N);
    else
        ttl = sprintf('Curve %d', n);
    end
else
    ttl = '';
end

title(ttl, 'FontSize', 10);

drawnow;

% Store figure name to save later
fnm = sprintf('%s_curve%03dof%03d', tdate, n, N);
end
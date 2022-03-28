function gout = interpolateGrid(gin, xtrp, ytrp, fsmth)
%% interpolateGrid: interapolation of a 2D grid
%
% Usage:
%   gout = interpolateGrid(gin, ftrp, ltrp)
%
% Input:
%   gin: inputted 2D grid
%   xtrp: interpolation size for x-axis
%   ytrp: interpolation size for y-axis
%   fsmth: radius of disk for smoothing [default 0]
%
% Output:
%   gout: interpolated grid

if nargin < 2; xtrp  = 100; end
if nargin < 3; ytrp  = 100; end
if nargin < 4; fsmth = 0;   end

% Generate interpolated spaces
[xin , yin] = size(gin);
[pt , pu]   = ndgrid(1 : yin, linspace(0, 1, xin));
[gt , gu]   = ndgrid(linspace(1, yin, xtrp), linspace(0, 1, ytrp));

% Smoothing if specified
if fsmth; gin = imfilter(gin, fspecial('disk', fsmth), 'replicate'); end

% Make gridded interpolant and operate on input grid
QQ   = griddedInterpolant(pt, pu, gin', 'cubic');
gout = QQ(gt,gu)';
end

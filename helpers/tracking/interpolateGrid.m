function gout = interpolateGrid(gin, varargin)
%% interpolateGrid: interapolation of a 2D grid
%
% Usage:
%   gout = interpolateGrid(gin, varargin)
%
% Input:
%   gin: inputted 2D grid
%   varargin: various inputs
%       xtrp: interpolation size for x-axis
%       ytrp: interpolation size for y-axis
%       fsmth: radius of disk for smoothing [default 0]
%
% Output:
%   gout: interpolated grid

%% Parse inputs
args = parseInputs(varargin);
for fn = fieldnames(args)'
    feval(@() assignin('caller', cell2mat(fn), args.(cell2mat(fn))));
end

% Determine interpolation sizes
% [xin , yin] = size(gin);
[yin , xin] = size(gin);
if isempty(xtrp); xtrp = xin; end
if isempty(ytrp); ytrp = yin; end

% Generate interpolated spaces
[pt , pu]   = ndgrid(1 : xin, linspace(0, 1, yin));
[gt , gu]   = ndgrid(linspace(1, xin, xtrp), linspace(0, 1, ytrp));

% Smoothing if specified
if fsmth; gin = imfilter(gin, fspecial(smooth_shape, fsmth), 'replicate'); end

% Make gridded interpolant and operate on input grid
QQ   = griddedInterpolant(pt, pu, gin', interp_method);
gout = QQ(gt,gu)';
end

function args = parseInputs(varargin)
%% Parse input parameters for Constructor method
p = inputParser;

% Misc Options
p.addOptional('xtrp', []);
p.addOptional('ytrp', []);
p.addOptional('fsmth', 0);
p.addOptional('smooth_shape', 'disk');
p.addOptional('interp_method', 'cubic');

% Parse arguments and output into structure
p.parse(varargin{1}{:});
args = p.Results;
end

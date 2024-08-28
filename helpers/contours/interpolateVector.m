function Y = interpolateVector(X, ncrds, span, smth)
%% interpolateVector: interpolation of single vector
%
% Usage:
%   Y = interpolateVector(X, ncrds, span, smth)
%
% Input:
%   X: vector to interpolate
%   ncrds: coordinates to interpolate [default numel(X)]
%   span: smoothing value [default 0]
%   smth: smoothing algorithm [default 'sgolay']
%   
%
% Output:
%   Y: smoothed interpolated vector

if nargin < 2; ncrds = numel(X); end
if nargin < 3; span  = 0;        end
if nargin < 4; smth  = 'sgolay'; end

[rows , cols] = size(X);
Xa            = 1 : numel(X);
Xq            = linspace(min(Xa), max(Xa), ncrds);

if rows > cols; Xq = Xq'; end
Y  = interp1(Xa, X, Xq);

if span
    % Smooth vector
    Y = smooth(Y, span, smth);
end
end
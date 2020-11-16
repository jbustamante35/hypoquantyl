function crc = makeCircle(r, x, y, z, s, e, toRound)
%% makeFakeCircle: generate fake CircuitJB object
% asdf
%
% Usage:
%   crc = makeCircle(r, x, y, z, s, e, toRound)
%
% Inputs:
%   r: radius
%   x: x-coordinate of center
%   y: y-coordinate of center
%   z: number of points to place around the circle
%   toRound: round coordinates (for mapping onto images)
%
% Output:
%   crc: coordinates of the circle
%

%% Make circles on images
if nargin < 5
    s       = 0;
    e       = 2*pi;
    toRound = 0;
end

th   = linspace(s, e, z);
xcrd = r * cos(th) + x;
ycrd = r * sin(th) + y;

if toRound
    crc  = round([xcrd ; ycrd]');
else
    crc = [xcrd ; ycrd]';
end

end
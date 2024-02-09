function [dom , domSize , domShape] = generateDomains(dDsk, dSqr, dVrt, dHrz, myShps)
%% generateDomains: create domain for a disk, square, vertical/horizontal line
% This function generates domains for generating a disk (d), square (s),
% vertical line (v) and a horizontal line (h). These domains can be used with an
% image to map the domain coordinates onto that image using ba_interp2 or a
% similar interpolation function.
%
% Usage:
%   [dom , domSize] = generateDomains(dSize, sSize, vSize, hSize)
%
% Input:
%   dDsk: size to create a disk domain [d , d]
%   dSqr: size to create a sqare domain [s , s]
%   dVrt: size to create a vertical line domain [r , c]
%   dHrz: size to create a horizontal line domain [c , r]
%   myShps: domains to select
%
% Output:
%   dom: cell array of all domains
%   domSize: cell array of sizes used for the domains
%   domShape: shapes of domains (for printing)

if nargin < 1; dDsk   = [30  ,  30]; end
if nargin < 2; dSqr   = [30  ,  30]; end
if nargin < 3; dVrt   = [100 ,   3]; end
if nargin < 4; dHrz   = [3   , 100]; end
if nargin < 5; myShps = [];          end

%% Set domain properties
% Disk
[rho , theta] = ndgrid(linspace(0, 1, dDsk(1)), linspace(-pi, pi, dDsk(2)));
d1            = rho .* cos(theta);
d2            = rho .* sin(theta);
cDsk          = [d1(:) , d2(:) , ones(size(d1(:)))];

% Square
[s1 , s2] = ndgrid(linspace(-1, 1, dSqr(1)), linspace(-1, 1, dSqr(2)));
cSqr      = [s1(:) , s2(:) , ones(size(s1(:)))];

% Vertical Line
vmag      = 0.1;
[v2 , v1] = ndgrid(linspace(-1, 1, dVrt(1)), linspace(-vmag, vmag, dVrt(2)));
cVrt      = [v1(:) , v2(:) , ones(size(v1(:)))];

% Horizontal Line
hmag      = 0.1;
[h2 , h1] = ndgrid(linspace(-hmag, hmag, dHrz(1)), linspace(-1, 1, dHrz(2)));
cHrz      = [h1(:) , h2(:) , ones(size(h1(:)))];

%% Store everything in a cell array
dom      = {cDsk   , cSqr     , cVrt    , cHrz};
domSize  = {dDsk   , dSqr     , dVrt    , dHrz};
domShape = {'disk' , 'square' , 'vline' , 'hline'};

%% Remove indices
if ~isempty(myShps)
    dom      = dom(myShps);
    domSize  = domSize(myShps);
    domShape = domShape(myShps);
end
end
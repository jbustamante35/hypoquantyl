function [dom , domSize] = generateDomains(dSize, sSize, vSize, hSize, toRemove)
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
%   dSize: size to create a disk domain [d , d]
%   sSize: size to create a sqare domain [s , s]
%   vSize: size to create a vertical line domain [r , c]
%   hSize: size to create a horizontal line domain [c , r]
%
% Output:
%   dom: cell array of all domains
%   domSize: cell array of sizes used for the domains

%%
% Disk
[rho , theta] = ndgrid(linspace(0, 1, dSize(1)), linspace(-pi, pi, dSize(2)));
d1            = rho .* cos(theta);
d2            = rho .* sin(theta);
dsk           = [d1(:) , d2(:) , ones(size(d1(:)))];

% Square
[s1, s2] = ndgrid(linspace(-1, 1, sSize(1)), linspace(-1, 1, sSize(2)));
sqr      = [s1(:) , s2(:) , ones(size(s1(:)))];

% Vertical Line
vmag     = 0.1;
[v2, v1] = ndgrid(linspace(-vmag, vmag, vSize(1)), linspace(-1, 1, vSize(2)));
vline    = [v1(:) , v2(:) , ones(size(v1(:)))];

% Horizontal Line
hmag     = 0.1;
[h2, h1] = ndgrid(linspace(-1, 1, hSize(1)), linspace(-hmag, hmag, hSize(2)));
hline    = [h1(:) , h2(:) , ones(size(h1(:)))];

%% Store everything in a cell array
dom     = {dsk ,  sqr , vline , hline};
domSize = {dSize, sSize, vSize, hSize};

%% Remove indices
if ~isempty(toRemove)
    dom(toRemove)     = [];
    domSize(toRemove) = [];
end

end
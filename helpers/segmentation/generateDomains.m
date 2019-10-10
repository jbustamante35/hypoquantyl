function [dom , domSize] = generateDomains(dSize, sSize, vSize, hSize)
%% generateDomains: create domain for a disk d and square s
%
%
% Usage:
%   [dsk , sqr] = generateDomains(dSize, sSize)
%
% Input:
%   dSize: size to create a disk domain [d , d]
%   sSize: size to create a sqare domain [s , s]
%
% Output:
%   dsk: domain of size dSize of a disk
%   sqr: domain of size sSize of a square

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
vmag     = 10;
[v2, v1] = ndgrid(linspace(-1/vmag, 1/vmag, vSize(1)), linspace(-1, 1, vSize(2)));
vline    = [v1(:) , v2(:) , ones(size(v1(:)))];

% Horizontal Line
hmag     = 10;
[h2, h1] = ndgrid(linspace(-1, 1, hSize(1)), linspace(-1/hmag, 1/hmag, hSize(2)));
hline    = [h1(:) , h2(:) , ones(size(h1(:)))];

%% Store everything in a cell array
dom     = {dsk ,  sqr , vline , hline};
domSize = {dSize, sSize, vSize, hSize};

end
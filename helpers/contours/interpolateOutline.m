function oL = interpolateOutline(crds, sz)
%% interpolateOutline: interpolate a set of coordinates to desired length
% This function takes a set of coordinates, determines cumulative sum of all the
% arc lengths between each coordinate, then interpolates along each axis to the
% number of coordinates defined by the sz parameter.
%
% Usage:
%   oL = interpolateOutline(crds, sz)
%
% Input:
%   crds: original set of coordinates to interpolate
%   sz: length for interpolated set of coordinates
%
% Output:
%   oL: new set of coordinates of desired length
%

%% Arc lengths of countour (distances between points)
d  = diff(crds, 1, 1);
dL = sum(d .* d, 2) .^ 0.5;

%% Interpolate distances to an equalized number of coordinates
L  = cumsum([0 ; dL]);
oq = linspace(L(1), L(end), sz);
oL = interp1(L, crds, oq);
end


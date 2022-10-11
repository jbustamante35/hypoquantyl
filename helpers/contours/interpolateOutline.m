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

% Convert 1-D coordinates to 2-D
rchk = size(crds) == 1;
dchk = find(rchk == 1);
if any(rchk)
    % Convert from rows to columns
    if dchk; crds = crds'; end
    crds = [(1 : numel(crds))' , crds];
end

%% Arc lengths of countour (distances between points)
d  = diff(crds, 1, 1);
dL = sum(d .* d, 2) .^ 0.5;

% Interpolate distances to an equalized number of coordinates
L  = cumsum([0 ; dL]);
oq = linspace(L(1), L(end), sz);
oL = interp1(L, crds, oq);

% Convert back to 1-D coordinates
if any(rchk)
    oL = oL(:,2);
    if dchk; oL = oL'; end
end
end

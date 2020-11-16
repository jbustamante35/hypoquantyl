function [src , excrd] = extendCurve(src, trg, ang, maxscl, npts, rot)
%% extendCurve: extend curve along angle to reach target curve
% Description
%
% Usage:
%   [src , excrd] = extendCurve(src, trg, ang, maxscl, npts)
%
% Input:
%   src: source curve
%   trg: target curve to reach
%   ang: angle vector to extend towards
%   maxscl: maximum scalar to attempt extension (default 100)
%   npts: number of points to interpolate extended midline (default 100)
%   rot: angle to rotate for additional extension (default -30)
%
% Output:
%   src: source curve extended to target curve
%   excrd: coordinate where source was extended from
%
% Author Julian Bustamante <jbustamante@wisc.edu>
%

%% Set default parameters
switch nargin
    case 3
        maxscl = 100;
        npts   = 100;
        rot    = -30;
    case 4
        npts = 100;
        rot  = -30;
    case 5
        rot = -30;
end

%% Extend end of midline from angle
% Get extension point and compute 45-degree angle
excrd = src(end,:);
angl  = ang;
angr  = Rmat(rot) * angl;

% Extend along angle to contour and append to the input curve
extl = extend2contour(excrd, trg, angl, maxscl, npts);
extr = extend2contour(excrd, trg, angr, maxscl, npts);
ext  = [extl ; extr];
src  = [src ; ext];

end

function ext = extend2contour(excrd, trg, ang, maxscl, npts)
%% extend2target:
% Extend and check if out of bounds
EXT = arrayfun(@(scl) excrd + (ang' * scl), 1 : maxscl, 'UniformOutput', 0);
EXT = EXT(cell2mat(cellfun(@(ext) inpolygon(ext(1), ext(2), trg(:,1), trg(:,2)), ...
    EXT, 'UniformOutput', 0)));

% Snap max extension to target curve and interpolateinterpolate
ext = snap2curve(EXT{end}, trg);
ext = interpolateOutline([excrd ; ext], npts + 1);

end

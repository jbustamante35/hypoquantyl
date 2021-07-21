function [mid , tng , nrm] = plottableZVector(z, scl, rtyp, dpos)
%% plottableZVector: make Z-Vector plottable
% Description
%
% Usage:
%   [mid , tng , nrm] = plottableZVector(z, scl, rtyp, dpos)
%
% Input:
%   z:
%   scl:
%   rtyp:
%   dpos:
%
% Output:
%   mid:
%   tng:
%   nrm:
%

%% Returns midpoints and scales tangents and normals
if nargin < 2
    scl  = 8;
    rtyp = 'rad';
    dpos = 1;
end

nsegs = size(z, 1);
if size(z, 1) == 3
    z = zVectorConversion(z, nsegs, 1, 'rot', rtyp, dpos);
end

mid = z(:,1:2);
tng = (scl * z(:,3:4)) + mid;
nrm = (scl * z(:,5:6)) + mid;

tng = arrayfun(@(x) [mid(x,:) ; tng(x,:)], 1 : nsegs, 'UniformOutput', 0)';
nrm = arrayfun(@(x) [mid(x,:) ; nrm(x,:)], 1 : nsegs, 'UniformOutput', 0)';

end

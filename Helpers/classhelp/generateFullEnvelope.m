function crvs = generateFullEnvelope(crds, envDist, numCurves)
%% generateFullEnvelope: generate all intermediate curves between original segment and envelope
% This function generates all intermediate segments between the original segment and the
% fully-extended envelope. Each iterative curve is defined by the max distance and the desired
% number of curves between the original segment and envelope extent.
%
% Usage:
%   crvs = generateFullEnvelope(crds, envDist, itr)
%
% Input:
%   crds: x-/y-coordinates of inputted segment
%   envDist: maximum distance from segment to envelope
%   numCurves: number of desired curves between segment and envelope
%
% Output:
%   crvs: cell array of all intermediate curves between original segment and envelope
%

itr  = envDist / numCurves;
crvs = arrayfun(@(x) crds + (itr * x), 1 : numCurves, 'UniformOutput', 0);

end
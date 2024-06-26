function [crvs, strc] = generateFullEnvelope(crds, dist2env, numCrvs, alg)
%% generateFullEnvelope: generate all curves from segment throught envelope
% This function generates all the intermediate segments between the original
% segment from crds to the fully-extended envelope, whose distance is defined by
% the dist2env parameter. Curves are iteratively placed equidistant along this
% vector until the desired number of curves in the envelope is reached.
%
% Usage:
%   crvs = generateFullEnvelope(crds, dist2env, numCrvs, mth)
%
% Input:
%   crds: x-/y-coordinates of inputted segment
%   dist2env: maximum distance from to envelope, or vector of outer enveope
%   numCrvs: number of desired curves between segment and envelope
%   alg: algorithm to run ('hq' for HypoQuantyl, 'cs' for CarrotSweeper)
%
% Output:
%   crvs: intermediate curves between segment and envelope
%   strc: envelope structure reshaped as an image
%

if nargin < 4; alg = 'hq'; end

switch alg
    case 'hq'
        %% HypoQuantyl Method
        % Just go to specified distance (need to be updated to go along normal)
        itr  = dist2env / numCrvs;
        crvs = arrayfun(@(x) crds + (itr * x), 1 : numCrvs, 'UniformOutput', 0);
        strc = [];
        
    case 'cs'
        %% CarrotSweeper Method
        % Make intermediate segments between two curves
        pts  = arrayfun(@(x) ...
            interpolateOutline([crds(x,:) ; dist2env(x,:)], numCrvs), ...
            1 : length(crds), 'UniformOutput', 0);
        crvs = cat(1, pts{:});
%         strc = cat(2, pts{:});
        sx   = cellfun(@(x) x(:,1), pts, 'UniformOutput', 0);
        sy   = cellfun(@(x) x(:,2), pts, 'UniformOutput', 0);
        strc = [cat(2, sx{:}) , cat(2, sy{:})];
        
        
    otherwise
        % Error
        fprintf(2, 'Please select appropriate algorithm [hq|cs]\n');
        crvs = [];
end
end
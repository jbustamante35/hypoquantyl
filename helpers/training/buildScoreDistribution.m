function [DOUT , SCRS , xi , yi , vi] = buildScoreDistribution(SCRS, BIN, MAG, sav, vis)
%% buildTipDistribution: initialize model to optimize tip-finding algorithm
%
%
% Usage:
%   [DOUT, SCRS, xi, yi, vi] = buildScoreDistribution(SCRS, BIN, MAG, sav, vis)
%
% Input:
%   SCRS: cell array of contours to train initial distribution
%   BIN:
%   MAG:
%   sav:
%   vis:
%
% Output:
%   DOUT: structure containing additional outputs to save in a .mat file
%   SCRS: sorted array of all curvatures from training set of contours
%   xi: bin designations
%   yi: counts from probability density function
%   vi: -logs of sums of probabilities

try
    %% Set left-right limits to capture main distribution around mean
    LMAX       = MAG * std(SCRS) + median(SCRS);
    [~ , LMAX] = min(abs(LMAX - SCRS));

    LMIN       = -MAG * std(SCRS) + median(SCRS);
    [~ , LMIN] = min(abs(LMIN - SCRS));

    fprintf('ida: %d | idb: %d | mag: %.06f \n', LMIN , LMAX, MAG);

    %% Generate curvature probability distribution
    [yi, xi] = hist(SCRS, linspace(SCRS(LMIN), SCRS(LMAX), BIN));
    yi(1)    = [];
    yi(end)  = [];
    xi(1)    = [];
    xi(end)  = [];

    % Sum of -logs of curvature probabilities
    yi = yi / sum(yi);
    vi = -log(yi);

    %% Store output in a structure and save
    Ncar = numel(SCRS);
    Ncrv = length(SCRS);
    DOUT = v2struct(Ncar, Ncrv, SCRS, xi, yi, vi, LMAX, LMIN);
    if sav
        nm = sprintf('%s_CurveDistribution_%dObjects_%dCurves', ...
            tdate('s'), Ncar, Ncrv);
        save(nm, '-v7.3', 'DOUT');
    end

    if vis
        plt([xi ; vi]', 'k-', 1);
        ttl = sprintf('Curvature Distribution -log(P(k))\n%d Carrots %d Curves', ...
            Ncar, Ncrv);
        title(ttl);
    end

catch e
    % Incorrect input
    fprintf('Error building model\n%s\n', e.getReport);
    [DOUT, SCRS, xi, yi, vi] = deal([]);
end

end

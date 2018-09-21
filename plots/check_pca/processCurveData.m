function [X, Y] = processCurveData(C, typ)
%% processCurveData: rasterizes segments from Curve objects in CircuitJB array
% Input:
%
%
% Output:
%
%

[X, Y] = arrayfun(@(x) x.rasterizeCurves(typ), C, 'UniformOutput', 0);
X      = cat(1, X{:});
Y      = cat(1, Y{:});

end
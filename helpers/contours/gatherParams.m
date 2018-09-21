function [Pm, Pp] = gatherParams(C)
%% gatherParams: combine Pmat and Ppar from all Routes of CircuitJB array into single matrix
% 
%
% Usage:
%   [Pm, Pp] = gatherParams(C)
%
% Input:
%   C: object array of CircuitJB objects
%
% Output:
%   Pm: [3 x 3 x n x r] matrix of Pmat data from all r Routes of all n CircuitJB objects
%   Pp: [1 x 3 x n x r] matrix of Ppar data from all r Routes of all n CircuitJB objects
%

%% Concat all Routes in CircuitJB array
P = arrayfun(@(x) x.getRoute, C, 'UniformOutput', 0);
P = cat(1, P{:});

%% Collect all Pmat data
Pm = arrayfun(@(x) x.getPmat, P, 'UniformOutput', 0);
Pm = cat(3, Pm{:});
Pm = reshape(Pm, 3, 3, numel(C), numel(C.getRoute));
Pm = permute(Pm, [1 2 3 4]);

%% Collect all Ppar data
Pp = arrayfun(@(x) x.getPpar, P, 'UniformOutput', 0);
Pp = cat(3, Pp{:});
Pp = reshape(Pp, 1, 3, numel(C), numel(C.getRoute));
Pp = permute(Pp, [1 2 3 4]);

end
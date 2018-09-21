function [D, X, Y] = multiPCAprep(C)
%% multiPCAprep: split data for PCA of multiple segments
% This function takes the full training set of CircuitJB objects to extract the raw data used for
% PCA of the multiple Route objects between anchor points.
%
% Usage:
%   D = multiPCAprep(C)
%
% Input:
%   C: object array of CircuitJB objects to run PCA
%
% Output:
%   D: {2 x 1} cell array of split x-/y-coordinates
%   X: [m x n x r] array of x-coordinates for  m contours of n length split by r Routes
%   Y: [m x n x r] array of x-coordinates for  m contours of n length split by r Routes

%% Linearize all Routes
[X, Y] = arrayfun(@(x) x.LinearizeRoutes, C, 'UniformOutput', 0);

%% Store x-/y-coordinates into [m x n x r] matrices
X = cat(2, X{:});
Y = cat(2, Y{:});
X = permute(X, [2 1 3]);
Y = permute(Y, [2 1 3]);

%% Split X and Y into cells of D
D = {X ; Y};
end
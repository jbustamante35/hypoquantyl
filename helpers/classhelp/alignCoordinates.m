function I = alignCoordinates(X, dim)
%% alignCoordinates: return array of matching coordinate index
% This function takes [n x m x t] matrix X, where each row represents a set of coordinates of a
% given point through a stack of size t (coordinates through time-lapse). This function iterates
% through each t and finds the closest matching coordinate between slices of t. It then returns a
% vector of indices for each n. Dimension to sort along is defined by dim.
%
% Usage:
%   I = alignCoordinates(X, dim)
%
% Input:
%   X: [n x m x t] matrix of coordinates
%   dim: m dimension to sort along
%
% Ouput:
%   I: [n x t] matrix of indices defining the closest coordinates through all slices of t
%

idx = zeros(size(X,1), size(X,3));
for i = 2 : size(X,3)
    idx(:,i) = compareCoords(X(:,:,i-1), X(:,:,i), dim);
end
[~, I] = sort(idx);
end
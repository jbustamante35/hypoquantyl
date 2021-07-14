function I = alignCoordinates(X)
%% alignCoordinates: return array of matching coordinate index
% This function takes an [n x m x t] matrix X, where each [n x m] row represents
% a set of coordinates through a stack of size t (e.g. an array of
% x-/y-coordinates through a time-lapse). This function iterates through each
% slice t and finds the closest matching coordinates in the subsequent slice.
%
% An [n x 1] vector of indices at each slice t is then returned, which
% corresponds to the coordinates that match for each n. Dimension to sort along
% is defined by the dim parameter.
%
% NOTE:
%   Indexing in for loop starts at 2 so that the previous frame is frame 1. The
%   alternative would be to start the loop at 1 and have it end at
%   size(X,3) - 1, which would be comparing current and next, rather than
%   previous and current. Slight differences but same outcome.
%
% Usage:
%   I = alignCoordinates(X, dim)
%
% Input:
%   X: [n x m x t] matrix of coordinates
%
% Ouput:
%   I: [n x t] indices defining the closest coordinates through all t slices
%

xi  = X(:,:,1);
idx = zeros(size(X,1), size(X,3));
for i = 1 : size(X,3)
    if i == 1
        idx(:,i) = compareCoords(xi, X(:,:,i));
    else
        idx(:,i) = compareCoords(X(:,:,i-1), X(:,:,i));
    end
end
[~, I] = sort(idx);
end


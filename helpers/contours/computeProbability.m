function p = computeProbability(P, I, x, y, l, t)
%% computeProbability: compute probability at point (x,y) using length (l) angle (t) of Image (I)
% This function refers to probability matrix P to check coordinate [x, y] for the probability of
% being part of the average contour with designated length l and theta angle t. Probability is
% determined by pixels of inputted image I.
%
% Usage:
%   p = computeProbability(P, I, x, y, l, t)
%
% Input:
%   P: [m x n] probability matrix
%   I: [m x n] image of hypocotyl
%   x: x-coordinate to compute probability
%   y: y-coordinate to compute probability
%   l: length of segment to construct
%   t: theta angle of segment to define new reference vector
%
% Output:
%   p: probability from coordinates [x,y] and length l and theta angle t
%

D = setEndPoints([x y]);
X = getCoordinateSet(D, l, size(I));
S = sumProbabilities(P, X);
p = mean(S);

end

function D = setEndPoints(X)
%% setEndPoints: subfunction to set randomly-selected start and end points from given midpoints
pos          = [X 15 15];
c            = imellipse(gca, pos);
msk          = c.createMask;
[rows, cols] = ind2sub(size(msk), find(msk == 1));
X            = [cols, rows];
D            = X(randi([1 length(X)], 2, 1), :);
end

function X = getCoordinateSet(D, L, S)
%% getCoordinateSet: subfunction to retrieve a set of L coordinates within image of size sz
X = random_path(D(1,:), D(end,:), S);
end

function path = random_path(start, goal, board_size)
%%
m = board_size(1);
n = board_size(2);
isInBounds = @(x) x(1) >= 1 && x(1) <= m && x(2) >= 1 && x(2) <= n;

neighbor_offset = [ 0, -1; % Neighbor indices:
    -1,  0;                 %        2
    0,  1;                 %    1   x   3
    1,  0];                %        4

% Edit: get the actual size of our neighbor list
[possible_moves, ~] = size(neighbor_offset);

current_position = start;
path = current_position;

while sum(current_position ~= goal) > 0
    valid = false;
    while ~valid
        % Edit: "magic numbers" are bad; fixed below
        %           move = randi(4);
        move = randi(possible_moves);
        candidate = current_position + neighbor_offset(move, :);
        valid = isInBounds(candidate);
    end
    current_position = candidate;
    path = [path; current_position];
end
end

function S = sumProbabilities(P, X)
%% sumProbabilities: subfunction to sum the probabilies of coordinates X from probability matrix P

S = P(X);
S = sum(S);

end
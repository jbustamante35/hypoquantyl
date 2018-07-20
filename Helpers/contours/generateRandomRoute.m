function RTS = generateRandomRoute(I, V, minR, maxR, maxD, maxA)
%% generateRandomeRoute: select random midpoint and radius to generate synthetic Route
% This function uses a probability matrix and selects and adequate coordinate to serve as a
% synthetic midpoint for a Route (segment of a CircuitJB contour). The length of the Route is
% randomly determined by a radius that is ensured to be inside the inputted image. This radius is
% used to determine the distances of the start and end anchorpoints to the midpoint.
%
% The angle of the new reference frame is randomly determined by selecting an adequate start and end
% anchorpoint at the radius distance from the midpoint. A rotation matrix pivots around the midpoint
% to define 360 points around that midpoint. A start anchorpoint is randomly selected from those 360
% points, and the end anchorpoint is the diagonal coordinate from the start anchorpoint.
%
% To generate the Route's Trace (coordinates defining the contour segment), this algorithm uses the
% eigenvector from principal components analysis data.
%
% Usage:
%   RTS = generateRandomRoute(I, V, minR, maxR, maxD, maxA)
%
% Input:
%   I: [n x n] probability matrix
%   V: [N x m] eigenvector containing m PCs for all N training data
%   minR: minimum radius size to define distance from midpoint to each anchorpoint
%   maxR: maximum radius size to define distance from midpoint to each anchorpoint
%   maxD: maximum decrementer to decrease radius size if too large for image
%   maxA: maximum number of attempts to search for an adequate midpoint before quitting
%
% Output:
%   RTS: output structure containing values used to generate synthetic Route
%

%% Function Handles
plt  = @(x,y,z) plot(x(:,1), x(:,2), y, 'MarkerSize', z);
m    = @(x) randi([1 length(x)], 1);
Rmat = @(t) [[cos(t) ; -sin(t)], ...
    [sin(t) ; cos(t)]];
Rrot = @(r,p,m) bsxfun(@(x,y) (r * x), [p(1) .'-m(1); p(2) .'-m(2)], false(1, length(p(1))));

disp(V);
fprintf('Att|Dec|Rad|Tmp|Crds\n');

%% Select random coordinate and random radius size
rRad = randi([minR maxR], 1);
rCrd = randi([1 size(I,2)], 1, 2);

%% Set search parameters for adequate midpoint
% An adequate midpoint will not have it's radius extend outside of image
anchorChk = true;
dec       = 1;   % radius decrementer
att       = 1;   % attempt counter
tmp       = rRad;   % modifiable radius

% Find adequate coordinate for midpoint
while anchorChk
    % Check if radius chosen will be outside of image
    if sum((rCrd + tmp) >= size(I)) >= 1 || sum((rCrd - tmp) < 0) >= 1
        if dec <= maxD && (rRad - dec) >= minR
            % Decrement radius by max of 10
            % Don't decrement if final radius r will be < 5
            tmp = tmp - 1;
            dec = dec + 1;
        elseif dec > maxD || (rRad - dec) <= minR
            % Pick new midpoint and reset radius
            rCrd = randi([1 size(I,2)], 1, 2);
            tmp  = rRad;
            dec  = 1;
        end
    else
        % Check validated
        anchorChk = false;
        rRad      = rRad - dec;
    end
    
    % Stop if too many attempts to find good spot
    if att >= maxA
        fprintf(2, 'Too many tries (%d)', att);
        return;
    else
        att = att + 1;
    end
end

% Final parameters
fprintf('%d | %d | %d | %d | (%d,%d)\n', att, dec, rRad, tmp, rCrd);

%% Find adequate starting and ending coordinates
pointChk = true;

% All points around midpoint at radius distance
M = rCrd;
P = floor([M(1) + (rRad / 2), M(2)]);
R = arrayfun(@(x) Rmat(x), 1:360, 'UniformOutput', 0);
T = cellfun(@(r) Rrot(r, P, M)', R, 'UniformOutput', 0);
T = floor(cat(1, T{:}) + M);

while pointChk
    % Determine all coordinates at radius distance inside image
    G = T(~sum(T > length(I),2),:);
    
    % Choose random valid starting coordinate
    S   = G(m(G),:);
    
    % Check if diagonal coordinate is valid
    E   = M - (S - M);
    
    % Plot S->M->E
    S2M = [S ; M];
    M2E = [M ; E];
    
    pointChk = false;
end

%% Output final structure and plot data onto image
plt(rCrd, 'ro', 8);
m2e = line(M2E(:,1), M2E(:,2), 'Color', 'm');
s2m = line(S2M(:,1), S2M(:,2), 'Color', 'g');
RTS = v2struct(rRad, rCrd, M, E, S, M2E, m2e, S2M, s2m);
end

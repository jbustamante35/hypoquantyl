function M = findMidpoint(S, E)
%% getMidpoint: find midpoint coordinate between points S and E
% This function returns the midpoint between two coordinates. This
% function is primarily used for the midpointNorm() function.
%
% Usage:
%   M = findMidpoint(S, E)
%
% Input:
%   S: coordinate at start of curve
%   E: coordinate at end of curve
%
% Output:
%   M: coordinate between start and ending curve

M = S + 0.5 * (E - S);
end
function fig = lineInts(A, B, stp, col)
%% lineInts: plot two lines with lines in various intervals
% This function takes two lines of the same length and generates lines between corresponding points
% at intervals provided by the user.
%
% Usage:
%   fig = lineInts(A, B, stp, col)
%
% Input:
%   A: x-/y-coordinates for first line
%   B: x-/y-coordinates for second line
%   stp: interval to place lines between segments
%   col: color of the lines
%
% Output:
%   fig: resulting figure handle
%

itr = round(1 : (length(A) - 1) / stp : length(A));
fig = arrayfun(@(x) makeLine(A(x,:), B(x,:), col), itr, 'UniformOutput', 0);

end

function lnF = makeLine(crdA, crdB, col)
%% makeLine: subfunction to generate line through two points

lnL = [crdA ; crdB];
lnF = line(lnL(:,1), lnL(:,2), 'Color', col);

end
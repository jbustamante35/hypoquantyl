function Ppar = computePpar(ox, rx)
%% computePpar: compute theta angle from given input vectors 
% This function takes the x-coordinates of the two input vectors 
%
% Usage:
%   Ppar = computePpar(dx, dy)
% 
% Input:
%   dx: x-coordinate from original basis vector
%   dy: x-coordinate from new reference vector
% 
% Output: 
%   Ppar: theta angle of vector from default basis vector
% 

Ppar = atan2(ox, rx);

end
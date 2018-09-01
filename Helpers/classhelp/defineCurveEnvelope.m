function [envOut, envInn, dstOut, dstInn] = defineCurveEnvelope(crds, scl)
%% defineCurveEnvelope: generate the envelope boundaries around a curve segment
% This function takes the x-/y-coordinates of a curve segment and defines the extent of it's
% envelope structure (that is, the furthest extent in which the probability-based search algorithm
% determine where to set the segment of a contour).
%
% Usage:
%   [envOut, envInn, dstOut, dstInn] = defineCurveEnvelope(crds)
%
% Input:
%   crds: curve segment in midpoint-normalized x-/y-coordinates
%   scl: length to scale unit length vector to increase/decrease max envelope distance
%
% Output:
%   dstOut: unit length vector defining the distance from curve to outer envelope
%   dstInn: unit length vector defining the distance from curve to inner envelope
%   envOut: coordinates of outer envelope
%   envInn: coordinates of inner envelope
%

%% Compute unit length vector distances around curve
tng_line = gradient(crds')';
dst2env  = sum((tng_line .* tng_line), 2).^(-0.5);
unit_len = bsxfun(@times, tng_line, dst2env) * scl;

%% Convert vector distances to reflect direction of envelope
dstOut = [-getDim(unit_len,2) getDim(unit_len,1)];
dstInn = [getDim(unit_len,2) -getDim(unit_len,1)];

%% Compute envelope coordinates around inputted curve
envOut = crds + dstOut;
envInn = crds + dstInn;

end
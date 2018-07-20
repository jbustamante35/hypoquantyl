function I = norm2interp(varargin)
%% norm2interp: convert NormTrace to InterpTrace
% This function converts normalized outlines used for PCA back to the interpolated
% outlines whose coordinates align with the drawn contour. This should be used for
% verifying the normalization method of converting raw to normalized outlines.
%
% Calculation: I = ((n x d) + b) + m
%   1) Multiply normalized coordinate by mean-subtracted, zero-set destination anchorpoint
%   2) Add back mean-subtracted beginning anchorpoint
%   3) Add back the mean coordinate of the original curve 
% 
% Usage:
%   I = norm2interp(n, m, b, d)
%       or
%   I = norm2interp(c)
%
% Input:
%   n: x-/y-coordinates of normalized trace
%   m: mean x-/y-coordinate of curve
%   b: starting anchorpoint after mean subtraction ('b2')
%   d: ending anchorpoint after mean subtraction and setting to 0 ('d2')
%   c: input can simply be the Route object of a single contour
%
% Output:
%   I: coordinates of Interpolated Outline
%

%% Extract values if only single Route inputted
if nargin == 1
    x = varargin{1};    
    n = x.getTrace(1);
    m = x.getMean;
    b = x.getAnchors(1, 'b2');
    d = x.getAnchors(1, 'd2');
else
    n = varargin{1};
    m = varargin{2};
    b = varargin{3};
    d = varargin{4};
end

I = ((n .* d) + b) + m;

end

% function I = norm2interp(n, m, b, d)
function I = norm2interp(varargin)
%% Convert NormTrace to InterpTrace
% This function converts normalized outlines used for PCA back to the interpolated
% outlines whose coordinates align with the drawn contour. This should be used for
% verifying the normalization method.
%
% Usage:
%   I = norm2interp(n, m, b, d)
%
% Input:
%   n: normalized trace
%   m: mean coordinate of curve
%   b: starting anchorpoint after mean subtraction
%   d: ending anchorpoint after mean subtraction and setting to 0
%
% Output:
%   I: coordinates of Interpolated Outline

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
function [c , ceq] = nonlconFlf(x, th)
%% non-linear constraint function for fitting flf
% c = ...     % Compute nonlinear inequalities at x.
% ceq = ...   % Compute nonlinear equalities at x.

if nargin < 2; th  = 0.1; end

y   = flf(0,x);
c   = y - th;
ceq = [];
end
function xinn = fitFLF(xinn, params, vrb, nlc, lb, ub, tol, itrs)
%% fitFLF: find best fit for flf parameters using positions
%
% Usage:
%   xinn = fitFLF(xinn, params, vrb, nonlcon, lb, ub, tol)
%
% Input:
%   xinn: arclengths
%   params: flf parameters ([vmax , k , x0 , n])
%   vrb: verbosity for paternsearch (none|iter) [default 'none']
%   nlc: use non-linear constraint [default 0]
%   lb: lower bound for parameters
%   ub: upper bound for parameters
%   tol: termination tolerance for function and X [tolf , tolx]

if nargin < 3; vrb  = 0;                          end
if nargin < 4; nlc  = 0;                          end
if nargin < 5; lb   = [0 , 0    , -100   , 0];     end
if nargin < 6; ub   = [6 , 0.04 , 300    , 0.10]; end
if nargin < 7; tol  = [1e-12 , 1e-12];            end
if nargin < 8; itrs = 1000;                       end

if vrb; vrb     = 'iter';            else; vrb     = 'none'; end
if nlc; nonlcon = @(x)nonlconFlf(x); else; nonlcon = [];     end

%%
delta   = @(x,y) -sum(log(normpdf(x - y, 0, 1)));
options = optimset('Display', vrb, 'TolFun', tol(1), 'TolX', tol(2), ...
    'MaxIter', itrs);

%
for e = 1 : numel(xinn)
    X = xinn(e).X;
    Y = xinn(e).V;

    %
    xinn(e).kiniPara = patternsearch(@(w) delta(flf(X(:), w), Y(:)), params, ...
        [], [], [], [], lb, ub, nonlcon, options);
    %     xinn(e).kiniPara = fminsearch(@(w) ...
    %         delta(flf(X(:), w), Y(:)), params, options);
end
end
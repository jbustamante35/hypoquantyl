function D = getDim(X, n)
%% getDim: returns n-dimension of multi-dimensional data
% This function is basically just a shortcut for concatenating a cell array and returning the
% desired dimension. It can also be used for a multi-dimensional data matrix
%
% This basically only works for 2D data right now.
%
% Usage:
%   D = getDim(X, n)
%
% Input:
%   X: input data as cell array or matrix
%   n: desired dimension of data to return
%
% Output:
%   D: data from desired dimension defined by n
%

try
    if iscell(X)
        X = reshape(cat(1, X{:}), size(X));
        D = X(:,n);
    else
        D = X(:,n);
    end
catch
    fprint(2, 'Input should either be cell array or data matrix\n');
end

end
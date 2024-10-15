function Z = im2colF(F, X, mth)
%% im2colF: rearrange image blocks into columns
if nargin < 3; mth = 'sliding'; end

try
    % Try compiled version
    Z = im2colF_c(F, X, mth);
catch
    % Default to matlab's im2col
    % fprintf('%s not compiled, defaulting to im2col\n', mfilename);
    % Z = im2col(F, X, 'distinct');
    Z = im2col(F, X, 'sliding');
end
end

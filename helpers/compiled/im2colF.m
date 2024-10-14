function Z = im2colF(F, X, mth)
%% im2colF: rearrange image blocks into columns
if nargin < 3; mth = 'sliding'; end

try
    % Try compiled version
    Z = im2colF_c(F, X);
catch
    % Default to matlab's im2col
    fprintf(2, 'im2colF not compiled, defaulting to im2col\n');
    % Z = im2col(F, X, 'distinct');
    Z = im2col(F, X, mth);
end
end

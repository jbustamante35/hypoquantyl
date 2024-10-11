function Z = im2colF(F, X, Y)
%% im2colF: rearrange image blocks into columns

try
    % Try compiled version
    Z = im2colF_c(F, X, Y);
catch
    % Default to matlab's im2col
    % Z = im2col(F, X, 'distinct');
    Z = im2col(F, X, 'sliding');
end
end

function smth = segSmooth(seg, span, method)
%% segSmooth: Smooth curve of given type defined by req parameter
% Curve is smoothed by moving average span from SMOOTHSPAN constant
try
    seg_in = seg(2:(end-1), :);
    y_out  = smooth(seg_in(:,1), seg_in(:,2), span, method);
    yf     = [seg_in(1,2) ; y_out ; seg_in(end,2)];
    smth   = [seg(:,1) yf];
catch
    fprintf(2, 'Error smoothing segment\n');
    smth = [];
ends

end
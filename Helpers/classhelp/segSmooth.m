function smth = segSmooth(seg, span)
%% segSmooth: Smooth curve of given type defined by req parameter
% Curve is smoothed by moving average span from SMOOTHSPAN constant
try
    smth = reshape(smooth(seg, span), size(seg));
catch
    fprintf(2, 'Error smoothing segment\n');
end

end
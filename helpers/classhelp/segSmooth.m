function smth = segSmooth(seg, span, method)
%% segSmooth: Smooth curve of given type defined by req parameter
% Curve is smoothed by moving average span from SMOOTHSPAN constant
try
    y    = smooth(seg(:,1), seg(:,2), span, method);
    smth = [seg(:,1) y];
catch
    fprintf(2, 'Error smoothing segment\n');
end

end
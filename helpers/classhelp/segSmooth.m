function smth = segSmooth(seg, span, smth, alg)
%% segSmooth: Smooth curve of given type defined by req parameter
% Curve is smoothed by moving average span from SMOOTHSPAN constant
% [NOTE] I made this to keep the end points locked, and assumed it is a closed
% curve. Use algorithm 'gen' for general curves.
%
% Usage:
%   smth = segSmooth(seg, span, smth, mth)
%
% Input:
%   seg: curve coordaintes (input as [Y , X] or [rows , cols]
%   span: smoothing percentage [default 0.5]
%   smth: smoothing method [default 'sgolay']
%   alg: algorithm ('elock' to lock ends, 'gen' for general curves) [default
%   'elock']
if nargin < 2; span = 0.5;      end
if nargin < 3; smth = 'sgolay'; end
if nargin < 4; alg  = 'gen';    end

try
    switch alg
        case 'elock'
            seg_in = seg(2:(end-1), :);
            y_out  = smooth(seg_in(:,1), seg_in(:,2), span, smth);
            yf     = [seg_in(1,2) ; y_out ; seg_in(end,2)];
            smth   = [seg(:,1) , yf];
        case 'gen'
            x_out = smooth(seg(:,2), span, smth);
            y_out = smooth(seg(:,1), span, smth);
            smth  = [y_out , x_out];
    end
catch
    fprintf(2, 'Error smoothing segment\n');
    smth = [];
end
end
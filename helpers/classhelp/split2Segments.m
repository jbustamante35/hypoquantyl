function segs = split2Segments(trc, len, step, mth)
%% split2Segments: split contour into pieces of len size around the segment
% This function takes a set of coordinates (typically defining a full contour)
% and splits it into many segments of len size. These segments iteratively slide
% around the contour, with the step size to skip between lengths defined by the
% step parameter.
%
% Usage:
%   segs = split2Segments(trc, len, step)
%
% Input:
%   trc: full contour as a set of x-/y-coordinates
%   len: length to split each segment around the contour
%   step: step size for each iterative slide
%
% Output:
%   segs: [len x 2 x N] matrix of N segments of len size
%

if nargin < 4
    mth = 'old';
end


% if ~all(trc(1,:) == trc(end,:))
%     trc = [trc ; trc(1,:)];
%     len = len + 1;
% end

%% Continue generating segments to fully wrap around contour
switch mth
    case 'old'
        startIdx       = 1 : step : (length(trc) - 1);
        endIdx         = startIdx + len - 1;
        outIdx         = endIdx > size(trc,1);
        endIdx(outIdx) = endIdx(outIdx) - size(trc,1) + step;
        
        segs = zeros(len, 2, size(startIdx, 2));
        for sIdx = 1 : size(segs,3)
            if endIdx(sIdx) >= startIdx(sIdx)
                segs(:, :, sIdx) = trc(startIdx(sIdx) : endIdx(sIdx), :);
            else
                segA           = trc(startIdx(sIdx) : end         , :);
                segB           = trc(2              : endIdx(sIdx), :);
                segs(:,:,sIdx) = [segA ; segB];
            end
        end
        
    case 'new'
        trc(end,:) = [];
        lbl  = ones(size(trc,1), 1);                                % Label matrix 
        tmp  = [[0 * lbl , trc] ; [1 * lbl, trc] ; [0 * lbl, trc]]; % Stacking curves
        wid  = size(tmp,2);                                         % Dimensions of curve
        out  = im2colF(tmp, [len , wid], [step , 1]);
        kp   = out((len - 1) / 2 , :) == 1;                         % Get middle indices of segments
        out  = out((len + 1) : end, kp);
        segs = reshape(out, [len , wid-1 , size(trc,1)]);
        
    otherwise
        fprintf(2, 'Method must be [old|new]\n');
        segs = [];
end

end

% function segs = oldMethod()
% end


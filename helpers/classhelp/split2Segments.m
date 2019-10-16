function segs = split2Segments(trc, len, stp, mth)
%% split2Segments: split contour into pieces of len size around the segment
% This function takes a set of coordinates (typically defining a full contour)
% and splits it into many segments of len size. These segments iteratively slide
% around the contour, with the step size to skip between lengths defined by the
% step parameter.
%
% Usage:
%   segs = split2Segments(trc, len, stp, mth)
%
% Input:
%   trc: full contour as a set of x-/y-coordinates
%   len: length to split each segment around the contour
%   stp: step size for each iterative slide
%   mth: method for performing the split [1|2|3]
%
% Output:
%   segs: [len x 2 x N] matrix of N segments of len size
%

%% Default to method 1
if nargin < 4
    mth = 1;
end

%% Continue generating segments to fully wrap around contour
switch mth
    case 1
        % Open contour if closed
        if all(trc(1,:) == trc(end,:))
            trc(end,:) = [];
        end
        
        %% Fastest and least complex method        
        pad    = len - stp;
        wid    = size(trc,2);        
        padtrc = double([trc ; trc(1:pad,:)]);
        segF   = im2colF(padtrc, [len , wid], [stp, 1]);
        segs   = reshape(segF, [len , wid , size(segF,2)]);
        
        % Convert back to original class
        cls  = class(trc);
        segs = eval(sprintf('%s(%s)', cls, 'segs'));
        
    case 2
        %% Nathan's method that labels stacked curves
        trc(end,:) = [];
        lbl  = ones(size(trc,1), 1);                                % Label matrix
        stk  = [[0 * lbl , trc] ; [1 * lbl, trc] ; [0 * lbl, trc]]; % Stacking curves
        wid  = size(stk,2);                                         % Dimensions of curve
        out  = im2colF(stk, [len , wid], [stp , 1]);
        
        % Pull out segments
        kp   = out((len - 1) / 2 , :) == 1; % Keep 2nd layers containing segments
        out  = out((len + 1) : end, kp);
        segs = reshape(out, [len , wid-1 , size(trc,1)]);
        
    case 3
        %% Oldest and Slowest method
        startIdx       = 1 : stp : (length(trc) - 1);
        endIdx         = startIdx + len - 1;
        outIdx         = endIdx > size(trc,1);
        endIdx(outIdx) = endIdx(outIdx) - size(trc,1) + stp;
        
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
    otherwise
        %% Incorrect method chosen
        fprintf(2, 'Method must be [old|new]\n');
        segs = [];
end

end


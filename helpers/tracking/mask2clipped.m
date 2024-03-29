function [cntr , mline] = mask2clipped(msk, dsz, npts, init, creq, mth, smth, seg_lengths, fidx, itr)
%% mask2clipped: segment from mask and process to clipped contour
%
%
% Usage:
%   [cntr , mline] = mask2clipped(msk, varargin)
%
% Input:
%   msk: binary mask of lower region
%   dsk: disk size for smoothing binary mask [default 3]
%   npts: number of coordinates to set contour
%   mth: processing method to find corners of contour [default 1]
%   smth: smoothing parameter after segmentation [default 1]
%   slens: length of segments for all 4 regions [left|top|right|bottom]
%   fidx: figure handle index to display result [default 0]
%
% Output:
%   out: results
%       clow: re-formatted contour of lower mask
%       mlow: midline generated from contour

%% Parse inputs
if nargin < 2; dsz         = 3;                   end
if nargin < 3; npts        = 210;                 end
if nargin < 4; init        = 'alt';               end
if nargin < 5; creq        = 'Normalize';         end
if nargin < 6; mth         = 1;                   end
if nargin < 7; smth        = 1;                   end
if nargin < 8; seg_lengths = [53 , 52 , 53 , 51]; end
if nargin < 9; fidx        = 0;                   end
if nargin < 10; itr        = 1;                   end

MAXITRS = 3; % Attempts to get midline
BLK     = 15; % Image rows to remove for each iteration
try
    % Segment, smooth, process to regions, extract midline
    dsk        = fspecial('disk', dsz);
    msk        = imfilter(msk, dsk);
    [~ , cntr] = extractContour(msk, npts, init, creq);
    cntr       = [smooth(cntr(:,1), smth) , smooth(cntr(:,2), smth)];
    cntr       = raw2clipped(cntr, mth, 4, seg_lengths, fidx);
    %     [cntr , cinit , segs , t] = raw2clipped(cntr, mth, 4, seg_lengths, fidx);
    mline      = nateMidline(cntr);
catch
    fprintf(2, 'Error [attempt %02d of %02d]...', itr, MAXITRS);
    if itr == MAXITRS
        [cntr , mline] = deal([]);
    else
        % Remove lower rows of mask and re-attempt conversion
        blk = 1 : size(msk,1) - BLK;
        msk = msk(blk,:);
        [cntr , mline] = mask2clipped(msk, dsz, npts, init, creq, mth, smth, ...
            seg_lengths, fidx, itr + 1);
    end
end
end

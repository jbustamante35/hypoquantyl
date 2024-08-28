function [rcntr , rmline , minfo] = thumb2full_remote(himg, simg, cntr, mline, sbox, gbox, toFlip, slens, slen, mbuf)
%% thumb2full_remote: remap from thumbnail full resolution image without objects
% Extract Images | Rescale and Remap coordinates
%
% Usage:
%   [rcntr , rmline , minfo] = thumb2full_remote(himg, simg, cntr, mline, ...
%       sbox, gbox, toFlip, slens, slen, mbuf)
%
% Input:
%   himg: upper or lower hypocotyl image
%   cntr: contour associated with image
%   mline: midline associated with image
%   sbox:
%   gbox:
%   toFlip:
%   slens:
%   slen:
%   mbuf:
%
% Output:
%   rcntr: contour remapped to full resolution image
%   rmline: midline remapped to full resolution image
%   minfo: miscellaneous information about remapping
%

%% Remap seedling data onto full-res image
if nargin < 7;  toFlip = 0;                   end
if nargin < 8;  slens  = [53 , 52 , 53 , 51]; end
if nargin < 9;  slen   = slens(end);          end
if nargin < 10; mbuf   = 0;                   end

% Hypocotyl on non-resized seedling image
[rcntr , rmline , minfo] = deal([]);

% Rescale thumbnail coordinates back to original
scrp    = imcrop(simg, sbox);
scls    = size(scrp) ./ size(himg);
rcntrs  = fliplr(fliplr(cntr) .* scls);
rmlines = fliplr(fliplr(mline) .* scls);

% Flip if needed
if toFlip
    isz     = size(simg,1);
    rcntrs  = flipAndSlide(rcntrs, slens, isz);
    rmlines = flipLine(rmlines, slen);
end

% Map seedling coordinates back to full-res image
rcntr  = rcntrs + (gbox(1:2) + sbox(1:2) - [mbuf , mbuf]);
rmline = rmlines + (gbox(1:2) + sbox(1:2) - [mbuf , mbuf]);

%% Get some miscellaneous data for visualizing info
minfo = struct('img', himg, 'himg', simg, 'cntr', cntr, 'mline', mline);
end

function flp = flipLine(mline, slen)
%% flipLine: flip line along x-axis and slide to appropriate location
% Works on most any curve. Use flipAndSlide to flip contours.
%
% Usage:
%   flp = flipAndSlide(mline, slen)
%
% Input:
%   mline:
%   slen: length of bottom segment (for flipping midlines)
%
% Output:
%   flp:
%

if nargin < 2; slen = 51; end

%%
bmid      = mline(1,:);
dspl      = mline + (-bmid);
dspl(:,1) = -dspl(:,1);
sld       = [slen - bmid(1) , 0] * 2;
flp       = dspl + sld + bmid;
end

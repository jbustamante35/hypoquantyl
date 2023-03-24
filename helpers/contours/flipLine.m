function flp = flipLine(mline, slen, scl)
%% flipLine: flip line along x-axis and slide to appropriate location
% Works on most any curve. Use flipAndSlide to flip contours.
%
% Usage:
%   flp = flipAndSlide(mline, slen, scl)
%
% Input:
%   mline:
%   slen: length of bottom segment (for flipping midlines)
%   scl: 
%
% Output:
%   flp:
%

if nargin < 2; slen = 51; end
if nargin < 3; scl  = 1;  end

slen = slen * scl;

%%
bmid      = mline(1,:);
dspl      = mline + (-bmid);
dspl(:,1) = -dspl(:,1);
sld       = [slen - bmid(1) , 0] * 2;
flp       = dspl + sld + bmid;
end

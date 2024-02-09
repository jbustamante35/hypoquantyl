function flp = flipLine(mline, isz)
%% flipLine: flip line along x-axis and slide to appropriate location
% Works on most any curve. Use flipAndSlide to flip contours.
%
% Usage:
%   flp = flipLine(mline, isz)
%
% Input:
%   mline:
%   isz:
%
% Output:
%   flp:

%%
if nargin < 2; isz = 101; end

bmid = mline(1,:);
dspl = mline + (-bmid);
flpd = [-dspl(:,1) , dspl(:,2)];
fdsp = flpd + bmid;

mpt  = round(isz / 2);
mdst = bmid(1) - mpt;
sld  = [(mpt - mdst) - bmid(1) , 0];
flp  = fdsp + sld;
end

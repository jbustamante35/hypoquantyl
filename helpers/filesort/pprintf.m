function ostr = pprintf(pstr, ctyp)
%% pprintf: converts file paths to appropriate OS
%
%
% Usage:
%   pout = jpath(pstr, ctyp)
%
% Input:
%   pstr: file path string
%   ctyp: override OS type ['unix2win'|'win2unix']
%
% Output:
%   ostr: file path string converted to appropriate OS
%

if nargin < 2; ctyp = [];end

if isempty(ctyp); ctyp = isunix; end

if ctyp
    ostr = convertpath(pstr, 'win2unix');
else
    ostr = convertpath(pstr, 'unix2win');
end
end
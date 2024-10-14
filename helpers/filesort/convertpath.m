function pout = convertpath(pinn, ctyp, wdrive)
%% convert2windows: convert filepath to windows or unix
% Just a simple way to convert file paths for windows users
%
% Usage:
%   pout = convertpath(pinn, ctyp, wdrive)
%
% Input:
%   pinn: file path string
%   ctyp: direction to convert ('unix2win'|'win2unix')
%   wdrive: Windows drive to append (default [])
%
% Output:
%   pout: converted path

if nargin < 2; ctyp   = 'unix2win'; end
if nargin < 3; wdrive = [];         end

switch ctyp
    case 'unix2win'
        % Detects if drive selected, then convert Unix to Windows
        if ~isempty(wdrive); wdrive = sprintf('%s:\\', wdrive); end
        pout = sprintf('%s%s', wdrive, strrep(pinn, '/', '\'));
    case 'win2unix'
        % Removes drive, then convert Windows to Unix
        if strcmpi(pinn(2), ':'); pinn = pinn(4 : end); end
        pout = sprintf('%s', strrep(pinn, '\', '/'));
    otherwise

end
end
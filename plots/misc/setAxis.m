function setAxis(fidx, fsz, fwt, cbar)
%% setAxis: formatting for axis labels
%
% Usage:
%   setAxis(fidx, fsz, fwt)
%
% Input:
%   fidx: figure handle index [default 1]
%   fsz: font size to set axis labels [default 8]
%   fwt: font weight to set axis labels [default 'n']

if nargin < 1; fidx = 1;   end
if nargin < 2; fsz  = 10;  end
if nargin < 3; fwt  = 'n'; end
if nargin < 4; cbar = [];  end

figclr(fidx,1);

ax                  = gca;
ax.XAxis.FontWeight = fwt;
ax.YAxis.FontWeight = fwt;
ax.ZAxis.FontWeight = fwt;
ax.XAxis.FontSize   = fsz;
ax.YAxis.FontSize   = fsz;
ax.ZAxis.FontSize   = fsz;

if ~isempty(cbar)
    if ~contains(class(cbar), 'colorbar', 'IgnoreCase', 1)
        cbar = get(gca, 'colorbar');
    end
    cbar.FontSize   = fsz;
    cbar.FontWeight = fwt;
end
end

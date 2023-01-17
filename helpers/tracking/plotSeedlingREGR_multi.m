function FNMS = plotSeedlingREGR_multi(T, GIMGS, GMIDS, gstr, pver, fidx, tbug, sav, tdir)
%% plotSeedlingREGR_multi
%
% Usage:
%   FNMS = plotSeedlingREGR_multi(T, GIMGS, GMIDS, ...
%       gstr, pver, fidx, tbug, sav, tdir)
%
% Input:
%   T:
%   GIMGS:
%   GMIDS:
%   gstr:
%   pver:
%   fidx:
%   tbug:
%   sav:
%   tdir:
%
% Output:
%   FNMS:
%

if nargin < 4; gstr = 'xxx';              end
if nargin < 5; pver = 'rep';              end
if nargin < 6; fidx = [];                 end
if nargin < 7; tbug = 1;                  end
if nargin < 8; sav  = 0;                  end
if nargin < 9; tdir = 'tracking_results'; end

%
FNMS = cellfun(@(t,g,m) showTrackingResults_remote(t, g, m, ...
    'dbug', tbug, 'sav', sav), T, GIMGS, GMIDS, 'UniformOutput', 0);

%
if isempty(fidx); fidx = numel(FNMS{1}) + 1; end
enm = T{1}.Data.Experiment;
tnm = sprintf('%s_%s', enm(strfind(enm, '_') + 1 : end), gstr(1:end-1));
fnm = plotSeedlingREGR(T, tnm, fidx, pver);

%
for i = 1 : numel(FNMS); FNMS{i}{8} = fnm; end

%
if sav
    tdir = sprintf('%s/%s', tdir, enm);
    saveFiguresJB(fidx, {fnm}, tdir);
end
end
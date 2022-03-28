function ndout = substituteNd(ndin, path2subs)
%% replaceNd: replace Network object Nd with MyNN object for CONDOR use
if nargin < 2; path2subs = fileparts(which('N1')); end


flds = fieldnames(ndin);
for f = 1 : numel(flds)
    fld         = flds{f};
    script      = sprintf('%s/%s.m', path2subs, flds{f});
    ndout.(fld) = struct('script', script, ...
        'fnc', sprintf('@(varargin)%s(varargin{:})', fld));
end
end
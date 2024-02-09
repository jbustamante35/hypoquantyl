function mmkdir(sysPath)
%% mmkdir: use system's mkdir (for HTCondor)
%
% Usage:
%   mmkdir(sysPath)
%
% Input:
%   sysPath: path to create directory

cmd     = sprintf('mkdir -p "%s"', sysPath);
[r , o] = system(cmd);
end
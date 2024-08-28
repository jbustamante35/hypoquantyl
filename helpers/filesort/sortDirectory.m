function [d , f] = sortDirectory(pathTo)
%% sortDirectory: function that returns only directories
% This function takes in a path string, loads the contents, and returns structures of
% only the directories, files, or both. All others are removed from the array(s).
%
% Usage:
%   allDirs = sortDirectories(pathIn)
%
% Input:
%   pathTo: string representing path to cd into
%
% Output:
%   allDirs: [n x 1] table containing all directories in path
%
pathOrigin = pwd;
cd(pathTo);
a       = dir('*');
[d , f] = sortFiles(a);

    function [dirs , fils] = sortFiles(ain)
        ain(1:2) = [];
        dIdx = cat(1, ain.isdir) == 1;
        dirs = ain(dIdx);
        fils = ain(~dIdx);

        try
            if ~isempty(dirs)
                dirs = struct2table(dirs);
                if isunix
                    dirs.path = strcat(dirs.folder, '/', dirs.name);
                else
                    dirs.path = strcat(dirs.folder, '\', dirs.name);
                end
            end
            fils = struct2table(fils);
        catch e
            fprintf(2, 'Directory empty\n');
            fprintf(2, '%s \n', e.message);
            return;
        end
    end

cd(pathOrigin);
end
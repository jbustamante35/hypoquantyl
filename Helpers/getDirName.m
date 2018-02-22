function [name_out, name_in] = getDirName(name_in)
%% getDirName: function to parse folder name from current path
% This is simple really
% 
% Usage:
%   name_out = getDirName(name_in)
% 
% Input:
%   name_in:
% 
% Output:
%   name_out:
% 
% 

    if isunix
        p = regexp(name_in, '\/', 'split');
    else
        p = regexp(name_in, '\\', 'split');
    end

    name_out = p{end};

end
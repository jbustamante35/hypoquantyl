function [jmsg , strA , strB] = jprintf(msg, tt, v, len, estr, charA, charB)
%% jprintf: shortcut function to make nice output messages
% Description
%
% Example:
%   t = tic;
%   n = fprintf('Current Task');
%
%   [ functions ]
%
%   jprintf(' ', toc(t), 1, 80 - n);
%
%   Console:
%   >> Current Task ................................ [ 0.73 sec ]
%
% Usage:
%   [jmsg , strA , strB] = jprintf(msg, tt, v, estr, len, charA, charB)
%
% Input:
%   msg: message to print before filler message
%   tt: output of toc
%   v: store in string (0) or output to console (1) [default 1]
%   len: max length of each line of the message (default 80)
%   estr: string or character to use as message filler (default '.')
%   charA: string or character for heading separator (default '=')
%   charB: string or character for section separator (default '-')
%
% Output:
%   jmsg: function to use message in a string message
%   strA: heading separator
%   strB: section separator
%

%%
switch nargin
    case nargin < 2
        fprintf(2, 'Not enough input arguments [%d]\n', nargin);
        [jmsg , strA , strB] = deal([]);
        return;
    case 2
        v     = 1;
        len   = 80;
        estr  = '.';
        charA = '=';
        charB = '-';
    case 3
        len   = 80;
        estr  = '.';
        charA = '=';
        charB = '-';
    case 4
        estr  = '.';
        charA = '=';
        charB = '-';
    case 5
        charA = '=';
        charB = '-';
    case 6
        charB = '-';
end

%
strA = repmat(charA, [1 , len]);
strB = repmat(charB, [1 , len]);
ellp = @(x) repmat(estr, 1, len - (length(x) + 13));

% Output to console or store in string
if v
    jmsg = fprintf('%s%s [ %.02f sec ] \n', msg, ellp(msg), tt);
else
    jmsg = sprintf('%s%s [ %.02f sec ] \n', msg, ellp(msg), tt);
end
end

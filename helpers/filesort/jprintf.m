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
if nargin < 1; msg   = '';  end
if nargin < 2; tt    = 0;   end
if nargin < 3; v     = 1;   end
if nargin < 4; len   = 80;  end
if nargin < 5; estr  = '.'; end
if nargin < 6; charA = '='; end
if nargin < 7; charB = '-'; end

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

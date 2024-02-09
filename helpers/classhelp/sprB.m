function strB = sprB(charB, len)
%% sprB: a second custom separator
%
% Usage:
%   strB = sprB(charB, len)
%
% Input:
%   charB: character to replicate [default '-']
%   len: length to replicate character [default 80]
%
% Output:
%   strB: string of replicated character
if nargin < 1; charB = '-'; end
if nargin < 2; len   = 80;  end

strB = sprA(charB, len);
end
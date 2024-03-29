function strA = sprA(charA, len)
%% sprA: my custom separator
%
% Usage:
%   strA = sprA(charA, len)
%
% Input:
%   charA: character to replicate [default '=']
%   len: length to replicate character [default 80]
%
% Output:
%   strA: string of replicated character
if nargin < 1; charA = '='; end
if nargin < 2; len   = 80;  end

strA = repmat(charA, [1 , len]);
end
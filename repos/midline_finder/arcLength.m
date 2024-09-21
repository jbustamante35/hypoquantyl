function [S , LEN , arcLen , s] = arcLength(S, type, N)
%% arcLength: parameterize S via methType
%
% Usage:
%   [S , LEN , arcLen , s] = arcLength(S, type, N)
%
% Input:
%   S: curve to operate on
%   type: method type
%   N: method type parameter
%
% Output:
%   S:
%   LEN:
%   arcLen:
%   s:
%

%%
dS = diff(S, 1, 1);
l  = sum(dS .* dS, 2) .^ 0.5;
l  = cumsum([0 ; l], 1);

% switch on type of interpolation
switch type
    case 'mag'
        N = N * numel(l);
    case 'spec'
        N = N;
    case 'arcLen'
        N = round(l(end));
end

%
s      = linspace(0, l(end), N)';
S      = interp1(l, S, s);
LEN    = l(end);
arcLen = 0 : LEN;
end
